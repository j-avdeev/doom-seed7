(function () {
  "use strict";

  const WIDTH = 320;
  const HEIGHT = 200;
  const RECT_WIDTH = 48;
  const RECT_HEIGHT = 32;

  const canvas = document.getElementById("framebuffer");
  const status = document.getElementById("status");
  const wasmStatus = document.getElementById("wasmStatus");
  const pauseButton = document.getElementById("pauseButton");
  const resetButton = document.getElementById("resetButton");
  const framebufferModeButton = document.getElementById("framebufferModeButton");
  const firstPersonModeButton = document.getElementById("firstPersonModeButton");
  const mapModeButton = document.getElementById("mapModeButton");
  const modeStatus = document.getElementById("modeStatus");
  const wadFileInput = document.getElementById("wadFileInput");
  const wadStatus = document.getElementById("wadStatus");
  const wadSummary = document.getElementById("wadSummary");
  const wadLumps = document.getElementById("wadLumps");
  const mapSummary = document.getElementById("mapSummary");
  const context = canvas.getContext("2d", { alpha: false });
  const imageData = context.createImageData(WIDTH, HEIGHT);

  const WAD_HEADER_SIZE = 12;
  const WAD_DIRECTORY_ENTRY_SIZE = 16;
  const THING_SIZE = 10;
  const LINEDEF_SIZE = 14;
  const SIDEDEF_SIZE = 30;
  const VERTEX_SIZE = 4;
  const SECTOR_SIZE = 26;
  const DOOM_PALETTE_COLORS = 256;
  const DOOM_PALETTE_BYTES = DOOM_PALETTE_COLORS * 3;
  const TEXTURE_HEADER_SIZE = 22;
  const TEXTURE_PATCH_SIZE = 10;
  const PATCH_HEADER_SIZE = 8;
  const MAX_TEXTURE_PIXELS = 1024 * 1024;
  const MAP_LUMPS = ["THINGS", "LINEDEFS", "SIDEDEFS", "VERTEXES", "SECTORS"];
  const LINEDEF_BLOCKING = 1;
  const PLAYER_RADIUS = 12;
  const PLAYER_SPEED = 120;
  const PLAYER_TURN_SPEED = 150;
  const FIRST_PERSON_FOV_DEGREES = 66;
  const FIRST_PERSON_WALL_HEIGHT = 96;
  const FIRST_PERSON_NEAR_DISTANCE = 0.25;
  const FIRST_PERSON_PROJECTION_DISTANCE =
    (WIDTH / 2) / Math.tan((FIRST_PERSON_FOV_DEGREES * Math.PI / 180) / 2);

  let frame = 0;
  let paused = false;
  let lastStep = 0;
  let lastMapStep = 0;
  let wasmProvider = null;
  let renderMode = "framebuffer";
  let loadedMap = null;
  let playerState = null;
  const pressedKeys = new Set();

  function byteWrap(value) {
    return ((value % 256) + 256) % 256;
  }

  function rectLeft(frameNumber) {
    return (frameNumber * 5) % (WIDTH + RECT_WIDTH) - RECT_WIDTH;
  }

  function rectTop(frameNumber) {
    return (frameNumber * 3) % (HEIGHT + RECT_HEIGHT) - RECT_HEIGHT;
  }

  function insideMovingRect(x, y, frameNumber) {
    const left = rectLeft(frameNumber);
    const top = rectTop(frameNumber);
    return x >= left && x < left + RECT_WIDTH && y >= top && y < top + RECT_HEIGHT;
  }

  function writeFrame(frameNumber, data) {
    let offset = 0;
    for (let y = 0; y < HEIGHT; y += 1) {
      for (let x = 0; x < WIDTH; x += 1) {
        if (insideMovingRect(x, y, frameNumber)) {
          data[offset] = 255;
          data[offset + 1] = byteWrap(y * 3 + frameNumber);
          data[offset + 2] = 32;
        } else {
          data[offset] = byteWrap(x + frameNumber * 3);
          data[offset + 1] = byteWrap(y * 2 + frameNumber * 5);
          data[offset + 2] = byteWrap(x + y + frameNumber * 2);
        }
        data[offset + 3] = 255;
        offset += 4;
      }
    }
  }

  function putPixel(data, x, y, red, green, blue) {
    if (x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT) return;
    const offset = (Math.trunc(y) * WIDTH + Math.trunc(x)) * 4;
    data[offset] = red;
    data[offset + 1] = green;
    data[offset + 2] = blue;
    data[offset + 3] = 255;
  }

  function clearImageData(data, red, green, blue) {
    for (let offset = 0; offset < data.length; offset += 4) {
      data[offset] = red;
      data[offset + 1] = green;
      data[offset + 2] = blue;
      data[offset + 3] = 255;
    }
  }

  function drawLine(data, x0, y0, x1, y1, red, green, blue) {
    let currentX = Math.round(x0);
    let currentY = Math.round(y0);
    const targetX = Math.round(x1);
    const targetY = Math.round(y1);
    const dx = Math.abs(targetX - currentX);
    const sx = currentX < targetX ? 1 : -1;
    const dy = -Math.abs(targetY - currentY);
    const sy = currentY < targetY ? 1 : -1;
    let error = dx + dy;

    while (true) {
      putPixel(data, currentX, currentY, red, green, blue);
      if (currentX === targetX && currentY === targetY) break;
      const doubledError = error * 2;
      if (doubledError >= dy) {
        error += dy;
        currentX += sx;
      }
      if (doubledError <= dx) {
        error += dx;
        currentY += sy;
      }
    }
  }

  function drawDisk(data, centerX, centerY, radius, red, green, blue) {
    const roundedX = Math.round(centerX);
    const roundedY = Math.round(centerY);
    for (let y = -radius; y <= radius; y += 1) {
      for (let x = -radius; x <= radius; x += 1) {
        if (x * x + y * y <= radius * radius) {
          putPixel(data, roundedX + x, roundedY + y, red, green, blue);
        }
      }
    }
  }

  function normalizeAngle(angle) {
    return ((angle % 360) + 360) % 360;
  }

  function positiveModulo(value, modulus) {
    return ((value % modulus) + modulus) % modulus;
  }

  function isMapRenderMode(mode) {
    return mode === "map" || mode === "firstPerson";
  }

  function initPlayerState(mapData) {
    if (mapData === null || mapData.playerStart === null) {
      playerState = null;
      return;
    }

    playerState = {
      x: mapData.playerStart.x,
      y: mapData.playerStart.y,
      angle: normalizeAngle(mapData.playerStart.angle),
      speed: PLAYER_SPEED,
      turnSpeed: PLAYER_TURN_SPEED
    };
  }

  function isSolidLinedef(linedef) {
    return linedef.leftSidedef < 0 ||
      linedef.rightSidedef < 0 ||
      (linedef.flags & LINEDEF_BLOCKING) !== 0;
  }

  function cross(ax, ay, bx, by, cx, cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
  }

  function pointOnSegment(px, py, ax, ay, bx, by) {
    const epsilon = 0.000001;
    return Math.abs(cross(ax, ay, bx, by, px, py)) <= epsilon &&
      px >= Math.min(ax, bx) - epsilon &&
      px <= Math.max(ax, bx) + epsilon &&
      py >= Math.min(ay, by) - epsilon &&
      py <= Math.max(ay, by) + epsilon;
  }

  function segmentsIntersect(ax, ay, bx, by, cx, cy, dx, dy) {
    const abC = cross(ax, ay, bx, by, cx, cy);
    const abD = cross(ax, ay, bx, by, dx, dy);
    const cdA = cross(cx, cy, dx, dy, ax, ay);
    const cdB = cross(cx, cy, dx, dy, bx, by);

    if ((abC > 0 && abD < 0 || abC < 0 && abD > 0) &&
        (cdA > 0 && cdB < 0 || cdA < 0 && cdB > 0)) {
      return true;
    }

    return pointOnSegment(cx, cy, ax, ay, bx, by) ||
      pointOnSegment(dx, dy, ax, ay, bx, by) ||
      pointOnSegment(ax, ay, cx, cy, dx, dy) ||
      pointOnSegment(bx, by, cx, cy, dx, dy);
  }

  function pointSegmentDistanceSquared(px, py, ax, ay, bx, by) {
    const segmentX = bx - ax;
    const segmentY = by - ay;
    const lengthSquared = segmentX * segmentX + segmentY * segmentY;

    if (lengthSquared === 0) {
      const pointDx = px - ax;
      const pointDy = py - ay;
      return pointDx * pointDx + pointDy * pointDy;
    }

    const t = Math.max(0, Math.min(1,
      ((px - ax) * segmentX + (py - ay) * segmentY) / lengthSquared));
    const nearestX = ax + t * segmentX;
    const nearestY = ay + t * segmentY;
    const dx = px - nearestX;
    const dy = py - nearestY;
    return dx * dx + dy * dy;
  }

  function movementTouchesSolidLine(mapData, fromX, fromY, toX, toY) {
    const radiusSquared = PLAYER_RADIUS * PLAYER_RADIUS;

    for (let index = 0; index < mapData.linedefs.length; index += 1) {
      const linedef = mapData.linedefs[index];
      if (!isSolidLinedef(linedef)) continue;

      const start = mapData.vertexes[linedef.startVertex];
      const end = mapData.vertexes[linedef.endVertex];
      if (!start || !end) continue;

      if (segmentsIntersect(fromX, fromY, toX, toY, start.x, start.y, end.x, end.y)) {
        return true;
      }

      const oldDistance = pointSegmentDistanceSquared(fromX, fromY, start.x, start.y, end.x, end.y);
      const newDistance = pointSegmentDistanceSquared(toX, toY, start.x, start.y, end.x, end.y);
      if (newDistance < radiusSquared && newDistance <= oldDistance) {
        return true;
      }
    }

    return false;
  }

  function tryMovePlayer(mapData, dx, dy) {
    const nextX = playerState.x + dx;
    const nextY = playerState.y + dy;

    if (!movementTouchesSolidLine(mapData, playerState.x, playerState.y, nextX, nextY)) {
      playerState.x = nextX;
      playerState.y = nextY;
      return true;
    }

    return false;
  }

  function updatePlayerFromInput(mapData, deltaSeconds) {
    if (playerState === null) return;

    const seconds = Math.min(deltaSeconds, 0.1);
    let turn = 0;
    let forward = 0;
    let strafe = 0;

    if (pressedKeys.has("ArrowLeft") || pressedKeys.has("KeyQ")) turn += 1;
    if (pressedKeys.has("ArrowRight") || pressedKeys.has("KeyE")) turn -= 1;
    if (pressedKeys.has("KeyW")) forward += 1;
    if (pressedKeys.has("KeyS")) forward -= 1;
    if (pressedKeys.has("KeyD")) strafe += 1;
    if (pressedKeys.has("KeyA")) strafe -= 1;

    if (turn !== 0) {
      playerState.angle = normalizeAngle(playerState.angle + turn * playerState.turnSpeed * seconds);
    }

    if (forward !== 0 || strafe !== 0) {
      const radians = playerState.angle * Math.PI / 180;
      const length = Math.hypot(forward, strafe);
      const travel = playerState.speed * seconds;
      const moveForward = forward / length;
      const moveStrafe = strafe / length;
      const dx = (Math.cos(radians) * moveForward + Math.sin(radians) * moveStrafe) * travel;
      const dy = (Math.sin(radians) * moveForward - Math.cos(radians) * moveStrafe) * travel;

      tryMovePlayer(mapData, dx, 0);
      tryMovePlayer(mapData, 0, dy);
    }
  }

  function renderAndPresent(frameNumber) {
    if (wasmProvider !== null) {
      const checksum = wasmProvider.writeFrame(frameNumber, imageData.data);
      context.putImageData(imageData, 0, 0);
      status.textContent = "Frame " + frameNumber + " (WASM checksum " + checksum + ")";
    } else {
      writeFrame(frameNumber, imageData.data);
      context.putImageData(imageData, 0, 0);
      status.textContent = "Frame " + frameNumber + " (JS fallback)";
    }
  }

  function renderTopDownMap(mapData) {
    const data = imageData.data;
    const bounds = mapData.bounds;
    const mapWidth = Math.max(1, bounds.maxX - bounds.minX);
    const mapHeight = Math.max(1, bounds.maxY - bounds.minY);
    const padding = 16;
    const scale = Math.min((WIDTH - padding * 2) / mapWidth, (HEIGHT - padding * 2) / mapHeight);
    const centerX = (bounds.minX + bounds.maxX) / 2;
    const centerY = (bounds.minY + bounds.maxY) / 2;

    function toScreen(vertex) {
      return {
        x: WIDTH / 2 + (vertex.x - centerX) * scale,
        y: HEIGHT / 2 - (vertex.y - centerY) * scale
      };
    }

    clearImageData(data, 9, 12, 12);

    for (let index = 0; index < mapData.linedefs.length; index += 1) {
      const linedef = mapData.linedefs[index];
      const start = mapData.vertexes[linedef.startVertex];
      const end = mapData.vertexes[linedef.endVertex];
      if (start && end) {
        const startScreen = toScreen(start);
        const endScreen = toScreen(end);
        if (linedef.leftSidedef >= 0 && linedef.rightSidedef >= 0) {
          drawLine(data, startScreen.x, startScreen.y, endScreen.x, endScreen.y, 82, 141, 128);
        } else {
          drawLine(data, startScreen.x, startScreen.y, endScreen.x, endScreen.y, 220, 232, 225);
        }
      }
    }

    for (let index = 0; index < mapData.vertexes.length; index += 1) {
      const screen = toScreen(mapData.vertexes[index]);
      drawDisk(data, screen.x, screen.y, 2, 119, 208, 189);
    }

    if (playerState !== null) {
      const player = toScreen(playerState);
      const radians = playerState.angle * Math.PI / 180;
      const arrowLength = 18;
      const arrowX = player.x + Math.cos(radians) * arrowLength;
      const arrowY = player.y - Math.sin(radians) * arrowLength;
      drawDisk(data, player.x, player.y, 4, 255, 212, 96);
      drawLine(data, player.x, player.y, arrowX, arrowY, 255, 212, 96);
      drawLine(data, arrowX, arrowY,
        arrowX - Math.cos(radians + 0.55) * 6,
        arrowY + Math.sin(radians + 0.55) * 6, 255, 212, 96);
      drawLine(data, arrowX, arrowY,
        arrowX - Math.cos(radians - 0.55) * 6,
        arrowY + Math.sin(radians - 0.55) * 6, 255, 212, 96);
    }

    context.putImageData(imageData, 0, 0);
    if (playerState !== null) {
      status.textContent = "Map " + mapData.name + " player x=" +
        playerState.x.toFixed(1) + " y=" + playerState.y.toFixed(1) +
        " angle=" + Math.round(playerState.angle) + " (" +
        mapData.vertexes.length + " vertexes, " + mapData.linedefs.length +
        " linedefs, scale " + scale.toFixed(2) + ")";
    } else {
      status.textContent = "Map " + mapData.name + " top-down: no player start (" +
      mapData.vertexes.length + " vertexes, " + mapData.linedefs.length +
      " linedefs, scale " + scale.toFixed(2) + ")";
    }
  }

  function raySegmentIntersection(originX, originY, rayX, rayY, ax, ay, bx, by) {
    const segmentX = bx - ax;
    const segmentY = by - ay;
    const denominator = rayX * segmentY - rayY * segmentX;

    if (Math.abs(denominator) < 0.000001) return null;

    const toSegmentX = ax - originX;
    const toSegmentY = ay - originY;
    const distance = (toSegmentX * segmentY - toSegmentY * segmentX) / denominator;
    const segmentT = (toSegmentX * rayY - toSegmentY * rayX) / denominator;

    if (distance <= FIRST_PERSON_NEAR_DISTANCE || segmentT < 0 || segmentT > 1) {
      return null;
    }

    return {
      distance: distance,
      segmentT: segmentT
    };
  }

  function findNearestWallHit(mapData, rayAngleRadians) {
    const rayX = Math.cos(rayAngleRadians);
    const rayY = Math.sin(rayAngleRadians);
    let nearestHit = null;

    for (let index = 0; index < mapData.linedefs.length; index += 1) {
      const linedef = mapData.linedefs[index];
      if (!isSolidLinedef(linedef)) continue;

      const start = mapData.vertexes[linedef.startVertex];
      const end = mapData.vertexes[linedef.endVertex];
      if (!start || !end) continue;

      const hit = raySegmentIntersection(
        playerState.x, playerState.y,
        rayX, rayY,
        start.x, start.y,
        end.x, end.y
      );

      if (hit !== null && (nearestHit === null || hit.distance < nearestHit.distance)) {
        nearestHit = {
          distance: hit.distance,
          segmentT: hit.segmentT,
          linedef: linedef,
          start: start,
          end: end
        };
      }
    }

    return nearestHit;
  }

  function drawVerticalColumn(data, x, y0, y1, red, green, blue) {
    const startY = Math.max(0, Math.floor(y0));
    const endY = Math.min(HEIGHT - 1, Math.ceil(y1));

    for (let y = startY; y <= endY; y += 1) {
      const offset = (y * WIDTH + x) * 4;
      data[offset] = red;
      data[offset + 1] = green;
      data[offset + 2] = blue;
      data[offset + 3] = 255;
    }
  }

  function wallFallbackColor(perpendicularDistance, segmentT) {
    const shade = Math.max(0.28, Math.min(1, 220 / (perpendicularDistance + 96)));
    const edgeShade = segmentT < 0.04 || segmentT > 0.96 ? 0.72 : 1;
    return {
      shade: shade * edgeShade,
      red: Math.round(188 * shade * edgeShade),
      green: Math.round(201 * shade * edgeShade),
      blue: Math.round(190 * shade * edgeShade)
    };
  }

  function sidedefAt(mapData, index) {
    if (index < 0 || index >= mapData.sidedefs.length) return null;
    return mapData.sidedefs[index];
  }

  function chooseWallSidedef(mapData, hit) {
    const sideValue = cross(
      hit.start.x, hit.start.y,
      hit.end.x, hit.end.y,
      playerState.x, playerState.y
    );
    const primaryIndex = sideValue < 0 ? hit.linedef.rightSidedef : hit.linedef.leftSidedef;
    const secondaryIndex = sideValue < 0 ? hit.linedef.leftSidedef : hit.linedef.rightSidedef;
    const primarySidedef = sidedefAt(mapData, primaryIndex);
    const secondarySidedef = sidedefAt(mapData, secondaryIndex);

    if (isUsableTextureName(firstWallTextureName(primarySidedef))) {
      return {
        sidedef: primarySidedef,
        index: primaryIndex,
        reverseTextureX: primaryIndex === hit.linedef.leftSidedef
      };
    }
    if (isUsableTextureName(firstWallTextureName(secondarySidedef))) {
      return {
        sidedef: secondarySidedef,
        index: secondaryIndex,
        reverseTextureX: secondaryIndex === hit.linedef.leftSidedef
      };
    }
    return null;
  }

  function resolveWallTexture(mapData, hit) {
    const side = chooseWallSidedef(mapData, hit);
    const textureSet = mapData.textureSet;
    let textureName = "";

    if (side === null || !textureSet || !textureSet.available) return null;

    textureName = firstWallTextureName(side.sidedef);
    if (!textureSet.textures.has(textureName)) return null;

    return {
      side: side,
      textureName: textureName,
      texture: textureSet.textures.get(textureName)
    };
  }

  function drawTexturedWallColumn(data, x, y0, y1, texture, textureX, yOffset, shade, fallbackColor) {
    const startY = Math.max(0, Math.floor(y0));
    const endY = Math.min(HEIGHT - 1, Math.ceil(y1));
    const wallSpan = Math.max(1, y1 - y0);

    for (let y = startY; y <= endY; y += 1) {
      const textureY = positiveModulo(
        Math.floor(((y + 0.5 - y0) / wallSpan) * texture.height + yOffset),
        texture.height
      );
      const sourceOffset = (textureY * texture.width + textureX) * 4;
      const destinationOffset = (y * WIDTH + x) * 4;

      if (texture.pixels[sourceOffset + 3] === 0) {
        data[destinationOffset] = fallbackColor.red;
        data[destinationOffset + 1] = fallbackColor.green;
        data[destinationOffset + 2] = fallbackColor.blue;
      } else {
        data[destinationOffset] = Math.round(texture.pixels[sourceOffset] * shade);
        data[destinationOffset + 1] = Math.round(texture.pixels[sourceOffset + 1] * shade);
        data[destinationOffset + 2] = Math.round(texture.pixels[sourceOffset + 2] * shade);
      }
      data[destinationOffset + 3] = 255;
    }
  }

  function renderFirstPersonMap(mapData) {
    const data = imageData.data;
    const playerAngleRadians = playerState === null ? 0 : playerState.angle * Math.PI / 180;
    const fovRadians = FIRST_PERSON_FOV_DEGREES * Math.PI / 180;
    let hitColumns = 0;
    let texturedColumns = 0;

    for (let y = 0; y < HEIGHT; y += 1) {
      const ceiling = y < HEIGHT / 2;
      for (let x = 0; x < WIDTH; x += 1) {
        const offset = (y * WIDTH + x) * 4;
        if (ceiling) {
          data[offset] = 42;
          data[offset + 1] = 50;
          data[offset + 2] = 58;
        } else {
          data[offset] = 35;
          data[offset + 1] = 38;
          data[offset + 2] = 33;
        }
        data[offset + 3] = 255;
      }
    }

    if (playerState !== null) {
      for (let column = 0; column < WIDTH; column += 1) {
        const cameraX = (column + 0.5) / WIDTH - 0.5;
        const angleOffset = cameraX * fovRadians;
        const rayAngle = playerAngleRadians + angleOffset;
        const hit = findNearestWallHit(mapData, rayAngle);

        if (hit === null) continue;

        const perpendicularDistance = Math.max(
          FIRST_PERSON_NEAR_DISTANCE,
          hit.distance * Math.cos(angleOffset)
        );
        const wallHeight = Math.min(
          HEIGHT * 2,
          FIRST_PERSON_WALL_HEIGHT * FIRST_PERSON_PROJECTION_DISTANCE / perpendicularDistance
        );
        const wallTop = HEIGHT / 2 - wallHeight / 2;
        const wallBottom = HEIGHT / 2 + wallHeight / 2;
        const fallbackColor = wallFallbackColor(perpendicularDistance, hit.segmentT);
        const resolvedTexture = resolveWallTexture(mapData, hit);

        if (resolvedTexture === null) {
          drawVerticalColumn(
            data,
            column,
            wallTop,
            wallBottom,
            fallbackColor.red,
            fallbackColor.green,
            fallbackColor.blue
          );
        } else {
          const lineLength = Math.hypot(hit.end.x - hit.start.x, hit.end.y - hit.start.y);
          const wallDistance = resolvedTexture.side.reverseTextureX ?
            (1 - hit.segmentT) * lineLength : hit.segmentT * lineLength;
          const textureX = positiveModulo(
            Math.floor(wallDistance + resolvedTexture.side.sidedef.xOffset),
            resolvedTexture.texture.width
          );
          drawTexturedWallColumn(
            data,
            column,
            wallTop,
            wallBottom,
            resolvedTexture.texture,
            textureX,
            resolvedTexture.side.sidedef.yOffset,
            fallbackColor.shade,
            fallbackColor
          );
          texturedColumns += 1;
        }
        hitColumns += 1;
      }
    }

    context.putImageData(imageData, 0, 0);
    if (playerState !== null) {
      status.textContent = "First-person " + mapData.name + " player x=" +
        playerState.x.toFixed(1) + " y=" + playerState.y.toFixed(1) +
        " angle=" + Math.round(playerState.angle) + " (" +
        hitColumns + " wall columns, " + texturedColumns + " textured)";
    } else {
      status.textContent = "First-person " + mapData.name + ": no player start";
    }
  }

  function renderCurrentMapMode(mapData) {
    if (renderMode === "firstPerson") {
      renderFirstPersonMap(mapData);
    } else {
      renderTopDownMap(mapData);
    }
  }

  function setRenderMode(nextMode) {
    if (isMapRenderMode(nextMode) && loadedMap === null) return;
    renderMode = nextMode;
    lastMapStep = 0;
    framebufferModeButton.classList.toggle("is-active", renderMode === "framebuffer");
    firstPersonModeButton.classList.toggle("is-active", renderMode === "firstPerson");
    mapModeButton.classList.toggle("is-active", renderMode === "map");
    framebufferModeButton.setAttribute("aria-pressed", renderMode === "framebuffer" ? "true" : "false");
    firstPersonModeButton.setAttribute("aria-pressed", renderMode === "firstPerson" ? "true" : "false");
    mapModeButton.setAttribute("aria-pressed", renderMode === "map" ? "true" : "false");
    if (renderMode === "firstPerson") {
      modeStatus.textContent = "Mode: first-person prototype";
    } else if (renderMode === "map") {
      modeStatus.textContent = "Mode: top-down map view";
    } else {
      modeStatus.textContent = "Mode: framebuffer demo";
    }
    if (isMapRenderMode(renderMode)) {
      renderCurrentMapMode(loadedMap);
    } else {
      renderAndPresent(frame);
    }
  }

  function draw(timestamp) {
    if (renderMode === "framebuffer" && !paused && timestamp - lastStep >= 33) {
      renderAndPresent(frame);
      frame += 1;
      lastStep = timestamp;
    } else if (isMapRenderMode(renderMode) && loadedMap !== null) {
      if (lastMapStep === 0) lastMapStep = timestamp;
      updatePlayerFromInput(loadedMap, (timestamp - lastMapStep) / 1000);
      renderCurrentMapMode(loadedMap);
      lastMapStep = timestamp;
    }
    window.requestAnimationFrame(draw);
  }

  function createWasmProvider(module) {
    const doomInit = module.cwrap("doom_init", null, ["number", "number"]);
    const doomTick = module.cwrap("doom_tick", "number", ["number"]);
    const framebufferPtr = module.cwrap("doom_framebuffer_ptr", "number", []);
    const framebufferWidth = module.cwrap("doom_framebuffer_width", "number", []);
    const framebufferHeight = module.cwrap("doom_framebuffer_height", "number", []);
    const framebufferSize = module.cwrap("doom_framebuffer_size", "number", []);

    const width = framebufferWidth();
    const height = framebufferHeight();
    const size = framebufferSize();

    if (width !== WIDTH || height !== HEIGHT || size !== imageData.data.length) {
      throw new Error("unexpected framebuffer ABI " + width + "x" + height + " size=" + size);
    }

    doomInit(WIDTH, HEIGHT);

    return {
      writeFrame: function (frameNumber, destination) {
        const checksum = doomTick(frameNumber);
        const ptr = framebufferPtr();
        const heap = module.HEAPU8;

        if (!heap || ptr <= 0 || ptr + size > heap.length) {
          throw new Error("invalid WASM framebuffer pointer");
        }
        destination.set(heap.subarray(ptr, ptr + size));
        return checksum;
      }
    };
  }

  function clearNode(node) {
    while (node.firstChild !== null) {
      node.removeChild(node.firstChild);
    }
  }

  function appendDescription(parent, label, value) {
    const term = document.createElement("dt");
    const detail = document.createElement("dd");
    term.textContent = label;
    detail.textContent = value;
    parent.appendChild(term);
    parent.appendChild(detail);
  }

  function readAsciiName(bytes, offset, length) {
    let name = "";
    for (let index = 0; index < length && offset + index < bytes.length; index += 1) {
      const value = bytes[offset + index];
      if (value === 0) break;
      name += String.fromCharCode(value);
    }
    return name.toUpperCase();
  }

  function readAsciiNameFromView(view, offset, length) {
    let name = "";
    for (let index = 0; index < length && offset + index < view.byteLength; index += 1) {
      const value = view.getUint8(offset + index);
      if (value === 0) break;
      name += String.fromCharCode(value);
    }
    return name.toUpperCase();
  }

  function isDigitChar(character) {
    return character >= "0" && character <= "9";
  }

  function isSupportedMapMarker(name) {
    return name === "E1M1" || name === "MAP01";
  }

  function isMapMarkerBoundary(name) {
    return isSupportedMapMarker(name) ||
      (name.length === 4 && name[0] === "E" && isDigitChar(name[1]) &&
        name[2] === "M" && isDigitChar(name[3])) ||
      (name.length === 5 && name.slice(0, 3) === "MAP" && isDigitChar(name[3]) &&
        isDigitChar(name[4]));
  }

  function findFirstSupportedMap(wad) {
    for (let index = 0; index < wad.lumps.length; index += 1) {
      if (isSupportedMapMarker(wad.lumps[index].name)) return index;
    }
    return -1;
  }

  function findMapLumpAfterMarker(wad, markerIndex, lumpName) {
    for (let index = markerIndex + 1; index < wad.lumps.length; index += 1) {
      if (isMapMarkerBoundary(wad.lumps[index].name)) return null;
      if (wad.lumps[index].name === lumpName) return wad.lumps[index];
    }
    return null;
  }

  function findLumpByName(wad, lumpName) {
    const normalizedName = lumpName.toUpperCase();
    for (let index = 0; index < wad.lumps.length; index += 1) {
      if (wad.lumps[index].name === normalizedName) return wad.lumps[index];
    }
    return null;
  }

  function validateLumpRange(buffer, lump) {
    const end = lump.dataOffset + lump.dataSize;
    if (lump.dataOffset < 0 || lump.dataSize < 0 || end > buffer.byteLength) {
      throw new Error("lump data exceeds file size: " + lump.name);
    }
  }

  function checkedLumpData(buffer, lump) {
    validateLumpRange(buffer, lump);
    return new DataView(buffer, lump.dataOffset, lump.dataSize);
  }

  function checkedLumpBytes(buffer, lump) {
    validateLumpRange(buffer, lump);
    return new Uint8Array(buffer, lump.dataOffset, lump.dataSize);
  }

  function checkedRecordCount(lumpName, dataView, recordSize) {
    if (dataView.byteLength % recordSize !== 0) {
      throw new Error("lump " + lumpName + " has invalid size " + dataView.byteLength);
    }
    return dataView.byteLength / recordSize;
  }

  function parsePlayerStart(thingsView) {
    const thingCount = checkedRecordCount("THINGS", thingsView, THING_SIZE);
    for (let index = 0; index < thingCount; index += 1) {
      const offset = index * THING_SIZE;
      if (thingsView.getInt16(offset + 6, true) === 1) {
        return {
          x: thingsView.getInt16(offset, true),
          y: thingsView.getInt16(offset + 2, true),
          angle: thingsView.getInt16(offset + 4, true)
        };
      }
    }
    return null;
  }

  function parseVertexes(vertexesView) {
    const vertexCount = checkedRecordCount("VERTEXES", vertexesView, VERTEX_SIZE);
    const vertexes = [];
    for (let index = 0; index < vertexCount; index += 1) {
      const offset = index * VERTEX_SIZE;
      vertexes.push({
        x: vertexesView.getInt16(offset, true),
        y: vertexesView.getInt16(offset + 2, true)
      });
    }
    return vertexes;
  }

  function parseLinedefs(linedefsView, vertexCount) {
    const linedefCount = checkedRecordCount("LINEDEFS", linedefsView, LINEDEF_SIZE);
    const linedefs = [];
    for (let index = 0; index < linedefCount; index += 1) {
      const offset = index * LINEDEF_SIZE;
      const startVertex = linedefsView.getUint16(offset, true);
      const endVertex = linedefsView.getUint16(offset + 2, true);
      if (startVertex >= vertexCount || endVertex >= vertexCount) {
        throw new Error("linedef " + index + " references a missing vertex");
      }
      linedefs.push({
        startVertex: startVertex,
        endVertex: endVertex,
        flags: linedefsView.getInt16(offset + 4, true),
        specialType: linedefsView.getInt16(offset + 6, true),
        sectorTag: linedefsView.getInt16(offset + 8, true),
        rightSidedef: linedefsView.getInt16(offset + 10, true),
        leftSidedef: linedefsView.getInt16(offset + 12, true)
      });
    }
    return linedefs;
  }

  function parseSidedefs(sidedefsView) {
    const sidedefCount = checkedRecordCount("SIDEDEFS", sidedefsView, SIDEDEF_SIZE);
    const sidedefs = [];
    for (let index = 0; index < sidedefCount; index += 1) {
      const offset = index * SIDEDEF_SIZE;
      sidedefs.push({
        xOffset: sidedefsView.getInt16(offset, true),
        yOffset: sidedefsView.getInt16(offset + 2, true),
        upperTexture: readAsciiNameFromView(sidedefsView, offset + 4, 8),
        lowerTexture: readAsciiNameFromView(sidedefsView, offset + 12, 8),
        middleTexture: readAsciiNameFromView(sidedefsView, offset + 20, 8),
        sector: sidedefsView.getInt16(offset + 28, true)
      });
    }
    return sidedefs;
  }

  function isUsableTextureName(name) {
    return name !== "" && name !== "-";
  }

  function firstWallTextureName(sidedef) {
    if (!sidedef) return "";
    if (isUsableTextureName(sidedef.middleTexture)) return sidedef.middleTexture;
    if (isUsableTextureName(sidedef.upperTexture)) return sidedef.upperTexture;
    if (isUsableTextureName(sidedef.lowerTexture)) return sidedef.lowerTexture;
    return "";
  }

  function collectReferencedWallTextureNames(mapData) {
    const names = new Set();

    function addSidedefTexture(sidedef) {
      if (!sidedef) return;
      if (isUsableTextureName(sidedef.middleTexture)) names.add(sidedef.middleTexture);
      if (isUsableTextureName(sidedef.upperTexture)) names.add(sidedef.upperTexture);
      if (isUsableTextureName(sidedef.lowerTexture)) names.add(sidedef.lowerTexture);
    }

    for (let index = 0; index < mapData.linedefs.length; index += 1) {
      const linedef = mapData.linedefs[index];
      if (!isSolidLinedef(linedef)) continue;
      addSidedefTexture(mapData.sidedefs[linedef.rightSidedef]);
      addSidedefTexture(mapData.sidedefs[linedef.leftSidedef]);
    }

    return names;
  }

  function unavailableTextureSet(reason, requestedCount) {
    return {
      available: false,
      reason: reason,
      requestedCount: requestedCount || 0,
      definitionCount: 0,
      textureCount: 0,
      textures: new Map(),
      missingTextures: [],
      missingPatches: []
    };
  }

  function parsePlaypal(playpalBytes) {
    if (playpalBytes.byteLength < DOOM_PALETTE_BYTES) {
      throw new Error("PLAYPAL is shorter than one 256-color palette");
    }

    const palette = new Uint8ClampedArray(DOOM_PALETTE_COLORS * 4);
    for (let index = 0; index < DOOM_PALETTE_COLORS; index += 1) {
      const sourceOffset = index * 3;
      const destinationOffset = index * 4;
      palette[destinationOffset] = playpalBytes[sourceOffset];
      palette[destinationOffset + 1] = playpalBytes[sourceOffset + 1];
      palette[destinationOffset + 2] = playpalBytes[sourceOffset + 2];
      palette[destinationOffset + 3] = 255;
    }
    return palette;
  }

  function parsePnames(pnamesView) {
    if (pnamesView.byteLength < 4) {
      throw new Error("PNAMES is shorter than its count field");
    }

    const patchCount = pnamesView.getInt32(0, true);
    const expectedSize = 4 + patchCount * 8;
    const patchNames = [];

    if (patchCount < 0 || expectedSize > pnamesView.byteLength) {
      throw new Error("PNAMES has an invalid patch count");
    }

    for (let index = 0; index < patchCount; index += 1) {
      patchNames.push(readAsciiNameFromView(pnamesView, 4 + index * 8, 8));
    }
    return patchNames;
  }

  function parseTextureDefinitions(textureView, patchNames, requestedNames) {
    if (textureView.byteLength < 4) {
      throw new Error("TEXTURE1 is shorter than its count field");
    }

    const textureCount = textureView.getInt32(0, true);
    const offsetTableEnd = 4 + textureCount * 4;
    const definitions = new Map();

    if (textureCount < 0 || offsetTableEnd > textureView.byteLength) {
      throw new Error("TEXTURE1 has an invalid texture count");
    }

    for (let index = 0; index < textureCount; index += 1) {
      const textureOffset = textureView.getInt32(4 + index * 4, true);
      if (textureOffset < offsetTableEnd || textureOffset + TEXTURE_HEADER_SIZE > textureView.byteLength) {
        continue;
      }

      const name = readAsciiNameFromView(textureView, textureOffset, 8);
      if (!isUsableTextureName(name) || definitions.has(name) ||
          (requestedNames.size > 0 && !requestedNames.has(name))) {
        continue;
      }

      const width = textureView.getInt16(textureOffset + 12, true);
      const height = textureView.getInt16(textureOffset + 14, true);
      const patchCount = textureView.getInt16(textureOffset + 20, true);
      const patchTableOffset = textureOffset + TEXTURE_HEADER_SIZE;
      const patchTableEnd = patchTableOffset + patchCount * TEXTURE_PATCH_SIZE;
      const patches = [];

      if (width <= 0 || height <= 0 || width * height > MAX_TEXTURE_PIXELS ||
          patchCount < 0 || patchTableEnd > textureView.byteLength) {
        continue;
      }

      for (let patchIndex = 0; patchIndex < patchCount; patchIndex += 1) {
        const offset = patchTableOffset + patchIndex * TEXTURE_PATCH_SIZE;
        const pnamesIndex = textureView.getInt16(offset + 4, true);
        patches.push({
          originX: textureView.getInt16(offset, true),
          originY: textureView.getInt16(offset + 2, true),
          patchName: pnamesIndex >= 0 && pnamesIndex < patchNames.length ?
            patchNames[pnamesIndex] : ""
        });
      }

      definitions.set(name, {
        name: name,
        width: width,
        height: height,
        patches: patches
      });
    }

    return definitions;
  }

  function parsePatchPicture(buffer, lump, palette) {
    const view = checkedLumpData(buffer, lump);
    const bytes = checkedLumpBytes(buffer, lump);

    if (view.byteLength < PATCH_HEADER_SIZE) {
      throw new Error("patch " + lump.name + " is shorter than its header");
    }

    const width = view.getInt16(0, true);
    const height = view.getInt16(2, true);
    const columnDirectoryEnd = PATCH_HEADER_SIZE + width * 4;

    if (width <= 0 || height <= 0 || width * height > MAX_TEXTURE_PIXELS ||
        columnDirectoryEnd > view.byteLength) {
      throw new Error("patch " + lump.name + " has invalid dimensions");
    }

    const pixels = new Uint8ClampedArray(width * height * 4);
    for (let column = 0; column < width; column += 1) {
      let cursor = view.getUint32(PATCH_HEADER_SIZE + column * 4, true);
      if (cursor < columnDirectoryEnd || cursor >= bytes.length) {
        throw new Error("patch " + lump.name + " has an invalid column offset");
      }

      while (cursor < bytes.length) {
        const topDelta = bytes[cursor];
        cursor += 1;
        if (topDelta === 255) break;
        if (cursor + 2 > bytes.length) {
          throw new Error("patch " + lump.name + " has a truncated post header");
        }

        const postLength = bytes[cursor];
        cursor += 2;
        if (cursor + postLength + 1 > bytes.length) {
          throw new Error("patch " + lump.name + " has truncated post pixels");
        }

        for (let row = 0; row < postLength; row += 1) {
          const y = topDelta + row;
          if (y >= 0 && y < height) {
            const paletteIndex = bytes[cursor + row] * 4;
            const destinationOffset = (y * width + column) * 4;
            pixels[destinationOffset] = palette[paletteIndex];
            pixels[destinationOffset + 1] = palette[paletteIndex + 1];
            pixels[destinationOffset + 2] = palette[paletteIndex + 2];
            pixels[destinationOffset + 3] = 255;
          }
        }
        cursor += postLength + 1;
      }
    }

    return {
      name: lump.name,
      width: width,
      height: height,
      pixels: pixels
    };
  }

  function composeTexture(buffer, wad, definition, palette, patchCache, missingPatches) {
    const pixels = new Uint8ClampedArray(definition.width * definition.height * 4);
    let drawnPixels = 0;

    for (let patchIndex = 0; patchIndex < definition.patches.length; patchIndex += 1) {
      const placement = definition.patches[patchIndex];
      let patch = null;

      if (isUsableTextureName(placement.patchName)) {
        if (patchCache.has(placement.patchName)) {
          patch = patchCache.get(placement.patchName);
        } else {
          const lump = findLumpByName(wad, placement.patchName);
          if (lump === null) {
            missingPatches.add(placement.patchName);
            patchCache.set(placement.patchName, null);
          } else {
            try {
              patch = parsePatchPicture(buffer, lump, palette);
              patchCache.set(placement.patchName, patch);
            } catch (error) {
              missingPatches.add(placement.patchName);
              patchCache.set(placement.patchName, null);
            }
          }
        }
      }

      if (patch === null) continue;

      for (let sourceY = 0; sourceY < patch.height; sourceY += 1) {
        const destinationY = placement.originY + sourceY;
        if (destinationY < 0 || destinationY >= definition.height) continue;
        for (let sourceX = 0; sourceX < patch.width; sourceX += 1) {
          const destinationX = placement.originX + sourceX;
          if (destinationX < 0 || destinationX >= definition.width) continue;

          const sourceOffset = (sourceY * patch.width + sourceX) * 4;
          if (patch.pixels[sourceOffset + 3] === 0) continue;

          const destinationOffset = (destinationY * definition.width + destinationX) * 4;
          pixels[destinationOffset] = patch.pixels[sourceOffset];
          pixels[destinationOffset + 1] = patch.pixels[sourceOffset + 1];
          pixels[destinationOffset + 2] = patch.pixels[sourceOffset + 2];
          pixels[destinationOffset + 3] = 255;
          drawnPixels += 1;
        }
      }
    }

    if (drawnPixels === 0) return null;

    return {
      name: definition.name,
      width: definition.width,
      height: definition.height,
      pixels: pixels
    };
  }

  function loadWallTextureSet(buffer, wad, requestedNames) {
    const requestedCount = requestedNames.size;
    const playpalLump = findLumpByName(wad, "PLAYPAL");
    const pnamesLump = findLumpByName(wad, "PNAMES");
    const texture1Lump = findLumpByName(wad, "TEXTURE1");

    if (requestedCount === 0) {
      return unavailableTextureSet("map has no referenced wall texture names", requestedCount);
    }
    if (playpalLump === null || pnamesLump === null || texture1Lump === null) {
      return unavailableTextureSet("missing PLAYPAL, PNAMES, or TEXTURE1", requestedCount);
    }

    try {
      const palette = parsePlaypal(checkedLumpBytes(buffer, playpalLump));
      const patchNames = parsePnames(checkedLumpData(buffer, pnamesLump));
      const definitions = parseTextureDefinitions(
        checkedLumpData(buffer, texture1Lump),
        patchNames,
        requestedNames
      );
      const textures = new Map();
      const patchCache = new Map();
      const missingTextures = [];
      const missingPatches = new Set();

      requestedNames.forEach(function (textureName) {
        const definition = definitions.get(textureName);
        if (!definition) {
          missingTextures.push(textureName);
          return;
        }

        const texture = composeTexture(buffer, wad, definition, palette, patchCache, missingPatches);
        if (texture === null) {
          missingTextures.push(textureName);
        } else {
          textures.set(textureName, texture);
        }
      });

      return {
        available: textures.size > 0,
        reason: textures.size > 0 ? "" : "no requested wall textures resolved",
        requestedCount: requestedCount,
        definitionCount: definitions.size,
        textureCount: textures.size,
        textures: textures,
        missingTextures: missingTextures,
        missingPatches: Array.from(missingPatches)
      };
    } catch (error) {
      return unavailableTextureSet("texture parse failed: " + error.message, requestedCount);
    }
  }

  function computeMapBounds(vertexes, playerStart) {
    let minX = Infinity;
    let minY = Infinity;
    let maxX = -Infinity;
    let maxY = -Infinity;

    function includePoint(point) {
      minX = Math.min(minX, point.x);
      minY = Math.min(minY, point.y);
      maxX = Math.max(maxX, point.x);
      maxY = Math.max(maxY, point.y);
    }

    if (vertexes.length === 0) {
      throw new Error("map has no vertexes to render");
    }
    for (let index = 0; index < vertexes.length; index += 1) {
      includePoint(vertexes[index]);
    }
    if (playerStart !== null) {
      includePoint(playerStart);
    }

    return {
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY
    };
  }

  function parseMapData(buffer, wad) {
    const markerIndex = findFirstSupportedMap(wad);
    const counts = {};
    const views = {};
    let playerStart = null;
    let vertexes = [];
    let linedefs = [];
    let sidedefs = [];
    let mapData = null;

    if (markerIndex < 0) return null;

    for (let index = 0; index < MAP_LUMPS.length; index += 1) {
      const lumpName = MAP_LUMPS[index];
      const lump = findMapLumpAfterMarker(wad, markerIndex, lumpName);
      if (lump === null) {
        throw new Error("missing map lump " + lumpName + " after " + wad.lumps[markerIndex].name);
      }
      views[lumpName] = checkedLumpData(buffer, lump);
    }

    counts.things = checkedRecordCount("THINGS", views.THINGS, THING_SIZE);
    counts.linedefs = checkedRecordCount("LINEDEFS", views.LINEDEFS, LINEDEF_SIZE);
    counts.sidedefs = checkedRecordCount("SIDEDEFS", views.SIDEDEFS, SIDEDEF_SIZE);
    counts.vertexes = checkedRecordCount("VERTEXES", views.VERTEXES, VERTEX_SIZE);
    counts.sectors = checkedRecordCount("SECTORS", views.SECTORS, SECTOR_SIZE);

    playerStart = parsePlayerStart(views.THINGS);
    vertexes = parseVertexes(views.VERTEXES);
    linedefs = parseLinedefs(views.LINEDEFS, vertexes.length);
    sidedefs = parseSidedefs(views.SIDEDEFS);

    mapData = {
      name: wad.lumps[markerIndex].name,
      counts: counts,
      playerStart: playerStart,
      vertexes: vertexes,
      linedefs: linedefs,
      sidedefs: sidedefs,
      bounds: computeMapBounds(vertexes, playerStart),
      textureSet: unavailableTextureSet("not loaded", 0)
    };
    mapData.textureSet = loadWallTextureSet(
      buffer,
      wad,
      collectReferencedWallTextureNames(mapData)
    );
    return mapData;
  }

  function parseWadDirectory(buffer) {
    const bytes = new Uint8Array(buffer);
    const view = new DataView(buffer);
    let wadType = "";
    let lumpCount = 0;
    let directoryOffset = 0;
    let directorySize = 0;
    let directoryEnd = 0;
    const lumps = [];

    if (buffer.byteLength < WAD_HEADER_SIZE) {
      throw new Error("WAD header is shorter than " + WAD_HEADER_SIZE + " bytes");
    }

    wadType = readAsciiName(bytes, 0, 4);
    lumpCount = view.getInt32(4, true);
    directoryOffset = view.getInt32(8, true);
    directorySize = lumpCount * WAD_DIRECTORY_ENTRY_SIZE;
    directoryEnd = directoryOffset + directorySize;

    if (wadType !== "IWAD" && wadType !== "PWAD") {
      throw new Error("invalid WAD magic: " + wadType);
    }
    if (lumpCount < 0) {
      throw new Error("invalid negative lump count: " + lumpCount);
    }
    if (directoryOffset < WAD_HEADER_SIZE) {
      throw new Error("invalid directory offset: " + directoryOffset);
    }
    if (directoryEnd > buffer.byteLength) {
      throw new Error("WAD directory exceeds file size");
    }

    for (let index = 0; index < lumpCount; index += 1) {
      const offset = directoryOffset + index * WAD_DIRECTORY_ENTRY_SIZE;
      const dataOffset = view.getInt32(offset, true);
      const dataSize = view.getInt32(offset + 4, true);
      const dataEnd = dataOffset + dataSize;

      if (dataOffset < 0 || dataSize < 0) {
        throw new Error("invalid negative lump field at index " + (index + 1));
      }
      if (dataSize > 0 && dataEnd > buffer.byteLength) {
        throw new Error("lump data exceeds file size at index " + (index + 1));
      }

      lumps.push({
        index: index + 1,
        dataOffset: dataOffset,
        dataSize: dataSize,
        name: readAsciiName(bytes, offset + 8, 8)
      });
    }

    return {
      wadType: wadType,
      lumpCount: lumpCount,
      directoryOffset: directoryOffset,
      lumps: lumps
    };
  }

  function displayWadInfo(file, buffer, wad) {
    const previewCount = Math.min(wad.lumps.length, 24);

    clearNode(wadSummary);
    clearNode(wadLumps);
    clearNode(mapSummary);

    appendDescription(wadSummary, "File", file.name);
    appendDescription(wadSummary, "WAD type", wad.wadType);
    appendDescription(wadSummary, "Lumps", String(wad.lumpCount));
    appendDescription(wadSummary, "Directory offset", String(wad.directoryOffset));
    appendDescription(wadSummary, "Size", buffer.byteLength + " bytes");
    loadedMap = null;
    playerState = null;
    mapModeButton.disabled = true;
    firstPersonModeButton.disabled = true;

    if (previewCount > 0) {
      const title = document.createElement("h3");
      const list = document.createElement("ol");
      title.textContent = "Lumps";
      wadLumps.appendChild(title);
      for (let index = 0; index < previewCount; index += 1) {
        const lump = wad.lumps[index];
        const item = document.createElement("li");
        item.textContent = lump.index + " " + lump.name +
          " offset=" + lump.dataOffset + " size=" + lump.dataSize;
        list.appendChild(item);
      }
      wadLumps.appendChild(list);
    }

    try {
      const mapData = parseMapData(buffer, wad);
      if (mapData === null) {
        appendDescription(mapSummary, "Map", "No E1M1 or MAP01 marker found");
        if (isMapRenderMode(renderMode)) setRenderMode("framebuffer");
      } else {
        loadedMap = mapData;
        initPlayerState(loadedMap);
        mapModeButton.disabled = false;
        firstPersonModeButton.disabled = false;
        appendDescription(mapSummary, "Map", mapData.name);
        appendDescription(mapSummary, "Vertexes", String(mapData.counts.vertexes));
        appendDescription(mapSummary, "Linedefs", String(mapData.counts.linedefs));
        appendDescription(mapSummary, "Sidedefs", String(mapData.counts.sidedefs));
        appendDescription(mapSummary, "Sectors", String(mapData.counts.sectors));
        appendDescription(mapSummary, "Things", String(mapData.counts.things));
        appendDescription(mapSummary, "Bounds",
          mapData.bounds.minX + "," + mapData.bounds.minY + " to " +
          mapData.bounds.maxX + "," + mapData.bounds.maxY);
        if (mapData.playerStart === null) {
          appendDescription(mapSummary, "Player start", "Missing");
        } else {
          appendDescription(mapSummary, "Player start",
            mapData.playerStart.x + ", " + mapData.playerStart.y +
            " angle=" + mapData.playerStart.angle);
        }
        if (mapData.textureSet.available) {
          appendDescription(mapSummary, "Wall textures",
            mapData.textureSet.textureCount + " of " +
            mapData.textureSet.requestedCount + " resolved");
          if (mapData.textureSet.missingTextures.length > 0 ||
              mapData.textureSet.missingPatches.length > 0) {
            appendDescription(mapSummary, "Texture gaps",
              mapData.textureSet.missingTextures.concat(mapData.textureSet.missingPatches).
                slice(0, 6).join(", "));
          }
        } else {
          appendDescription(mapSummary, "Wall textures",
            "Fallback: " + mapData.textureSet.reason);
        }
        setRenderMode("map");
      }
    } catch (error) {
      appendDescription(mapSummary, "Map", "Could not load statistics: " + error.message);
      if (isMapRenderMode(renderMode)) setRenderMode("framebuffer");
    }
  }

  function displayWadError(message) {
    clearNode(wadSummary);
    clearNode(wadLumps);
    clearNode(mapSummary);
    loadedMap = null;
    playerState = null;
    mapModeButton.disabled = true;
    firstPersonModeButton.disabled = true;
    if (isMapRenderMode(renderMode)) setRenderMode("framebuffer");
    wadStatus.textContent = "WAD parse failed: " + message;
  }

  function loadWadFile(file) {
    if (!file) {
      wadStatus.textContent = "No WAD selected.";
      clearNode(wadSummary);
      clearNode(wadLumps);
      clearNode(mapSummary);
      loadedMap = null;
      playerState = null;
      mapModeButton.disabled = true;
      firstPersonModeButton.disabled = true;
      if (isMapRenderMode(renderMode)) setRenderMode("framebuffer");
      return;
    }

    wadStatus.textContent = "Loading " + file.name + "...";
    file.arrayBuffer()
      .then(function (buffer) {
        const wad = parseWadDirectory(buffer);
        displayWadInfo(file, buffer, wad);
        wadStatus.textContent = "Parsed " + file.name + ".";
      })
      .catch(function (error) {
        displayWadError(error.message);
      });
  }

  function loadGeneratedWasmProvider() {
    const providerUrl = new URL("wasm/framebuffer_demo.js", window.location.href);
    const wasmUrl = new URL("wasm/framebuffer_demo.wasm", window.location.href);

    fetch(providerUrl.href, { cache: "no-store" })
      .then(function (response) {
        if (!response.ok) {
          wasmStatus.textContent = "Generated WASM provider not built; JS fallback active.";
          return null;
        }
        return response.text();
      })
      .then(function (scriptText) {
        if (scriptText === null) return;

        const script = document.createElement("script");
        const blob = new Blob([scriptText], { type: "text/javascript" });
        const objectUrl = URL.createObjectURL(blob);
        let resolved = false;

        window.Module = {
          noInitialRun: true,
          preRun: [function () {}],
          locateFile: function (path) {
            return path.endsWith(".wasm") ? wasmUrl.href : path;
          },
          onRuntimeInitialized: function () {
            try {
              wasmProvider = createWasmProvider(window.Module);
              resolved = true;
              wasmStatus.textContent = "Seed7-generated WASM framebuffer active.";
              renderAndPresent(frame);
            } catch (error) {
              wasmProvider = null;
              wasmStatus.textContent = "Generated WASM provider rejected; JS fallback active: " + error.message;
            }
          },
          print: function (line) {
            if (line.indexOf("framebuffer_demo width=320 height=200") !== -1) {
              resolved = true;
              wasmStatus.textContent = "Generated WASM smoke: " + line;
            }
          },
          printErr: function (line) {
            if (!resolved && line.indexOf("warning:") === -1) {
              wasmStatus.textContent = "Generated WASM provider warning: " + line;
            }
          }
        };

        script.onload = function () {
          window.setTimeout(function () {
            URL.revokeObjectURL(objectUrl);
            if (!resolved) {
              wasmStatus.textContent = "Generated WASM provider loaded without framebuffer ABI.";
            }
          }, 500);
        };
        script.onerror = function () {
          URL.revokeObjectURL(objectUrl);
          wasmStatus.textContent = "Generated WASM provider failed to load; JS fallback active.";
        };
        script.src = objectUrl;
        document.body.appendChild(script);
      })
      .catch(function () {
        wasmStatus.textContent = "Generated WASM provider unavailable; JS fallback active.";
      });
  }

  pauseButton.addEventListener("click", function () {
    paused = !paused;
    pauseButton.textContent = paused ? "Resume" : "Pause";
  });

  resetButton.addEventListener("click", function () {
    frame = 0;
    if (isMapRenderMode(renderMode)) {
      initPlayerState(loadedMap);
      renderCurrentMapMode(loadedMap);
    } else {
      renderAndPresent(frame);
    }
  });

  framebufferModeButton.addEventListener("click", function () {
    setRenderMode("framebuffer");
  });

  firstPersonModeButton.addEventListener("click", function () {
    setRenderMode("firstPerson");
  });

  mapModeButton.addEventListener("click", function () {
    setRenderMode("map");
  });

  wadFileInput.addEventListener("change", function () {
    loadWadFile(wadFileInput.files[0]);
  });

  window.addEventListener("keydown", function (event) {
    const controlledKey = event.code === "KeyW" ||
      event.code === "KeyA" ||
      event.code === "KeyS" ||
      event.code === "KeyD" ||
      event.code === "KeyQ" ||
      event.code === "KeyE" ||
      event.code === "ArrowLeft" ||
      event.code === "ArrowRight";

    if (!controlledKey) return;
    pressedKeys.add(event.code);
    if (isMapRenderMode(renderMode)) {
      event.preventDefault();
    }
  });

  window.addEventListener("keyup", function (event) {
    pressedKeys.delete(event.code);
  });

  renderAndPresent(frame);
  loadGeneratedWasmProvider();
  window.requestAnimationFrame(draw);
}());
