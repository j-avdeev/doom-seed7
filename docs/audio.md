# Basic Browser Sound Effects

Task 17 adds short placeholder sound effects to the static `web/` browser demo.
The implementation is browser-side JavaScript and does not change the
Seed7-generated WASM framebuffer provider.

## Implementation

Audio lives in:

```text
web/audio.js
```

`web/main.js` creates the audio manager and triggers named sound events from
existing gameplay transitions. The manager uses the browser WebAudio API to
generate tiny oscillator and noise bursts at runtime. No audio files are
bundled, and no commercial Doom or Doom 3 sound assets are included.

Current sound events:

- pistol fire;
- enemy hit;
- enemy death;
- player hurt from enemy melee;
- door/use interaction;
- level complete;
- game over.

## Browser Autoplay

Browsers generally block audio until a user gesture occurs. The demo therefore
creates/resumes the `AudioContext` only after user interaction, such as clicking
the game, pressing a gameplay key, pressing Reset/Fullscreen, or using the audio
button.

The toolbar has a compact `Audio` / `Audio On` / `Muted` / `Audio N/A` button.
The collapsed Debug panel also reports the current audio state. If WebAudio is
unavailable or initialization fails, audio is disabled and gameplay continues.

## Limitations

- No music.
- No real Doom sound lump decoding.
- No WAD `DS*` sound playback.
- No positional audio, mixing priorities, or actor sound channels.
- Sounds are generated placeholders and may differ between browsers.
- Muting only affects this demo's generated sound effects.

## Verification

Recommended checks:

```bash
node --check web/audio.js
node --check web/main.js
```

Then serve the static demo:

```bash
python -m http.server 8080 --bind 127.0.0.1
```

Open:

```text
http://localhost:8080/web/index.html
```

Verify:

- the demo starts cleanly with the bundled `web/assets/demo_map.pwad`;
- clicking the game or pressing a gameplay key unlocks audio when the browser
  permits it;
- shooting plays a short pistol sound;
- hitting and killing the placeholder enemy play separate sounds;
- enemy melee damage plays a player-hurt sound;
- pressing `Space` on a door/use target plays a short use sound;
- completing the level plays a short completion sound;
- game over plays a short descending sound;
- the toolbar mute/unmute button works;
- muted or unavailable audio does not stop movement, combat, level completion,
  reset, manual WAD upload, or framebuffer debug mode.
