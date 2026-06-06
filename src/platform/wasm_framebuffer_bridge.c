/*
 * wasm_framebuffer_bridge.c
 *
 * Thin Emscripten ABI for the Seed7-generated framebuffer demo.
 * The build script defines SEED7_FRAMEBUFFER_GENERATED_C and the
 * generated pixel function names before compiling this file.
 */

#include <stdint.h>

#ifndef SEED7_FRAMEBUFFER_GENERATED_C
#error "SEED7_FRAMEBUFFER_GENERATED_C must point at tmp_framebuffer_demo.c"
#endif

#ifndef SEED7_PIXEL_RED
#error "SEED7_PIXEL_RED must name the generated Seed7 red pixel function"
#endif

#ifndef SEED7_PIXEL_GREEN
#error "SEED7_PIXEL_GREEN must name the generated Seed7 green pixel function"
#endif

#ifndef SEED7_PIXEL_BLUE
#error "SEED7_PIXEL_BLUE must name the generated Seed7 blue pixel function"
#endif

#define main seed7_framebuffer_cli_main
#define startMain seed7_framebuffer_startMain
#include SEED7_FRAMEBUFFER_GENERATED_C
#undef main
#undef startMain

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#else
#define EMSCRIPTEN_KEEPALIVE
#endif

#define DOOM_FRAMEBUFFER_WIDTH 320
#define DOOM_FRAMEBUFFER_HEIGHT 200
#define DOOM_FRAMEBUFFER_BYTES (DOOM_FRAMEBUFFER_WIDTH * DOOM_FRAMEBUFFER_HEIGHT * 4)
#define DOOM_CHECKSUM_MOD 1000000007

static uint8_t doom_framebuffer[DOOM_FRAMEBUFFER_BYTES];
static int doom_current_frame = 0;
static int doom_last_checksum = 0;

EMSCRIPTEN_KEEPALIVE
int doom_tick(int frame_number);

static int doom_update_checksum(void) {
  int64_t sum = 0;

  for (int offset = 0; offset < DOOM_FRAMEBUFFER_BYTES; offset += 1) {
    sum = (sum * 131 + doom_framebuffer[offset]) % DOOM_CHECKSUM_MOD;
  }
  doom_last_checksum = (int)sum;
  return doom_last_checksum;
}

EMSCRIPTEN_KEEPALIVE
int main(int argc, char **argv) {
  return seed7_framebuffer_cli_main(argc, argv);
}

EMSCRIPTEN_KEEPALIVE
void doom_init(int width, int height) {
  (void)width;
  (void)height;
  doom_tick(0);
}

EMSCRIPTEN_KEEPALIVE
int doom_tick(int frame_number) {
  int offset = 0;

  doom_current_frame = frame_number;
  for (int y = 0; y < DOOM_FRAMEBUFFER_HEIGHT; y += 1) {
    for (int x = 0; x < DOOM_FRAMEBUFFER_WIDTH; x += 1) {
      doom_framebuffer[offset] = (uint8_t)SEED7_PIXEL_RED(x, y, frame_number);
      doom_framebuffer[offset + 1] = (uint8_t)SEED7_PIXEL_GREEN(x, y, frame_number);
      doom_framebuffer[offset + 2] = (uint8_t)SEED7_PIXEL_BLUE(x, y, frame_number);
      doom_framebuffer[offset + 3] = 255;
      offset += 4;
    }
  }
  return doom_update_checksum();
}

EMSCRIPTEN_KEEPALIVE
int doom_framebuffer_ptr(void) {
  return (int)(uintptr_t)doom_framebuffer;
}

EMSCRIPTEN_KEEPALIVE
int doom_framebuffer_width(void) {
  return DOOM_FRAMEBUFFER_WIDTH;
}

EMSCRIPTEN_KEEPALIVE
int doom_framebuffer_height(void) {
  return DOOM_FRAMEBUFFER_HEIGHT;
}

EMSCRIPTEN_KEEPALIVE
int doom_framebuffer_size(void) {
  return DOOM_FRAMEBUFFER_BYTES;
}

EMSCRIPTEN_KEEPALIVE
int doom_framebuffer_checksum(void) {
  return doom_last_checksum;
}

EMSCRIPTEN_KEEPALIVE
int doom_framebuffer_frame(void) {
  return doom_current_frame;
}
