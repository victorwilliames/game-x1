// Visual parity capture harness (game-x0 Three.js vs game-x1 Godot Web).
// Captures REAL screenshots of the running games under normalized conditions:
//   - same CSS viewport (default 1280x720, deviceScaleFactor 1)
//   - character untouched at spawn (0,0,0), camera in default Locked mode
//   - cursor placed at the exact viewport center (zero cursor-offset in Locked mode)
//   - no clicks (avoids pointer lock / fullscreen requests in game-x0)
//
// Usage:
//   node tools/visual_capture.cjs --kind three --url http://localhost:3005/ --out shots/A_three.png
//   node tools/visual_capture.cjs --kind godot --url http://localhost:8080/ --out shots/B_godot.png
//
// Puppeteer is resolved from the read-only reference project (game-x0-moba/jogo/node_modules)
// unless PUPPETEER_PATH is set. Nothing is written into the reference project.

const path = require('path');
const fs = require('fs');

const args = {};
for (let i = 2; i < process.argv.length; i += 2) {
  args[process.argv[i].replace(/^--/, '')] = process.argv[i + 1];
}

const kind = args.kind || 'godot';
const url = args.url || (kind === 'three' ? 'http://localhost:3005/' : 'http://localhost:8080/');
const out = path.resolve(args.out || `shots/${kind}.png`);
const width = parseInt(args.width || '1280', 10);
const height = parseInt(args.height || '720', 10);
const settleMs = parseInt(args.settle || '3000', 10);
const headless = args.headless === 'true';

const puppeteerPath = process.env.PUPPETEER_PATH ||
  'C:/.PROJETOS - Sites 2026/godot/game-x0-moba/jogo/node_modules/puppeteer';
const puppeteer = require(puppeteerPath);

(async () => {
  fs.mkdirSync(path.dirname(out), { recursive: true });
  const browser = await puppeteer.launch({
    headless: headless ? 'new' : false,
    executablePath: args.chrome || process.env.CHROME_PATH ||
      'C:/Program Files/Google/Chrome/Application/chrome.exe',
    defaultViewport: { width, height, deviceScaleFactor: 1 },
    args: [
      `--window-size=${width + 16},${height + 140}`,
      '--ignore-gpu-blocklist',
      '--enable-gpu-rasterization',
      '--autoplay-policy=no-user-gesture-required',
      '--disable-frame-rate-limit',
      '--disable-gpu-vsync',
      '--disable-background-timer-throttling',
      '--disable-backgrounding-occluded-windows',
      '--disable-renderer-backgrounding',
    ],
  });
  const page = await browser.newPage();
  page.on('console', (m) => {
    const t = m.text();
    if (/error|fail|game-x1/i.test(t)) console.log(`[page:${kind}] ${t}`);
  });

  await page.goto(url, { waitUntil: 'load', timeout: 120000 });

  if (kind === 'three') {
    await page.waitForFunction(
      () => (document.getElementById('loading-status') || {}).innerText === 'Pronto!',
      { timeout: 120000 }
    );
  } else if (args.fixedwait) {
    await new Promise((r) => setTimeout(r, parseInt(args.fixedwait, 10)));
  } else {
    // main.gd sets window._gamex1_ready = true once the scene is ready.
    await page.waitForFunction(() => window._gamex1_ready === true, { timeout: 180000 });
  }

  // Normalize cursor: exact viewport center => zero Locked-mode camera offset in both games.
  await page.mouse.move(width / 2, height / 2);
  await new Promise((r) => setTimeout(r, 300));
  await page.mouse.move(width / 2 + 1, height / 2);
  await page.mouse.move(width / 2, height / 2);
  await new Promise((r) => setTimeout(r, settleMs));

  const info = await page.evaluate(async () => {
    // Sample 6 animation frames for frame timing
    const deltas = [];
    let lastT = performance.now();
    for (let i = 0; i < 6; i++) {
      await new Promise((r) => requestAnimationFrame((t) => {
        deltas.push(t - lastT);
        lastT = t;
        r();
      }));
    }
    const avgDelta = deltas.reduce((a, b) => a + b, 0) / deltas.length;
    const measuredFps = Math.round(1000 / avgDelta);

    return {
      innerWidth: window.innerWidth,
      innerHeight: window.innerHeight,
      dpr: window.devicePixelRatio,
      raf: window._gamex1_raf ? window._gamex1_raf.fps : null,
      engineFps: window._gamex1_engine_fps || null,
      engineFrameTimeMs: window._gamex1_frame_time_ms || null,
      measuredFps,
      avgDeltaMs: Number(avgDelta.toFixed(2)),
    };
  });
  console.log(`[capture:${kind}] viewport=${info.innerWidth}x${info.innerHeight} dpr=${info.dpr} raf=${info.raf} engineFps=${info.engineFps} avgFrameTime=${info.avgDeltaMs}ms measuredFps=${info.measuredFps}`);

  await page.screenshot({ path: out });
  console.log(`[capture:${kind}] saved ${out}`);
  await browser.close();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
