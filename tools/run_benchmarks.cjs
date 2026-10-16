const path = require('path');
const fs = require('fs');
const puppeteer = require(path.resolve(__dirname, '..', '..', 'game-x0-moba', 'jogo', 'node_modules', 'puppeteer'));

const OUT_DIR = path.join(__dirname, '..', 'docs', 'migration', 'visual');

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

async function runSuite(url, name, isGodot, uncapped) {
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
  await page.goto(url, { waitUntil: 'load', timeout: 120000 });

  if (!isGodot) {
    await page.waitForFunction(
      () => (document.getElementById('loading-status') || {}).innerText === 'Pronto!',
      { timeout: 120000 }
    );
  } else {
    await page.waitForFunction(() => window._gamex1_ready === true, { timeout: 180000 });
  }

  // Normalize cursor at center
  await page.mouse.move(640, 360);
  await new Promise(r => setTimeout(r, 300));
  await page.mouse.move(641, 360);
  await page.mouse.move(640, 360);
  await new Promise(r => setTimeout(r, 2500));

  // If this is the uncapped pass, capture the clean idle baseline screenshot first
  if (uncapped) {
    const idlePath = path.join(OUT_DIR, isGodot ? 'B_godot_corrected.png' : 'A_three_baseline.png');
    await page.screenshot({ path: idlePath });
  }

  const results = {};

  // 1. Cena parada (Idle)
  results.idle = await measureRAF(page, 2200);

  // 2. Movimento contínuo (Continuous movement around the center)
  const moveWaypoints = [
    [520, 340], [720, 260], [560, 420], [640, 300], [580, 320]
  ];
  let moveIdx = 0;
  const moveTimer = setInterval(async () => {
    const [x, y] = moveWaypoints[moveIdx % moveWaypoints.length];
    moveIdx++;
    try {
      await page.mouse.click(x, y, { button: 'right' });
    } catch (_) {}
  }, 420);
  results.movement = await measureRAF(page, 2200);
  clearInterval(moveTimer);

  // Return near spawn for attack/kiting
  await page.mouse.click(610, 320, { button: 'right' });
  await new Promise(r => setTimeout(r, 800));

  // 3. Ataque e kiting (Alternating A-click on Dummy at ~[680, 405] and RMB step)
  let kiteStep = 0;
  const kiteTimer = setInterval(async () => {
    try {
      if (kiteStep % 2 === 0) {
        await page.mouse.move(680, 405);
        await page.keyboard.press('KeyA');
      } else {
        await page.mouse.click(605 + (kiteStep % 3) * 15, 325, { button: 'right' });
      }
      kiteStep++;
    } catch (_) {}
  }, 240);
  results.kiting = await measureRAF(page, 2200);
  clearInterval(kiteTimer);

  // 4. Dummies recebendo dano (Sustained rapid fire on Dummy + combat screenshot)
  await page.mouse.move(680, 405);
  await page.mouse.click(680, 405, { button: 'right' });
  const dmgTimer = setInterval(async () => {
    try {
      await page.mouse.move(680, 405);
      await page.keyboard.press('KeyA');
    } catch (_) {}
  }, 260);

  // Wait 900ms into sustained attack to capture floating damage numbers in action
  await new Promise(r => setTimeout(r, 900));
  if (uncapped) {
    const combatPath = path.join(OUT_DIR, isGodot ? 'combat_godot.png' : 'combat_three.png');
    await page.screenshot({ path: combatPath });
  }
  results.damage = await measureRAF(page, 2200);
  clearInterval(dmgTimer);

  // 5. Câmera em movimento (Unlock camera with Y and pan via MMB drag)
  await page.keyboard.press('KeyY');
  await new Promise(r => setTimeout(r, 150));
  let camStep = 0;
  const camTimer = setInterval(async () => {
    try {
      const dir = camStep % 2 === 0 ? 1 : -1;
      await page.mouse.move(640, 360);
      await page.mouse.down({ button: 'middle' });
      await page.mouse.move(640 + dir * 120, 360 + dir * 60, { steps: 5 });
      await page.mouse.up({ button: 'middle' });
      camStep++;
    } catch (_) {}
  }, 450);
  results.camera = await measureRAF(page, 2200);
  clearInterval(camTimer);

  await browser.close();
  return results;
}

(async () => {
  console.log('Running Uncapped GPU Headroom Benchmarks (--disable-gpu-vsync)...');
  const threeUncapped = await runSuite('http://localhost:3005/', 'Three.js (Uncapped)', false, true);
  const godotUncapped = await runSuite('http://localhost:8080/', 'Godot 4 (Uncapped)', true, true);

  console.log('Running Standard Browser V-Sync Benchmarks (Default Chrome flags)...');
  const threeVsync = await runSuite('http://localhost:3005/', 'Three.js (V-Sync)', false, false);
  const godotVsync = await runSuite('http://localhost:8080/', 'Godot 4 (V-Sync)', true, false);

  const summary = {
    timestamp: new Date().toISOString(),
    viewport: '1280x720 (deviceScaleFactor=1)',
    uncapped: {
      threejs: threeUncapped,
      godot4: godotUncapped
    },
    standardVsync: {
      threejs: threeVsync,
      godot4: godotVsync
    }
  };

  fs.writeFileSync(path.join(OUT_DIR, 'multi_scenario_benchmark.json'), JSON.stringify(summary, null, 2));
  console.log('BENCHMARK COMPLETE:', JSON.stringify(summary, null, 2));
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
