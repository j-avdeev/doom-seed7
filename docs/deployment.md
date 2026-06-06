# Deployment

Task 16.1 deploys the current static playable browser demo to GitHub Pages. It
publishes the committed `web/` directory as-is; it does not rebuild Seed7,
Emscripten, or generated WASM in GitHub Actions.

## Local Run

Serve the repository locally:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\serve-web.ps1
```

or:

```bash
tools/serve-web.sh
```

Open:

```text
http://localhost:8080/web/index.html
```

## GitHub Pages Run

The deployment workflow is:

```text
.github/workflows/pages.yml
```

It runs automatically on pushes to `main` that change `web/**` or the workflow
file, and it can also be run manually from the Actions tab with
`workflow_dispatch`.

To enable Pages:

1. Push this workflow to the repository's `main` branch.
2. In GitHub, open `Settings -> Pages`.
3. Set `Build and deployment` source to `GitHub Actions`.
4. Run `Deploy playable web demo` from the Actions tab, or push a matching
   change to `main`.

The expected URL is:

```text
https://<owner>.github.io/<repository>/
```

The workflow uploads `web/` as the site root, so `web/index.html` is served as
the Pages root `index.html`.

## Deployed Assets

The static Pages artifact includes:

```text
web/.nojekyll
web/index.html
web/audio.js
web/main.js
web/styles.css
web/assets/demo_map.pwad
web/wasm/framebuffer_demo.js
web/wasm/framebuffer_demo.wasm
web/wasm/wasm_probe.js
web/wasm/wasm_probe.wasm
```

The workflow checks that those files exist and rejects unexpected additional
`.wad` files under `web/`. The bundled `demo_map.pwad` is a generated
non-commercial synthetic fixture.

## Debugging Pages

If the page loads but the WASM provider fails, open the collapsed `Debug` panel.
The demo remains playable through the JavaScript WAD/rendering bridge, while the
Framebuffer debug mode falls back if `web/wasm/framebuffer_demo.js` or
`web/wasm/framebuffer_demo.wasm` cannot load.

Check:

- GitHub Pages source is set to `GitHub Actions`, not a branch folder.
- The `Deploy playable web demo` workflow completed successfully.
- Browser devtools Network shows `framebuffer_demo.js`,
  `framebuffer_demo.wasm`, and `assets/demo_map.pwad` returning HTTP 200.
- The Pages URL is the repository root URL, not `/web/index.html`.

## Known Limitations

- CI does not rebuild Seed7-generated WASM; committed `web/wasm/` artifacts are
  deployed.
- The gameplay/rendering bridge is still temporary JavaScript.
- Generated browser sound effects are included through `web/audio.js`, but no
  music, Doom sound lump decoding, save/load, CI rebuild, commercial WAD assets,
  or real Doom assets are part of this deployment.
