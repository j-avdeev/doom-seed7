param(
  [string]$Url = "https://j-avdeev.github.io/doom-seed7/doom3.html?entry=doom3_seed7_runtime.s7",
  [string]$ChromePath = "",
  [int]$Port = 9340,
  [string]$ScreenshotPath = ""
)

$ErrorActionPreference = "Stop"

function Find-Chrome {
  $programFilesX86 = ${env:ProgramFiles(x86)}
  $candidates = @(@(
    $ChromePath,
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "$programFilesX86\Google\Chrome\Application\chrome.exe",
    "$env:LocalAppData\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "$programFilesX86\Microsoft\Edge\Application\msedge.exe",
    "$env:LocalAppData\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe",
    "$programFilesX86\BraveSoftware\Brave-Browser\Application\brave.exe",
    "$env:LocalAppData\BraveSoftware\Brave-Browser\Application\brave.exe"
  ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) })
  if ($candidates.Count -eq 0) {
    throw "Chrome, Edge, or Brave was not found. Pass -ChromePath to run browser visual smoke."
  }
  return $candidates[0]
}

$browser = Find-Chrome
$userData = Join-Path $env:TEMP ("doom-pages-chrome-" + [guid]::NewGuid().ToString("N"))
$scriptPath = Join-Path $env:TEMP ("doom-pages-visual-" + [guid]::NewGuid().ToString("N") + ".js")
$cacheBust = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
if ($Url.Contains("?")) {
  $smokeUrl = "$Url&visual_smoke=$cacheBust"
} else {
  $smokeUrl = "$Url?visual_smoke=$cacheBust"
}

$script = @'
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';

const url = process.env.SMOKE_URL;
const port = Number(process.env.CDP_PORT || 9340);
const screenshotPath = process.env.SCREENSHOT_PATH || '';
const base = `http://127.0.0.1:${port}`;
const badResponses = [];
const errors = [];

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function getJson(path) {
  const response = await fetch(base + path);
  if (!response.ok) throw new Error(`${path} -> HTTP ${response.status}`);
  return response.json();
}

async function waitForPageTarget() {
  for (let i = 0; i < 100; i++) {
    try {
      const list = await getJson('/json/list');
      const target = list.find(item => item.type === 'page' && item.webSocketDebuggerUrl);
      if (target) return target;
    } catch (_) {}
    await sleep(200);
  }
  throw new Error('Chrome DevTools page target did not appear');
}

const target = await waitForPageTarget();
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  ws.onopen = resolve;
  ws.onerror = reject;
});

let nextId = 1;
const pending = new Map();
ws.onmessage = event => {
  const msg = JSON.parse(event.data);
  if (msg.id && pending.has(msg.id)) {
    const waiter = pending.get(msg.id);
    pending.delete(msg.id);
    if (msg.error) waiter.reject(new Error(JSON.stringify(msg.error)));
    else waiter.resolve(msg.result || {});
    return;
  }
  if (msg.method === 'Network.responseReceived' && msg.params.response.status >= 400) {
    badResponses.push({ status: msg.params.response.status, url: msg.params.response.url });
  }
  if (msg.method === 'Runtime.exceptionThrown') {
    errors.push(msg.params.exceptionDetails && msg.params.exceptionDetails.text || 'exceptionThrown');
  }
  if (msg.method === 'Log.entryAdded') {
    const entry = msg.params.entry || {};
    if (entry.level === 'error') errors.push(entry.text || JSON.stringify(entry));
  }
};

function send(method, params = {}) {
  const id = nextId++;
  ws.send(JSON.stringify({ id, method, params }));
  return new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
}

async function evaluate(expression) {
  const result = await send('Runtime.evaluate', {
    expression,
    awaitPromise: true,
    returnByValue: true,
    timeout: 30000
  });
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.text || 'Runtime.evaluate failed');
  return result.result && result.result.value;
}

await send('Page.enable');
await send('Runtime.enable');
await send('Network.enable');
await send('Log.enable');
await send('Page.navigate', { url });

for (let i = 0; i < 100; i++) {
  const ready = await evaluate('document.readyState');
  if (ready === 'complete' || ready === 'interactive') break;
  await sleep(200);
}
await sleep(800);

const before = await evaluate(`(() => ({
  title: document.title,
  hasLaunch: !!document.getElementById('runButton'),
  oldSynthetic: document.body.innerText.includes('Run Synthetic Fixture'),
  oldGameModule: document.documentElement.innerHTML.includes('doom3_seed7_game.s7'),
  engineModule: document.documentElement.innerHTML.includes('doom3_seed7_engine.s7'),
  url: location.href
}))()`);

if (!before.hasLaunch) throw new Error('Launch button not found: ' + JSON.stringify(before));
if (before.oldSynthetic) throw new Error('Old synthetic launcher UI is still visible');
if (before.oldGameModule) throw new Error('Old simple game module is still wired into launcher');
if (!before.engineModule) throw new Error('Engine module marker missing before launch');

await evaluate(`document.getElementById('runButton').click(); true`);

let observed = null;
for (let i = 0; i < 160; i++) {
  observed = await evaluate(`(() => {
    const c = document.querySelector('canvas');
    const rect = c ? c.getBoundingClientRect() : null;
    return {
      canvas: !!c,
      width: c ? c.width : 0,
      height: c ? c.height : 0,
      rect: rect ? { left: rect.left, top: rect.top, width: rect.width, height: rect.height } : null,
      viewport: { width: window.innerWidth, height: window.innerHeight },
      scroll: {
        width: document.documentElement.scrollWidth,
        height: document.documentElement.scrollHeight,
        clientWidth: document.documentElement.clientWidth,
        clientHeight: document.documentElement.clientHeight
      },
      bodyText: document.body.innerText.slice(0, 200),
      launchStillVisible: !!document.getElementById('runButton')
    };
  })()`);
  if (observed.canvas) break;
  await sleep(500);
}

if (!observed || !observed.canvas) {
  throw new Error('Canvas did not appear. Last state: ' + JSON.stringify(observed));
}
if (observed.launchStillVisible || observed.bodyText.includes('Launch')) {
  throw new Error('Launcher UI still overlaps the game canvas: ' + JSON.stringify(observed));
}
if (observed.width < 900 || observed.height < 500) {
  throw new Error('Canvas is not the expected engine viewport size: ' + JSON.stringify(observed));
}
if (observed.scroll.width > observed.scroll.clientWidth + 1 || observed.scroll.height > observed.scroll.clientHeight + 1) {
  throw new Error('Game canvas causes document scroll overflow: ' + JSON.stringify(observed));
}
if (!observed.rect || observed.rect.left < -1 || observed.rect.top < -1 || observed.rect.left + observed.rect.width > observed.viewport.width + 1 || observed.rect.top + observed.rect.height > observed.viewport.height + 1) {
  throw new Error('Game canvas is not fitted inside the viewport: ' + JSON.stringify(observed));
}

await sleep(1500);
const pageTargets = (await getJson('/json/list')).filter(item => item.type === 'page');
if (pageTargets.length !== 1) {
  throw new Error('A popup or extra page target was opened: ' + JSON.stringify(pageTargets.map(item => ({ title: item.title, url: item.url }))));
}

const pixels = await evaluate(`(() => {
  const c = document.querySelector('canvas');
  const ctx = c.getContext('2d');
  const data = ctx.getImageData(0, 0, c.width, c.height).data;
  let nonblank = 0, red = 0, green = 0, blue = 0, bright = 0, transitions = 0;
  let last = -1;
  for (let i = 0; i < data.length; i += 128) {
    const r = data[i], g = data[i + 1], b = data[i + 2], a = data[i + 3];
    const bucket = (r >> 4) * 256 + (g >> 4) * 16 + (b >> 4);
    if (a && (r || g || b)) nonblank++;
    if (r > g * 1.25 && r > b * 1.25) red++;
    if (g > r * 1.15 && g > b * 1.05) green++;
    if (b > r * 1.15 && b > g * 1.05) blue++;
    if (r + g + b > 145) bright++;
    if (last !== -1 && bucket !== last) transitions++;
    last = bucket;
  }
  return { width: c.width, height: c.height, nonblank, red, green, blue, bright, transitions, samples: Math.floor(data.length / 128) };
})()`);

if (pixels.nonblank < pixels.samples * 0.90) throw new Error('Canvas appears blank: ' + JSON.stringify(pixels));
if (pixels.transitions < 900) throw new Error('Frame entropy is too low for projected engine scene: ' + JSON.stringify(pixels));
if (pixels.red < 20 || pixels.green < 8 || pixels.blue < 8) throw new Error('Expected colored industrial/emissive detail is missing: ' + JSON.stringify(pixels));

const realBadResponses = badResponses.filter(item => !item.url.endsWith('/favicon.ico'));
if (realBadResponses.length !== 0) {
  throw new Error('Unexpected failed network responses: ' + JSON.stringify(realBadResponses));
}
const meaningfulErrors = errors.filter(text => !String(text).includes('Failed to load resource'));
if (meaningfulErrors.length !== 0) {
  throw new Error('Browser runtime errors: ' + meaningfulErrors.join(' | '));
}

if (screenshotPath) {
  const screenshot = await send('Page.captureScreenshot', { format: 'png', fromSurface: true });
  mkdirSync(dirname(screenshotPath), { recursive: true });
  writeFileSync(screenshotPath, Buffer.from(screenshot.data, 'base64'));
}

console.log(JSON.stringify({ before, observed, pixels, badResponses, screenshotPath }, null, 2));
ws.close();
'@

Set-Content -LiteralPath $scriptPath -Value $script -Encoding UTF8
$chromeProc = Start-Process -FilePath $browser -ArgumentList @(
  "--headless=new",
  "--disable-gpu",
  "--disable-extensions",
  "--no-first-run",
  "--no-default-browser-check",
  "--remote-debugging-port=$Port",
  "--user-data-dir=$userData",
  "about:blank"
) -PassThru -WindowStyle Hidden

try {
  $env:SMOKE_URL = $smokeUrl
  $env:CDP_PORT = [string]$Port
  if ($ScreenshotPath) {
    $env:SCREENSHOT_PATH = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ScreenshotPath)
  } else {
    $env:SCREENSHOT_PATH = ""
  }
  node $scriptPath
  if ($LASTEXITCODE -ne 0) {
    throw "Browser visual smoke failed with exit code $LASTEXITCODE"
  }
}
finally {
  if ($chromeProc -and -not $chromeProc.HasExited) {
    Stop-Process -Id $chromeProc.Id -Force
  }
  if (Test-Path -LiteralPath $scriptPath) {
    Remove-Item -LiteralPath $scriptPath -Force
  }
  if (Test-Path -LiteralPath $userData) {
    Remove-Item -LiteralPath $userData -Recurse -Force -ErrorAction SilentlyContinue
  }
}
