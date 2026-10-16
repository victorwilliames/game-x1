const path = require('path');
const puppeteer = require(path.resolve(__dirname, '..', '..', 'game-x0-moba', 'jogo', 'node_modules', 'puppeteer'));

async function measureRAF(page, durationMs) {
  return await page.evaluate((ms) => {
    return new Promise((resolve) => {
      const frameTimes = [];
      let last = performance.now();
      const start = last;
      function step(now) {
        const dt = now - last;
        last = now;
        if (dt > 0 && dt < 250) {
          frameTimes.push(dt);
        }
        if (now - start < ms) {
          requestAnimationFrame(step);
        } else {
          frameTimes.sort((a, b) => a - b);
          const sum = frameTimes.reduce((s, v) => s + v, 0);
          const avgMs = frameTimes.length ? sum / frameTimes.length : 16.67;
          const p95Ms = frameTimes.length ? frameTimes[Math.floor(frameTimes.length * 0.95)] : avgMs;
          const p99Ms = frameTimes.length ? frameTimes[Math.floor(frameTimes.length * 0.99)] : avgMs;
          const avgFps = 1000 / avgMs;
          const low1Fps = 1000 / p99Ms;
          resolve({
            samples: frameTimes.length,
            avgMs: Number(avgMs.toFixed(2)),
            p95Ms: Number(p95Ms.toFixed(2)),
            p99Ms: Number(p99Ms.toFixed(2)),
            avgFps: Math.round(avgFps),
            low1Fps: Math.round(low1Fps)
          });
        }
      }
      requestAnimationFrame((t) => {
        last = t;
        requestAnimationFrame(step);
      });
    });
  }, durationMs);
}

async function runGodot(uncapped) {
  const args = [
    '--window-size=1296,860',
    '--ignore-gpu-blocklist',
    '--enable-gpu-rasterization',
    '--autoplay-policy=no-user-gesture-required',
    '--disable-background-timer-throttling',
    '--disable-backgrounding-occluded-windows',
    '--disable-renderer-backgrounding',
  ];
  if (uncapped) {
    args.push('--disable-frame-rate-limit', '--disable-gpu-vsync');
  }

  const browser = await puppeteer.launch({
    headless: false,
    executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    defaultViewport: { width: 1280, height: 720, deviceScaleFactor: 1 },
    args
  });

  const page = await browser.newPage();
  await page.goto('http://localhost:8080/', { waitUntil: 'load', timeout: 120000 });
  await page.waitForFunction(() => window._gamex1_ready === true, { timeout: 180000 });

  await page.mouse.move(640, 360);
  await new Promise(r => setTimeout(r, 2000));

  const results = {};
  results.idle = await measureRAF(page, 2000);

  // Movement
  const moveWaypoints = [[520, 340], [720, 260], [560, 420], [640, 300], [580, 320]];
  let moveIdx = 0;
  const moveTimer = setInterval(async () => {
    const [x, y] = moveWaypoints[moveIdx % moveWaypoints.length];
    moveIdx++;
    try { await page.mouse.click(x, y, { button: 'right' }); } catch (_) {}
  }, 420);
  results.movement = await measureRAF(page, 2000);
  clearInterval(moveTimer);

  // Return near spawn
  await page.mouse.click(610, 320, { button: 'right' });
  await new Promise(r => setTimeout(r, 600));

  // Damage
  await page.mouse.move(680, 405);
  await page.mouse.click(680, 405, { button: 'right' });
  const dmgTimer = setInterval(async () => {
    try {
      await page.mouse.move(680, 405);
      await page.keyboard.press('KeyA');
    } catch (_) {}
  }, 260);
  await new Promise(r => setTimeout(r, 600));
  results.damage = await measureRAF(page, 2000);
  clearInterval(dmgTimer);

  await browser.close();
  return results;
}

(async () => {
  const label = process.argv[2] || 'Benchmark';
  console.log(`[TEST: ${label}] Starting Godot measurement...`);
  const uncapped = await runGodot(true);
  const vsync = await runGodot(false);
  console.log(`[RESULT: ${label}]`);
  console.log(JSON.stringify({ label, uncapped, vsync }, null, 2));
})().catch(err => {
  console.error(err);
  process.exit(1);
});
