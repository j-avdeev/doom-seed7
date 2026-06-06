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
  const context = canvas.getContext("2d", { alpha: false });
  const imageData = context.createImageData(WIDTH, HEIGHT);

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

  renderAndPresent(frame);
  loadGeneratedWasmProvider();
  window.requestAnimationFrame(draw);
}());
