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
  const MAP_LUMPS = ["THINGS", "LINEDEFS", "SIDEDEFS", "VERTEXES", "SECTORS"];

  let frame = 0;
  let paused = false;
  let lastStep = 0;
  let wasmProvider = null;

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

  function draw(timestamp) {
    if (!paused && timestamp - lastStep >= 33) {
      renderAndPresent(frame);
      frame += 1;
      lastStep = timestamp;
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

  function checkedLumpData(buffer, lump) {
    const end = lump.dataOffset + lump.dataSize;
    if (lump.dataOffset < 0 || lump.dataSize < 0 || end > buffer.byteLength) {
      throw new Error("lump data exceeds file size: " + lump.name);
    }
    return new DataView(buffer, lump.dataOffset, lump.dataSize);
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

  function parseMapStats(buffer, wad) {
    const markerIndex = findFirstSupportedMap(wad);
    const counts = {};
    const views = {};

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

    return {
      name: wad.lumps[markerIndex].name,
      counts: counts,
      playerStart: parsePlayerStart(views.THINGS)
    };
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
      const mapStats = parseMapStats(buffer, wad);
      if (mapStats === null) {
        appendDescription(mapSummary, "Map", "No E1M1 or MAP01 marker found");
      } else {
        appendDescription(mapSummary, "Map", mapStats.name);
        appendDescription(mapSummary, "Vertexes", String(mapStats.counts.vertexes));
        appendDescription(mapSummary, "Linedefs", String(mapStats.counts.linedefs));
        appendDescription(mapSummary, "Sidedefs", String(mapStats.counts.sidedefs));
        appendDescription(mapSummary, "Sectors", String(mapStats.counts.sectors));
        appendDescription(mapSummary, "Things", String(mapStats.counts.things));
        if (mapStats.playerStart === null) {
          appendDescription(mapSummary, "Player start", "Missing");
        } else {
          appendDescription(mapSummary, "Player start",
            mapStats.playerStart.x + ", " + mapStats.playerStart.y +
            " angle=" + mapStats.playerStart.angle);
        }
      }
    } catch (error) {
      appendDescription(mapSummary, "Map", "Could not load statistics: " + error.message);
    }
  }

  function displayWadError(message) {
    clearNode(wadSummary);
    clearNode(wadLumps);
    clearNode(mapSummary);
    wadStatus.textContent = "WAD parse failed: " + message;
  }

  function loadWadFile(file) {
    if (!file) {
      wadStatus.textContent = "No WAD selected.";
      clearNode(wadSummary);
      clearNode(wadLumps);
      clearNode(mapSummary);
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
    renderAndPresent(frame);
  });

  wadFileInput.addEventListener("change", function () {
    loadWadFile(wadFileInput.files[0]);
  });

  renderAndPresent(frame);
  loadGeneratedWasmProvider();
  window.requestAnimationFrame(draw);
}());
