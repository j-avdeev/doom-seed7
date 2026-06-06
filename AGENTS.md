# Project: Seed7 Doom Browser Port

Goal: implement a playable Doom-compatible engine in Seed7, compiled to browser WebAssembly through Seed7 -> C -> Emscripten.

Do not attempt a full PrBoom+/Dwasm rewrite in one task.

Development rules:
- Work by milestones.
- Prefer small, verifiable commits.
- Every task must end with build/test instructions.
- Keep Seed7 code idiomatic; do not blindly translate C pointers.
- Replace C pointer-heavy structures with arrays, records, indexes, and explicit IDs.
- Browser target must use a JS wrapper with Canvas framebuffer first; WebGL is optional later.
- First playable target: DOOM shareware E1M1 or Freedoom equivalent.
- First renderer target: software framebuffer, not WebGL.
- First audio target: no audio; add WebAudio later.
- Keep docs updated after each milestone.

Definition of done:
- Code builds.
- Minimal test or demo exists.
- Documentation explains what was implemented.
- Browser demo remains runnable after each milestone.