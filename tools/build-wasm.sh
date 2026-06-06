#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENTRY="${1:-src/platform/framebuffer_demo.s7}"
PROBE_ENTRY="src/platform/wasm_probe.s7"
BUILD_ROOT="$ROOT_DIR/build/wasm-generated"
OUT_DIR="$ROOT_DIR/web/wasm"
EMCC="${EMCC:-$ROOT_DIR/emsdk/upstream/emscripten/emcc}"

if [[ ! -x "$EMCC" ]]; then
  echo "Emscripten compiler not found or not executable: $EMCC" >&2
  exit 1
fi

if [[ ! -f "$PROBE_ENTRY" ]]; then
  echo "Seed7 WASM probe source not found: $PROBE_ENTRY" >&2
  exit 1
fi

if [[ ! -f "$ENTRY" ]]; then
  echo "Seed7 entrypoint not found: $ENTRY" >&2
  exit 1
fi

NODE_BIN_DIR=""
if compgen -G "$ROOT_DIR/emsdk/node/*/bin" > /dev/null; then
  NODE_BIN_DIR="$(echo "$ROOT_DIR"/emsdk/node/*/bin | awk '{print $1}')"
fi

export PATH="$ROOT_DIR/emsdk/upstream/emscripten:$ROOT_DIR/emsdk/upstream/bin${NODE_BIN_DIR:+:$NODE_BIN_DIR}:$PATH"

mkdir -p "$BUILD_ROOT" "$OUT_DIR"

build_seed7_generated_wasm() {
  local source_path="$1"
  local target_name="$2"
  local build_dir="$BUILD_ROOT/$target_name"
  local target_source="$build_dir/$target_name"
  local expected_text="${3:-}"
  local generated_c="$build_dir/tmp_${target_name}.c"
  local exported_functions="_main,_setEnvironmentVar,_setOsProperties"
  local exported_runtime_methods="ccall,cwrap,UTF8ToString"

  rm -rf "$build_dir"
  mkdir -p "$build_dir"
  cp "$source_path" "$target_source"

  echo "Generating C for $source_path"
  (
    cd "$build_dir"
    node --stack-size=8192 "../../../seed7/bin/s7.js" \
      -l "../../../seed7/lib" \
      "../../../seed7/prg/s7c.sd7" \
      -l "../../../seed7/lib" \
      -b "../../../seed7/bin" \
      -g -O2 -oc3 "$target_name"
  )

  if [[ ! -f "$build_dir/tmp_${target_name}.o" ]]; then
    echo "Generated object missing: $build_dir/tmp_${target_name}.o" >&2
    exit 1
  fi

  if [[ ! -f "$generated_c" ]]; then
    echo "Generated C source missing: $generated_c" >&2
    exit 1
  fi

  if [[ "$target_name" == "framebuffer_demo" ]]; then
    local pixel_red
    local pixel_green
    local pixel_blue
    local generated_c_include="$generated_c"

    pixel_red="$(grep -E 'static .*o_[0-9]+_pixelRed ' "$generated_c" | sed -E 's/.*(o_[0-9]+_pixelRed).*/\1/' | head -n 1)"
    pixel_green="$(grep -E 'static .*o_[0-9]+_pixelGreen ' "$generated_c" | sed -E 's/.*(o_[0-9]+_pixelGreen).*/\1/' | head -n 1)"
    pixel_blue="$(grep -E 'static .*o_[0-9]+_pixelBlue ' "$generated_c" | sed -E 's/.*(o_[0-9]+_pixelBlue).*/\1/' | head -n 1)"

    if [[ -z "$pixel_red" || -z "$pixel_green" || -z "$pixel_blue" ]]; then
      echo "Could not discover generated Seed7 framebuffer pixel symbols." >&2
      exit 1
    fi

    if command -v cygpath >/dev/null 2>&1; then
      generated_c_include="$(cygpath -m "$generated_c")"
    fi

    exported_functions+=",_doom_init,_doom_tick,_doom_framebuffer_ptr"
    exported_functions+=",_doom_framebuffer_width,_doom_framebuffer_height"
    exported_functions+=",_doom_framebuffer_size,_doom_framebuffer_checksum"
    exported_functions+=",_doom_framebuffer_frame"

    echo "Relinking $target_name with Seed7-generated framebuffer bridge"
    "$EMCC" "$ROOT_DIR/src/platform/wasm_framebuffer_bridge.c" \
      -w -O2 -g \
      "-DSEED7_FRAMEBUFFER_GENERATED_C=\"$generated_c_include\"" \
      "-DSEED7_PIXEL_RED=$pixel_red" \
      "-DSEED7_PIXEL_GREEN=$pixel_green" \
      "-DSEED7_PIXEL_BLUE=$pixel_blue" \
      "$ROOT_DIR/seed7/bin/s7_data_emc.a" \
      "$ROOT_DIR/seed7/bin/seed7_05_emc.a" \
      -sASSERTIONS=0 \
      -sALLOW_MEMORY_GROWTH=1 \
      -sEXIT_RUNTIME=0 \
      -sFORCE_FILESYSTEM=1 \
      -sEXPORTED_FUNCTIONS="$exported_functions" \
      -sEXPORTED_RUNTIME_METHODS="$exported_runtime_methods" \
      -lnodefs.js \
      --pre-js "$ROOT_DIR/wasm/pre_js_browser.js" \
      -o "$OUT_DIR/${target_name}.js"
  else
    echo "Relinking $target_name with browser/Node-safe Emscripten exports"
    "$EMCC" "$build_dir/tmp_${target_name}.o" \
    "$ROOT_DIR/seed7/bin/s7_data_emc.a" \
    "$ROOT_DIR/seed7/bin/seed7_05_emc.a" \
    -sASSERTIONS=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=0 \
    -sFORCE_FILESYSTEM=1 \
      -sEXPORTED_FUNCTIONS="$exported_functions" \
      -sEXPORTED_RUNTIME_METHODS="$exported_runtime_methods" \
    -lnodefs.js \
    --pre-js "$ROOT_DIR/wasm/pre_js_browser.js" \
    -o "$OUT_DIR/${target_name}.js"
  fi

  if [[ ! -f "$OUT_DIR/${target_name}.js" || ! -f "$OUT_DIR/${target_name}.wasm" ]]; then
    echo "Expected WASM artifacts were not created for $target_name" >&2
    exit 1
  fi

  if [[ -n "$expected_text" ]]; then
    echo "Node smoke for $target_name"
    local smoke_output
    smoke_output="$(node "$OUT_DIR/${target_name}.js" "${@:4}" 2>&1)"
    echo "$smoke_output"
    if [[ "$smoke_output" != *"$expected_text"* ]]; then
      echo "Node smoke did not contain expected text: $expected_text" >&2
      exit 1
    fi
  fi
}

build_seed7_generated_wasm "$PROBE_ENTRY" "wasm_probe" "seed7_wasm_probe ok value=1337"

if [[ "$ENTRY" == "$PROBE_ENTRY" ]]; then
  echo "Built probe only."
else
  build_seed7_generated_wasm "$ENTRY" "$(basename "$ENTRY" .s7)" \
    "framebuffer_demo width=320 height=200 frame=12 checksum=261054247" \
    --frame 12 --frames 1
fi

cat <<MSG
Generated WASM artifacts written to:
  $OUT_DIR

Browser smoke:
  python -m http.server 8080
  open http://localhost:8080/web/index.html
MSG
