(function () {
  "use strict";

  const CANVAS_WIDTH = 320;
  const CANVAS_HEIGHT = 200;
  const HUD_HEIGHT = 40;
  const VIEW_HEIGHT = CANVAS_HEIGHT - HUD_HEIGHT;
  const WIDTH = CANVAS_WIDTH;
  const HEIGHT = CANVAS_HEIGHT;
  const RECT_WIDTH = 48;
  const RECT_HEIGHT = 32;
  const DEFAULT_DEMO_WAD_URL = "assets/demo_map.pwad";

  const canvas = document.getElementById("framebuffer");
  const status = document.getElementById("status");
  const wasmStatus = document.getElementById("wasmStatus");
  const pauseButton = document.getElementById("pauseButton");
  const resetButton = document.getElementById("resetButton");
  const framebufferModeButton = document.getElementById("framebufferModeButton");
  const firstPersonModeButton = document.getElementById("firstPersonModeButton");
  const mapModeButton = document.getElementById("mapModeButton");
  const gameStage = document.querySelector(".game-stage");
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
  const SYNTHETIC_DOOR_SPECIAL = 900;
  const USE_DISTANCE = 96;
  const DOOR_OPEN_SECONDS = 0.45;
  const PLAYER_RADIUS = 12;
  const PLAYER_SPEED = 120;
  const PLAYER_TURN_SPEED = 150;
  const PLAYER_START_HEALTH = 100;
  const PLAYER_START_AMMO = 24;
  const PISTOL_DAMAGE = 1;
  const SHOOTABLE_THING_HEALTH = 3;
  const ENEMY_STATE_IDLE = "idle";
  const ENEMY_STATE_CHASE = "chase";
  const ENEMY_STATE_ATTACK = "attack";
  const ENEMY_STATE_DEAD = "dead";
  const GAME_STATE_READY = "ready";
  const GAME_STATE_PLAYING = "playing";
  const GAME_STATE_PAUSED = "paused";
  const GAME_STATE_DEAD = "dead";
  const ENEMY_DETECTION_RANGE = 192;
  const ENEMY_SHOT_ALERT_RANGE = 512;
  const ENEMY_MOVE_SPEED = 46;
  const ENEMY_RADIUS = 12;
  const ENEMY_MELEE_RANGE = 30;
  const ENEMY_MELEE_DAMAGE = 5;
  const ENEMY_ATTACK_COOLDOWN_SECONDS = 1.0;
  const ENEMY_ATTACK_STATE_SECONDS = 0.22;
  const HITSCAN_MAX_DISTANCE = 1024;
  const HITSCAN_THING_RADIUS = 18;
  const FIRST_PERSON_FOV_DEGREES = 66;
  const FIRST_PERSON_WALL_HEIGHT = 96;
  const FIRST_PERSON_THING_HEIGHT = 56;
  const FIRST_PERSON_THING_WIDTH_RATIO = 0.62;
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
  let interactionMessage = "";
  let combatMessage = "shot=ready";
  let aiMessage = "none";
  let gameStateMessage = "No map loaded.";
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

  function drawRing(data, centerX, centerY, radius, red, green, blue) {
    const innerRadiusSquared = Math.max(0, (radius - 2) * (radius - 2));
    const outerRadiusSquared = radius * radius;
    const roundedX = Math.round(centerX);
    const roundedY = Math.round(centerY);

    for (let y = -radius; y <= radius; y += 1) {
      for (let x = -radius; x <= radius; x += 1) {
        const distanceSquared = x * x + y * y;
        if (distanceSquared <= outerRadiusSquared && distanceSquared >= innerRadiusSquared) {
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

  function isPlayerStartThing(thing) {
    return thing.type === 1 || thing.type === 2 || thing.type === 3 ||
      thing.type === 4 || thing.type === 11;
  }

  function isRenderableThing(thing) {
    return !isPlayerStartThing(thing);
  }

  function isShootableThing(thing) {
    return isRenderableThing(thing) && thing.shootable === true;
  }

  function isAliveThing(thing) {
    return isShootableThing(thing) && thing.dead !== true && thing.health > 0;
  }

  function thingBaseColor(thing) {
    if (thing.aiState === ENEMY_STATE_ATTACK) {
      return { red: 224, green: 70, blue: 64 };
    }
    if (thing.aiState === ENEMY_STATE_CHASE) {
      return { red: 245, green: 184, blue: 74 };
    }
    if (thing.aiState === ENEMY_STATE_IDLE) {
      return { red: 96, green: 172, blue: 226 };
    }
    if (thing.type >= 3000) {
      return { red: 216, green: 82, blue: 72 };
    }
    if (thing.type >= 2000) {
      return { red: 92, green: 170, blue: 232 };
    }
    if (thing.type >= 1000) {
      return { red: 240, green: 192, blue: 84 };
    }
    return { red: 184, green: 132, blue: 220 };
  }

  function renderableThings(mapData) {
    if (!mapData || !mapData.things) return [];
    return mapData.things.filter(isRenderableThing);
  }

  function aliveRenderableThings(mapData) {
    if (!mapData || !mapData.things) return [];
    return mapData.things.filter(isAliveThing);
  }

  function shootableThingCount(mapData) {
    if (!mapData || !mapData.things) return 0;
    return mapData.things.filter(isShootableThing).length;
  }

  function aliveThingCount(mapData) {
    return aliveRenderableThings(mapData).length;
  }

  function deadThingCount(mapData) {
    if (!mapData || !mapData.things) return 0;
    return mapData.things.filter(function (thing) {
      return isShootableThing(thing) && (thing.dead === true || thing.health <= 0);
    }).length;
  }

  function isPlayerDead() {
    return playerState !== null && (playerState.dead === true || playerState.health <= 0);
  }

  function currentGameState() {
    if (isPlayerDead()) return GAME_STATE_DEAD;
    if (paused) return GAME_STATE_PAUSED;
    if (playerState !== null) return GAME_STATE_PLAYING;
    if (loadedMap !== null) return GAME_STATE_READY;
    return GAME_STATE_READY;
  }

  function setPaused(nextPaused) {
    paused = nextPaused;
    if (paused) pressedKeys.clear();
    pauseButton.textContent = paused ? "Resume" : "Pause";
    updateHudPanel(loadedMap);
  }

  function killPlayer(message) {
    if (playerState === null || playerState.dead === true) return;
    playerState.health = 0;
    playerState.dead = true;
    pressedKeys.clear();
    combatMessage = message || "player died";
    gameStateMessage = "GAME OVER - click Reset to restart.";
  }

  function setThingDead(thing) {
    thing.health = 0;
    thing.dead = true;
    thing.aiState = ENEMY_STATE_DEAD;
    thing.aiCooldown = 0;
    thing.aiAttackTimer = 0;
  }

  function resetThingCombatState(mapData) {
    if (!mapData || !mapData.things) return;
    mapData.things.forEach(function (thing) {
      if (isPlayerStartThing(thing)) {
        thing.shootable = false;
        thing.maxHealth = 0;
        thing.health = 0;
        thing.dead = false;
        thing.aiState = null;
        thing.aiCooldown = 0;
        thing.aiAttackTimer = 0;
      } else {
        thing.shootable = true;
        thing.maxHealth = SHOOTABLE_THING_HEALTH;
        thing.health = SHOOTABLE_THING_HEALTH;
        thing.dead = false;
        thing.aiState = ENEMY_STATE_IDLE;
        thing.aiCooldown = 0;
        thing.aiAttackTimer = 0;
      }
    });
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
      health: PLAYER_START_HEALTH,
      ammo: PLAYER_START_AMMO,
      currentWeapon: "pistol",
      dead: false,
      speed: PLAYER_SPEED,
      turnSpeed: PLAYER_TURN_SPEED
    };
    gameStateMessage = "Playing.";
  }

  function resetDoorStates(mapData) {
    if (!mapData || !mapData.doors) return;
    mapData.doors.forEach(function (door) {
      door.state = "closed";
      door.progress = 0;
    });
  }

  function resetPlayableState(mapData) {
    frame = 0;
    pressedKeys.clear();
    resetDoorStates(mapData);
    resetThingCombatState(mapData);
    initPlayerState(mapData);
    interactionMessage = "";
    combatMessage = "shot=ready";
    aiMessage = "none";
    gameStateMessage = playerState === null ? "No player start in loaded map." : "Playing.";
    setPaused(false);
    updateHudPanel(mapData);
  }

  function isDoorLinedef(linedef) {
    return linedef.specialType === SYNTHETIC_DOOR_SPECIAL;
  }

  function doorStateAt(mapData, linedefIndex) {
    if (!mapData || !mapData.doors) return null;
    return mapData.doors.get(linedefIndex) || null;
  }

  function isDoorOpen(mapData, linedefIndex) {
    const door = doorStateAt(mapData, linedefIndex);
    return door !== null && door.state === "open";
  }

  function isSolidLinedef(linedef, mapData, linedefIndex) {
    if (isDoorLinedef(linedef) && isDoorOpen(mapData, linedefIndex)) return false;
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

  function movementTouchesSolidLine(mapData, fromX, fromY, toX, toY, radius) {
    const collisionRadius = typeof radius === "number" ? radius : PLAYER_RADIUS;
    const radiusSquared = collisionRadius * collisionRadius;

    for (let index = 0; index < mapData.linedefs.length; index += 1) {
      const linedef = mapData.linedefs[index];
      if (!isSolidLinedef(linedef, mapData, index)) continue;

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

  function hasApproxLineOfSight(mapData, fromX, fromY, toX, toY) {
    if (!mapData) return false;

    for (let index = 0; index < mapData.linedefs.length; index += 1) {
      const linedef = mapData.linedefs[index];
      if (!isSolidLinedef(linedef, mapData, index)) continue;

      const start = mapData.vertexes[linedef.startVertex];
      const end = mapData.vertexes[linedef.endVertex];
      if (!start || !end) continue;

      if (segmentsIntersect(fromX, fromY, toX, toY, start.x, start.y, end.x, end.y)) {
        return false;
      }
    }

    return true;
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

  function tryMoveThing(mapData, thing, dx, dy) {
    const nextX = thing.x + dx;
    const nextY = thing.y + dy;

    if (!movementTouchesSolidLine(mapData, thing.x, thing.y, nextX, nextY, ENEMY_RADIUS)) {
      thing.x = nextX;
      thing.y = nextY;
      return true;
    }

    return false;
  }

  function moveEnemyTowardPlayer(mapData, thing, seconds) {
    const dx = playerState.x - thing.x;
    const dy = playerState.y - thing.y;
    const distance = Math.hypot(dx, dy);
    const stopDistance = ENEMY_MELEE_RANGE * 0.75;
    let travel = 0;
    let stepX = 0;
    let stepY = 0;

    if (distance <= stopDistance) return;

    travel = Math.min(ENEMY_MOVE_SPEED * seconds, Math.max(0, distance - stopDistance));
    if (travel <= 0) return;

    stepX = dx / distance * travel;
    stepY = dy / distance * travel;
    thing.angle = normalizeAngle(Math.atan2(dy, dx) * 180 / Math.PI);

    if (!tryMoveThing(mapData, thing, stepX, stepY)) {
      tryMoveThing(mapData, thing, stepX, 0);
      tryMoveThing(mapData, thing, 0, stepY);
    }
  }

  function enemyCanSeePlayer(mapData, thing, maxDistance) {
    const dx = playerState.x - thing.x;
    const dy = playerState.y - thing.y;

    if (dx * dx + dy * dy > maxDistance * maxDistance) return false;
    return hasApproxLineOfSight(mapData, thing.x, thing.y, playerState.x, playerState.y);
  }

  function alertEnemiesFromShot(mapData) {
    let alerted = 0;

    if (!mapData || playerState === null) return alerted;
    aliveRenderableThings(mapData).forEach(function (thing) {
      const dx = thing.x - playerState.x;
      const dy = thing.y - playerState.y;
      if (dx * dx + dy * dy > ENEMY_SHOT_ALERT_RANGE * ENEMY_SHOT_ALERT_RANGE) return;
      if (!hasApproxLineOfSight(mapData, playerState.x, playerState.y, thing.x, thing.y)) return;

      if (thing.aiState === ENEMY_STATE_IDLE) alerted += 1;
      thing.aiState = ENEMY_STATE_CHASE;
    });

    if (alerted > 0) {
      aiMessage = "shot alerted " + alerted;
    } else if (shootableThingCount(mapData) > 0) {
      aiMessage = "shot no alert";
    }
    return alerted;
  }

  function updateEnemyAi(mapData, deltaSeconds) {
    const seconds = Math.min(deltaSeconds, 0.1);
    let detected = 0;
    let attacks = 0;

    if (!mapData || playerState === null || isPlayerDead() || seconds <= 0) return;

    renderableThings(mapData).forEach(function (thing) {
      const dx = playerState.x - thing.x;
      const dy = playerState.y - thing.y;
      const distance = Math.hypot(dx, dy);
      let closeAndVisible = false;

      if (!isShootableThing(thing)) return;
      if (thing.dead === true || thing.health <= 0) {
        setThingDead(thing);
        return;
      }

      thing.aiCooldown = Math.max(0, (thing.aiCooldown || 0) - seconds);
      thing.aiAttackTimer = Math.max(0, (thing.aiAttackTimer || 0) - seconds);

      if (thing.aiState === ENEMY_STATE_IDLE &&
          enemyCanSeePlayer(mapData, thing, ENEMY_DETECTION_RANGE)) {
        thing.aiState = ENEMY_STATE_CHASE;
        detected += 1;
      }

      if (thing.aiState === ENEMY_STATE_IDLE) return;

      closeAndVisible = distance <= ENEMY_MELEE_RANGE &&
        hasApproxLineOfSight(mapData, thing.x, thing.y, playerState.x, playerState.y);

      if (closeAndVisible) {
        thing.aiState = ENEMY_STATE_ATTACK;
        thing.aiAttackTimer = ENEMY_ATTACK_STATE_SECONDS;
        if (thing.aiCooldown <= 0 && playerState.health > 0) {
          playerState.health = Math.max(0, playerState.health - ENEMY_MELEE_DAMAGE);
          thing.aiCooldown = ENEMY_ATTACK_COOLDOWN_SECONDS;
          attacks += 1;
          if (playerState.health <= 0) {
            killPlayer("player killed by enemy melee");
          }
        }
      } else {
        if (thing.aiAttackTimer <= 0) {
          thing.aiState = ENEMY_STATE_CHASE;
        }
        moveEnemyTowardPlayer(mapData, thing, seconds);
      }
    });

    if (attacks > 0) {
      aiMessage = "melee " + attacks + " hp=" + playerState.health;
    } else if (detected > 0) {
      aiMessage = "detected " + detected;
    }
  }

  function updatePlayerFromInput(mapData, deltaSeconds) {
    if (playerState === null) return;
    if (isPlayerDead() || paused) return;

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

  function createDoorStates(mapData) {
    const doors = new Map();

    for (let index = 0; index < mapData.linedefs.length; index += 1) {
      if (isDoorLinedef(mapData.linedefs[index])) {
        doors.set(index, {
          linedefIndex: index,
          state: "closed",
          progress: 0
        });
      }
    }

    return doors;
  }

  function updateDoorStates(mapData, deltaSeconds) {
    if (!mapData || !mapData.doors) return;
    mapData.doors.forEach(function (door) {
      if (door.state !== "opening") return;
      door.progress = Math.min(1, door.progress + deltaSeconds / DOOR_OPEN_SECONDS);
      if (door.progress >= 1) {
        door.state = "open";
        interactionMessage = "Door open.";
      }
    });
  }

  function findUsableLinedefInFront(mapData) {
    if (playerState === null || !mapData || !mapData.doors || mapData.doors.size === 0) return null;

    const radians = playerState.angle * Math.PI / 180;
    const rayX = Math.cos(radians);
    const rayY = Math.sin(radians);
    let nearest = null;

    mapData.doors.forEach(function (door, linedefIndex) {
      const linedef = mapData.linedefs[linedefIndex];
      const start = mapData.vertexes[linedef.startVertex];
      const end = mapData.vertexes[linedef.endVertex];
      let hit = null;

      if (!start || !end) return;
      hit = raySegmentIntersection(
        playerState.x, playerState.y,
        rayX, rayY,
        start.x, start.y,
        end.x, end.y
      );
      if (hit === null || hit.distance > USE_DISTANCE) return;
      if (nearest === null || hit.distance < nearest.distance) {
        nearest = {
          distance: hit.distance,
          linedef: linedef,
          linedefIndex: linedefIndex,
          door: door
        };
      }
    });

    return nearest;
  }

  function useLinedefInFront(mapData) {
    const target = findUsableLinedefInFront(mapData);

    if (isPlayerDead() || paused) return;
    if (target === null) {
      interactionMessage = "No usable line in reach.";
      return;
    }
    if (target.door.state === "closed") {
      target.door.state = "opening";
      target.door.progress = 0;
      interactionMessage = "Door opening.";
    } else if (target.door.state === "opening") {
      interactionMessage = "Door is opening.";
    } else {
      interactionMessage = "Door already open.";
    }
    renderCurrentMapMode(mapData);
  }

  function findHitscanThing(mapData) {
    const radians = playerState.angle * Math.PI / 180;
    const rayX = Math.cos(radians);
    const rayY = Math.sin(radians);
    const wallHit = findNearestWallHit(mapData, radians);
    const wallDistance = wallHit === null ? HITSCAN_MAX_DISTANCE :
      Math.min(HITSCAN_MAX_DISTANCE, wallHit.distance);
    let nearest = null;

    aliveRenderableThings(mapData).forEach(function (thing) {
      const dx = thing.x - playerState.x;
      const dy = thing.y - playerState.y;
      const forward = dx * rayX + dy * rayY;
      const lateral = dx * rayY - dy * rayX;
      let surfaceDistance = 0;

      if (forward <= FIRST_PERSON_NEAR_DISTANCE || forward > HITSCAN_MAX_DISTANCE) return;
      if (Math.abs(lateral) > HITSCAN_THING_RADIUS) return;

      surfaceDistance = forward -
        Math.sqrt(Math.max(0, HITSCAN_THING_RADIUS * HITSCAN_THING_RADIUS - lateral * lateral));
      if (surfaceDistance > wallDistance) return;

      if (nearest === null || surfaceDistance < nearest.distance) {
        nearest = {
          thing: thing,
          distance: surfaceDistance,
          centerDistance: forward
        };
      }
    });

    return nearest;
  }

  function fireCurrentWeapon(mapData) {
    let target = null;

    if (playerState === null || mapData === null) return;
    if (isPlayerDead()) {
      combatMessage = "shot=blocked player dead";
      renderCurrentMapMode(mapData);
      return;
    }
    if (paused) {
      combatMessage = "shot=blocked paused";
      renderCurrentMapMode(mapData);
      return;
    }
    if (playerState.currentWeapon !== "pistol") {
      combatMessage = "shot=no weapon";
      renderCurrentMapMode(mapData);
      return;
    }
    if (playerState.ammo <= 0) {
      combatMessage = "shot=no ammo";
      renderCurrentMapMode(mapData);
      return;
    }

    playerState.ammo -= 1;
    alertEnemiesFromShot(mapData);
    target = findHitscanThing(mapData);
    if (target === null) {
      combatMessage = "shot=miss";
    } else {
      target.thing.health = Math.max(0, target.thing.health - PISTOL_DAMAGE);
      if (target.thing.health === 0) {
        setThingDead(target.thing);
        aiMessage = "killed thing#" + (target.thing.index + 1);
        combatMessage = "shot=kill thing#" + (target.thing.index + 1);
      } else {
        target.thing.aiState = ENEMY_STATE_CHASE;
        aiMessage = "hurt thing#" + (target.thing.index + 1);
        combatMessage = "shot=hit thing#" + (target.thing.index + 1) +
          " hp=" + target.thing.health;
      }
    }
    renderCurrentMapMode(mapData);
  }

  function enemyStateHudText(mapData) {
    const counts = {};
    let total = 0;

    counts[ENEMY_STATE_IDLE] = 0;
    counts[ENEMY_STATE_CHASE] = 0;
    counts[ENEMY_STATE_ATTACK] = 0;
    counts[ENEMY_STATE_DEAD] = 0;

    if (!mapData || !mapData.things) return "";

    mapData.things.forEach(function (thing) {
      let state = thing.aiState || ENEMY_STATE_IDLE;

      if (!isShootableThing(thing)) return;
      if (thing.dead === true || thing.health <= 0) state = ENEMY_STATE_DEAD;
      if (!Object.prototype.hasOwnProperty.call(counts, state)) state = ENEMY_STATE_IDLE;
      counts[state] += 1;
      total += 1;
    });

    if (total === 0) return "";

    return "ai idle=" + counts[ENEMY_STATE_IDLE] +
      " chase=" + counts[ENEMY_STATE_CHASE] +
      " attack=" + counts[ENEMY_STATE_ATTACK] +
      " dead=" + counts[ENEMY_STATE_DEAD] +
      " last=" + aiMessage;
  }

  function enemySummaryText(mapData) {
    const total = shootableThingCount(mapData);

    if (total === 0) return "--";
    return aliveThingCount(mapData) + " alive / " + deadThingCount(mapData) + " dead";
  }

  function gameStateText() {
    const state = currentGameState();

    if (state === GAME_STATE_DEAD) return "Game over";
    if (state === GAME_STATE_PAUSED) return "Paused";
    if (state === GAME_STATE_PLAYING) return "Playing";
    if (loadedMap !== null && playerState === null) return "No player start";
    return "No map loaded";
  }

  function playerFacingCombatMessage() {
    if (combatMessage === "shot=ready") return "Ready.";
    if (combatMessage === "shot=miss") return "Shot missed.";
    if (combatMessage === "shot=no ammo") return "Out of ammo.";
    if (combatMessage === "shot=no weapon") return "No weapon.";
    if (combatMessage === "shot=blocked paused") return "Paused.";
    if (combatMessage === "shot=blocked player dead") return "Game over.";
    if (combatMessage.indexOf("shot=kill") === 0) return "Enemy down.";
    if (combatMessage.indexOf("shot=hit") === 0) return "Enemy hit.";
    return combatMessage;
  }

  function canvasHudMessage(mapData, visibleThingCount) {
    const state = currentGameState();
    const messageParts = [];

    if (playerState === null) return gameStateMessage;
    if (state === GAME_STATE_DEAD) {
      messageParts.push(gameStateMessage);
    } else if (state === GAME_STATE_PAUSED) {
      messageParts.push("Paused.");
    }
    messageParts.push(playerFacingCombatMessage());
    if (interactionMessage !== "") messageParts.push(interactionMessage);
    return messageParts.join(" ");
  }

  function updateHudPanel(mapData, visibleThingCount) {
    const state = currentGameState();

    gameStage.classList.toggle("is-dead", state === GAME_STATE_DEAD);
    gameStage.classList.toggle("is-paused", state === GAME_STATE_PAUSED);
  }

  function drawHudBox(x, y, width, height, label, value, accentColor) {
    context.fillStyle = "rgba(25, 28, 25, 0.94)";
    context.fillRect(x, y, width, height);
    context.strokeStyle = accentColor;
    context.strokeRect(x + 0.5, y + 0.5, width - 1, height - 1);
    context.fillStyle = "#aeb8b0";
    context.font = "7px monospace";
    context.fillText(label, x + 4, y + 8);
    context.fillStyle = "#f2ead2";
    context.font = "bold 11px monospace";
    context.fillText(value, x + 4, y + 21);
  }

  function renderCanvasHud(mapData, visibleThingCount) {
    const hudTop = VIEW_HEIGHT;
    const state = currentGameState();
    const healthText = playerState === null ? "--" : String(playerState.health);
    const ammoText = playerState === null ? "--" : String(playerState.ammo);
    const weaponText = playerState === null ? "--" : playerState.currentWeapon.toUpperCase();
    const enemyText = enemySummaryText(mapData).replace(" alive / ", "/").replace(" dead", "");
    const stateText = gameStateText().toUpperCase();
    const messageText = canvasHudMessage(mapData, visibleThingCount);
    let stateColor = "#8fd9c7";

    if (state === GAME_STATE_DEAD) {
      stateColor = "#ff8f80";
    } else if (state === GAME_STATE_PAUSED) {
      stateColor = "#ffd46f";
    }

    context.save();
    context.imageSmoothingEnabled = false;
    context.fillStyle = "#070807";
    context.fillRect(0, hudTop, WIDTH, HUD_HEIGHT);
    context.fillStyle = "rgba(56, 60, 54, 0.88)";
    context.fillRect(0, hudTop, WIDTH, 3);
    context.strokeStyle = "#6f7b73";
    context.strokeRect(0.5, hudTop + 0.5, WIDTH - 1, HUD_HEIGHT - 1);

    drawHudBox(6, hudTop + 6, 48, 24, "HP", healthText, state === GAME_STATE_DEAD ? "#b84f45" : "#679d87");
    drawHudBox(60, hudTop + 6, 50, 24, "AMMO", ammoText, "#8c9fb0");
    drawHudBox(116, hudTop + 6, 70, 24, "WEAPON", weaponText, "#a9975c");
    drawHudBox(192, hudTop + 6, 62, 24, "ENEMY", enemyText, "#9d6a61");

    context.fillStyle = stateColor;
    context.font = "bold 10px monospace";
    context.textAlign = "right";
    context.fillText(stateText, WIDTH - 8, hudTop + 34);

    context.textAlign = "left";
    context.fillStyle = state === GAME_STATE_DEAD ? "#ffb0a4" : "#d7ddd6";
    context.font = "9px monospace";
    context.fillText(messageText.slice(0, 41), 8, hudTop + 36);
    context.restore();
  }

  function combatHudText(mapData, visibleThingCount) {
    const visible = typeof visibleThingCount === "number" ?
      visibleThingCount : aliveThingCount(mapData);
    const aiHud = enemyStateHudText(mapData);

    if (playerState === null) return "";
    return "HUD hp=" + playerState.health +
      " weapon=" + playerState.currentWeapon +
      " ammo=" + playerState.ammo +
      " visible=" + visible +
      " alive=" + aliveThingCount(mapData) + "/" + shootableThingCount(mapData) +
      " " + combatMessage +
      (aiHud === "" ? "" : " " + aiHud);
  }

  function interactionSuffix(mapData, visibleThingCount) {
    const parts = [];
    const combatHud = combatHudText(mapData, visibleThingCount);

    if (combatHud !== "") parts.push(combatHud);
    if (interactionMessage !== "") parts.push(interactionMessage);
    return parts.length === 0 ? "" : " " + parts.join(" ");
  }

  function renderAndPresent(frameNumber) {
    if (wasmProvider !== null) {
      const checksum = wasmProvider.writeFrame(frameNumber, imageData.data);
      context.putImageData(imageData, 0, 0);
      renderCanvasHud(loadedMap);
      status.textContent = "Frame " + frameNumber + " (WASM checksum " + checksum + ")";
    } else {
      writeFrame(frameNumber, imageData.data);
      context.putImageData(imageData, 0, 0);
      renderCanvasHud(loadedMap);
      status.textContent = "Frame " + frameNumber + " (JS fallback)";
    }
    updateHudPanel(loadedMap);
  }

  function renderTopDownMap(mapData) {
    const data = imageData.data;
    const bounds = mapData.bounds;
    const mapWidth = Math.max(1, bounds.maxX - bounds.minX);
    const mapHeight = Math.max(1, bounds.maxY - bounds.minY);
    const padding = 16;
    const scale = Math.min((WIDTH - padding * 2) / mapWidth, (VIEW_HEIGHT - padding * 2) / mapHeight);
    const centerX = (bounds.minX + bounds.maxX) / 2;
    const centerY = (bounds.minY + bounds.maxY) / 2;

    function toScreen(vertex) {
      return {
        x: WIDTH / 2 + (vertex.x - centerX) * scale,
        y: VIEW_HEIGHT / 2 - (vertex.y - centerY) * scale
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
        const door = doorStateAt(mapData, index);
        if (door !== null && door.state === "open") {
          drawLine(data, startScreen.x, startScreen.y, endScreen.x, endScreen.y, 94, 196, 135);
        } else if (door !== null && door.state === "opening") {
          drawLine(data, startScreen.x, startScreen.y, endScreen.x, endScreen.y, 255, 212, 96);
        } else if (door !== null) {
          drawLine(data, startScreen.x, startScreen.y, endScreen.x, endScreen.y, 240, 128, 96);
        } else if (linedef.leftSidedef >= 0 && linedef.rightSidedef >= 0) {
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

    renderableThings(mapData).forEach(function (thing) {
      const screen = toScreen(thing);
      const color = thingBaseColor(thing);
      const radians = thing.angle * Math.PI / 180;
      const noseX = screen.x + Math.cos(radians) * 7;
      const noseY = screen.y - Math.sin(radians) * 7;
      if (thing.dead === true) {
        drawLine(data, screen.x - 5, screen.y - 5, screen.x + 5, screen.y + 5, 112, 119, 116);
        drawLine(data, screen.x - 5, screen.y + 5, screen.x + 5, screen.y - 5, 112, 119, 116);
      } else {
        drawRing(data, screen.x, screen.y, 5, color.red, color.green, color.blue);
        drawDisk(data, screen.x, screen.y, 2, 24, 28, 30);
        drawLine(data, screen.x, screen.y, noseX, noseY, color.red, color.green, color.blue);
      }
    });

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
    renderCanvasHud(mapData, aliveThingCount(mapData));
    if (playerState !== null) {
      status.textContent = "Map " + mapData.name + " player x=" +
        playerState.x.toFixed(1) + " y=" + playerState.y.toFixed(1) +
        " angle=" + Math.round(playerState.angle) + " (" +
        mapData.vertexes.length + " vertexes, " + mapData.linedefs.length +
        " linedefs, scale " + scale.toFixed(2) + ")" +
        (isPlayerDead() ? " GAME OVER" : paused ? " PAUSED" : "") +
        interactionSuffix(mapData, aliveThingCount(mapData));
    } else {
      status.textContent = "Map " + mapData.name + " top-down: no player start (" +
      mapData.vertexes.length + " vertexes, " + mapData.linedefs.length +
      " linedefs, scale " + scale.toFixed(2) + ")";
    }
    updateHudPanel(mapData, aliveThingCount(mapData));
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
      if (!isSolidLinedef(linedef, mapData, index)) continue;

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
          linedefIndex: index,
          start: start,
          end: end
        };
      }
    }

    return nearestHit;
  }

  function drawVerticalColumn(data, x, y0, y1, red, green, blue) {
    const startY = Math.max(0, Math.floor(y0));
    const endY = Math.min(VIEW_HEIGHT - 1, Math.ceil(y1));

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
    const endY = Math.min(VIEW_HEIGHT - 1, Math.ceil(y1));
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
    const wallDepthByColumn = new Float64Array(WIDTH);
    let hitColumns = 0;
    let texturedColumns = 0;
    let thingSprites = 0;

    wallDepthByColumn.fill(Infinity);

    for (let y = 0; y < VIEW_HEIGHT; y += 1) {
      const ceiling = y < VIEW_HEIGHT / 2;
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
        const rayAngle = playerAngleRadians - angleOffset;
        const hit = findNearestWallHit(mapData, rayAngle);

        if (hit === null) continue;

        const perpendicularDistance = Math.max(
          FIRST_PERSON_NEAR_DISTANCE,
          hit.distance * Math.cos(angleOffset)
        );
        const wallHeight = Math.min(
          VIEW_HEIGHT * 2,
          FIRST_PERSON_WALL_HEIGHT * FIRST_PERSON_PROJECTION_DISTANCE / perpendicularDistance
        );
        const wallTop = VIEW_HEIGHT / 2 - wallHeight / 2;
        const wallBottom = VIEW_HEIGHT / 2 + wallHeight / 2;
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
        wallDepthByColumn[column] = perpendicularDistance;
        hitColumns += 1;
      }
      thingSprites = drawFirstPersonThings(mapData, wallDepthByColumn, playerAngleRadians);
    }

    context.putImageData(imageData, 0, 0);
    renderCanvasHud(mapData, thingSprites);
    if (playerState !== null) {
      status.textContent = "First-person " + mapData.name + " player x=" +
        playerState.x.toFixed(1) + " y=" + playerState.y.toFixed(1) +
        " angle=" + Math.round(playerState.angle) + " (" +
        hitColumns + " wall columns, " + texturedColumns + " textured, " +
        thingSprites + " things)" +
        (isPlayerDead() ? " GAME OVER" : paused ? " PAUSED" : "") +
        interactionSuffix(mapData, thingSprites);
    } else {
      status.textContent = "First-person " + mapData.name + ": no player start";
    }
    updateHudPanel(mapData, thingSprites);
  }

  function drawFirstPersonThings(mapData, wallDepthByColumn, playerAngleRadians) {
    const data = imageData.data;
    const cosAngle = Math.cos(playerAngleRadians);
    const sinAngle = Math.sin(playerAngleRadians);
    const projectedThings = [];
    let drawn = 0;

    aliveRenderableThings(mapData).forEach(function (thing) {
      const dx = thing.x - playerState.x;
      const dy = thing.y - playerState.y;
      const forward = dx * cosAngle + dy * sinAngle;
      const right = dx * sinAngle - dy * cosAngle;

      if (forward <= FIRST_PERSON_NEAR_DISTANCE) return;

      const screenX = WIDTH / 2 + (right / forward) * FIRST_PERSON_PROJECTION_DISTANCE;
      const spriteHeight = FIRST_PERSON_THING_HEIGHT * FIRST_PERSON_PROJECTION_DISTANCE / forward;
      const spriteWidth = spriteHeight * FIRST_PERSON_THING_WIDTH_RATIO;

      if (screenX + spriteWidth / 2 < 0 || screenX - spriteWidth / 2 >= WIDTH) return;

      projectedThings.push({
        thing: thing,
        distance: forward,
        screenX: screenX,
        top: VIEW_HEIGHT / 2 - spriteHeight * 0.62,
        bottom: VIEW_HEIGHT / 2 + spriteHeight * 0.38,
        width: spriteWidth
      });
    });

    projectedThings.sort(function (left, right) {
      return right.distance - left.distance;
    });

    projectedThings.forEach(function (sprite) {
      const color = thingBaseColor(sprite.thing);
      const shade = Math.max(0.32, Math.min(1, 180 / (sprite.distance + 72)));
      const halfWidth = sprite.width / 2;
      const centerX = sprite.screenX;
      const top = sprite.top;
      const bottom = sprite.bottom;
      const height = Math.max(1, bottom - top);
      const xStart = Math.max(0, Math.floor(centerX - halfWidth));
      const xEnd = Math.min(WIDTH - 1, Math.ceil(centerX + halfWidth));
      const yStart = Math.max(0, Math.floor(top));
      const yEnd = Math.min(VIEW_HEIGHT - 1, Math.ceil(bottom));
      let pixelsDrawn = 0;

      for (let x = xStart; x <= xEnd; x += 1) {
        if (sprite.distance >= wallDepthByColumn[x]) continue;

        const normalizedX = halfWidth <= 0 ? 0 : (x + 0.5 - centerX) / halfWidth;
        for (let y = yStart; y <= yEnd; y += 1) {
          const normalizedY = (y + 0.5 - top) / height;
          const bodyWidth = normalizedY < 0.22 ?
            0.42 + normalizedY * 1.45 :
            0.92 - Math.max(0, normalizedY - 0.22) * 0.18;

          if (Math.abs(normalizedX) > bodyWidth) continue;
          if (normalizedY > 0.84 && Math.abs(normalizedX) < 0.20) continue;

          const edge = Math.abs(normalizedX) > bodyWidth - 0.08 ||
            normalizedY < 0.08 || normalizedY > 0.90;
          const verticalShade = 1 - Math.max(0, normalizedY - 0.35) * 0.34;
          const destinationOffset = (y * WIDTH + x) * 4;

          if (edge) {
            data[destinationOffset] = Math.round(34 * shade);
            data[destinationOffset + 1] = Math.round(38 * shade);
            data[destinationOffset + 2] = Math.round(36 * shade);
          } else {
            data[destinationOffset] = Math.round(color.red * shade * verticalShade);
            data[destinationOffset + 1] = Math.round(color.green * shade * verticalShade);
            data[destinationOffset + 2] = Math.round(color.blue * shade * verticalShade);
          }
          data[destinationOffset + 3] = 255;
          pixelsDrawn += 1;
        }
      }

      if (pixelsDrawn > 0) drawn += 1;
    });

    return drawn;
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

  function renderActiveMode() {
    if (isMapRenderMode(renderMode) && loadedMap !== null) {
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
      const deltaSeconds = (timestamp - lastMapStep) / 1000;
      if (!paused && !isPlayerDead()) {
        updatePlayerFromInput(loadedMap, deltaSeconds);
        updateDoorStates(loadedMap, deltaSeconds);
        updateEnemyAi(loadedMap, deltaSeconds);
      }
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

  function parseThings(thingsView) {
    const thingCount = checkedRecordCount("THINGS", thingsView, THING_SIZE);
    const things = [];

    for (let index = 0; index < thingCount; index += 1) {
      const offset = index * THING_SIZE;
      const thingType = thingsView.getInt16(offset + 6, true);
      things.push({
        index: index,
        x: thingsView.getInt16(offset, true),
        y: thingsView.getInt16(offset + 2, true),
        angle: normalizeAngle(thingsView.getInt16(offset + 4, true)),
        type: thingType,
        thingType: thingType,
        flags: thingsView.getInt16(offset + 8, true)
      });
    }
    return things;
  }

  function parsePlayerStart(things) {
    for (let index = 0; index < things.length; index += 1) {
      if (things[index].type === 1) return things[index];
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
      if (!isSolidLinedef(linedef, mapData, index)) continue;
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

  function computeMapBounds(vertexes, things) {
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
    for (let index = 0; index < things.length; index += 1) {
      includePoint(things[index]);
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
    let things = [];
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

    things = parseThings(views.THINGS);
    playerStart = parsePlayerStart(things);
    vertexes = parseVertexes(views.VERTEXES);
    linedefs = parseLinedefs(views.LINEDEFS, vertexes.length);
    sidedefs = parseSidedefs(views.SIDEDEFS);

    mapData = {
      name: wad.lumps[markerIndex].name,
      counts: counts,
      things: things,
      playerStart: playerStart,
      vertexes: vertexes,
      linedefs: linedefs,
      sidedefs: sidedefs,
      bounds: computeMapBounds(vertexes, things),
      doors: new Map(),
      textureSet: unavailableTextureSet("not loaded", 0)
    };
    mapData.doors = createDoorStates(mapData);
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

  function displayWadInfo(file, buffer, wad, preferredMode) {
    const previewCount = Math.min(wad.lumps.length, 24);
    const nextMode = preferredMode === "firstPerson" ? "firstPerson" : "map";

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
    interactionMessage = "";
    combatMessage = "shot=ready";
    aiMessage = "none";
    gameStateMessage = "No supported map loaded.";
    pressedKeys.clear();
    mapModeButton.disabled = true;
    firstPersonModeButton.disabled = true;
    updateHudPanel(null);

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
        resetPlayableState(loadedMap);
        mapModeButton.disabled = false;
        firstPersonModeButton.disabled = false;
        appendDescription(mapSummary, "Map", mapData.name);
        appendDescription(mapSummary, "Vertexes", String(mapData.counts.vertexes));
        appendDescription(mapSummary, "Linedefs", String(mapData.counts.linedefs));
        appendDescription(mapSummary, "Sidedefs", String(mapData.counts.sidedefs));
        appendDescription(mapSummary, "Sectors", String(mapData.counts.sectors));
        appendDescription(mapSummary, "Things", String(mapData.counts.things));
        appendDescription(mapSummary, "Renderable things", String(renderableThings(mapData).length));
        appendDescription(mapSummary, "Shootable things", String(shootableThingCount(mapData)));
        appendDescription(mapSummary, "Enemy AI", shootableThingCount(mapData) > 0 ?
          "basic idle/chase/attack/dead placeholders" : "No shootable enemies");
        if (mapData.doors.size > 0) {
          appendDescription(mapSummary, "Line specials",
            mapData.doors.size + " synthetic door special " + SYNTHETIC_DOOR_SPECIAL);
        }
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
        setRenderMode(nextMode);
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
    interactionMessage = "";
    combatMessage = "shot=ready";
    aiMessage = "none";
    gameStateMessage = "WAD parse failed.";
    pressedKeys.clear();
    mapModeButton.disabled = true;
    firstPersonModeButton.disabled = true;
    if (isMapRenderMode(renderMode)) setRenderMode("framebuffer");
    wadStatus.textContent = "WAD parse failed: " + message;
    updateHudPanel(null);
  }

  function loadWadFile(file) {
    if (!file) {
      wadStatus.textContent = "No WAD selected.";
      clearNode(wadSummary);
      clearNode(wadLumps);
      clearNode(mapSummary);
      loadedMap = null;
      playerState = null;
      interactionMessage = "";
      combatMessage = "shot=ready";
      aiMessage = "none";
      gameStateMessage = "No WAD selected.";
      pressedKeys.clear();
      mapModeButton.disabled = true;
      firstPersonModeButton.disabled = true;
      if (isMapRenderMode(renderMode)) setRenderMode("framebuffer");
      updateHudPanel(null);
      return;
    }

    wadStatus.textContent = "Loading " + file.name + "...";
    file.arrayBuffer()
      .then(function (buffer) {
        const wad = parseWadDirectory(buffer);
        displayWadInfo(file, buffer, wad, "firstPerson");
        wadStatus.textContent = "Parsed " + file.name + ".";
      })
      .catch(function (error) {
        displayWadError(error.message);
      });
  }

  function loadDefaultDemoWad() {
    const demoUrl = new URL(DEFAULT_DEMO_WAD_URL, window.location.href);

    wadStatus.textContent = "Loading bundled demo map...";
    fetch(demoUrl.href, { cache: "no-store" })
      .then(function (response) {
        if (!response.ok) {
          throw new Error("HTTP " + response.status);
        }
        return response.arrayBuffer();
      })
      .then(function (buffer) {
        const wad = parseWadDirectory(buffer);
        displayWadInfo({ name: "demo_map.pwad" }, buffer, wad, "firstPerson");
        wadStatus.textContent = "Bundled demo map loaded.";
      })
      .catch(function (error) {
        displayWadError("default demo map unavailable: " + error.message);
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
              renderActiveMode();
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
    setPaused(!paused);
    if (isMapRenderMode(renderMode) && loadedMap !== null) {
      renderCurrentMapMode(loadedMap);
    }
  });

  resetButton.addEventListener("click", function () {
    if (isMapRenderMode(renderMode)) {
      resetPlayableState(loadedMap);
      renderCurrentMapMode(loadedMap);
    } else {
      frame = 0;
      pressedKeys.clear();
      setPaused(false);
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

  canvas.addEventListener("mousedown", function (event) {
    if (event.button !== 0) return;
    if (isMapRenderMode(renderMode) && loadedMap !== null) {
      fireCurrentWeapon(loadedMap);
      event.preventDefault();
    }
  });

  window.addEventListener("keydown", function (event) {
    const controlledKey = event.code === "KeyW" ||
      event.code === "KeyA" ||
      event.code === "KeyS" ||
      event.code === "KeyD" ||
      event.code === "KeyF" ||
      event.code === "KeyQ" ||
      event.code === "KeyE" ||
      event.code === "ControlLeft" ||
      event.code === "ControlRight" ||
      event.code === "ArrowLeft" ||
      event.code === "ArrowRight" ||
      event.code === "Space";

    if (!controlledKey) return;
    if (paused && isMapRenderMode(renderMode) && loadedMap !== null) {
      pressedKeys.clear();
      event.preventDefault();
      return;
    }
    if (event.code === "Space" && isMapRenderMode(renderMode) && loadedMap !== null) {
      if (isPlayerDead()) {
        interactionMessage = "Use blocked: player dead.";
        renderCurrentMapMode(loadedMap);
        event.preventDefault();
        return;
      }
      if (!event.repeat) useLinedefInFront(loadedMap);
      event.preventDefault();
      return;
    }
    if ((event.code === "KeyF" || event.code === "ControlLeft" || event.code === "ControlRight") &&
        isMapRenderMode(renderMode) && loadedMap !== null) {
      if (!event.repeat) fireCurrentWeapon(loadedMap);
      event.preventDefault();
      return;
    }
    if (isPlayerDead() && isMapRenderMode(renderMode)) {
      pressedKeys.clear();
      event.preventDefault();
      return;
    }
    pressedKeys.add(event.code);
    if (isMapRenderMode(renderMode)) {
      event.preventDefault();
    }
  });

  window.addEventListener("keyup", function (event) {
    pressedKeys.delete(event.code);
  });

  renderAndPresent(frame);
  loadDefaultDemoWad();
  loadGeneratedWasmProvider();
  window.requestAnimationFrame(draw);
}());
