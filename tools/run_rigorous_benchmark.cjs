const path = require('path');
const fs = require('fs');
const puppeteer = require(path.resolve(__dirname, '..', '..', 'game-x0-moba', 'jogo', 'node_modules', 'puppeteer'));

const OUT_DIR = path.join(__dirname, '..', 'docs', 'migration', 'visual');

async function measureRAF(page, durationMs, warmupMs = 1200) {
  // First, warm up without collecting samples to avoid JIT/transition hitches
  if (warmupMs > 0) {
    await page.evaluate((wMs) => {
      return new Promise((resolve) => {
        const start = performance.now();
        function warmStep(now) {
          if (now - start < wMs) {
            requestAnimationFrame(warmStep);
          } else {
            resolve();
          }
        }
        requestAnimationFrame(warmStep);
      });
    }, warmupMs);
  }

  // Next, collect high-precision frame timing
  return await page.evaluate((ms) => {
    return new Promise((resolve) => {
      const frameTimes = [];
      let last = performance.now();
      const start = last;

      function step(now) {
        const dt = now - last;
        last = now;
        if (dt > 0 && dt < 500) {
          frameTimes.push(dt);
        }
        if (now - start < ms) {
          requestAnimationFrame(step);
        } else {
          frameTimes.sort((a, b) => a - b);
          const n = frameTimes.length;
          const sum = frameTimes.reduce((s, v) => s + v, 0);
          const meanMs = n ? sum / n : 16.67;
          const medianMs = n ? frameTimes[Math.floor(n * 0.5)] : meanMs;
          const p95Ms = n ? frameTimes[Math.floor(n * 0.95)] : meanMs;
          const p99Ms = n ? frameTimes[Math.floor(n * 0.99)] : meanMs;
          const minMs = n ? frameTimes[0] : meanMs;
          const maxMs = n ? frameTimes[n - 1] : meanMs;
          const avgFps = 1000 / meanMs;
          const low1Fps = 1000 / p99Ms;

          // Collect engine telemetry if Godot
          const engineFps = window._gamex1_engine_fps || 0;
          const engineMs = window._gamex1_frame_time_ms || 0;
          const aaMode = window._gamex1_aa_mode || 'N/A';
          const shadows = window._gamex1_shadows !== undefined ? window._gamex1_shadows : 1;
          const drawCalls = window._gamex1_draw_calls || 0;
          const primitives = window._gamex1_prims || 0;

          resolve({
            samples: n,
            meanMs: Number(meanMs.toFixed(2)),
            medianMs: Number(medianMs.toFixed(2)),
            p95Ms: Number(p95Ms.toFixed(2)),
            p99Ms: Number(p99Ms.toFixed(2)),
            minMs: Number(minMs.toFixed(2)),
            maxMs: Number(maxMs.toFixed(2)),
            avgFps: Math.round(avgFps),
            low1Fps: Math.round(low1Fps),
            engineFps,
            engineMs,
            aaMode,
            shadows,
            drawCalls,
            primitives
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

async function runSuite(url, name, isGodot, uncapped, godotConfig = null) {
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

  // Set Godot configuration if specified
  if (isGodot && godotConfig) {
    await page.evaluate((cfg) => {
      if (cfg.fxaa !== undefined) window._cmd_set_fxaa = cfg.fxaa ? 1 : 0;
      if (cfg.msaa !== undefined) window._cmd_set_msaa = cfg.msaa ? 1 : 0;
      if (cfg.shadows !== undefined) window._cmd_set_shadows = cfg.shadows ? 1 : 0;
    }, godotConfig);
    // Allow Godot 4 frames to consume the commands and stabilize
    await new Promise(r => setTimeout(r, 600));
  }

  // Normalize mouse position
  await page.mouse.move(640, 360);
  await new Promise(r => setTimeout(r, 300));
  await page.mouse.move(641, 360);
  await page.mouse.move(640, 360);
  await new Promise(r => setTimeout(r, 1500));

  // Capture baseline idle screenshot if uncapped
  if (uncapped) {
    let screenName = isGodot ? 'B_godot_corrected.png' : 'A_three_baseline.png';
    if (isGodot && godotConfig && godotConfig.label) {
      const modePath = path.join(OUT_DIR, `B_godot_${godotConfig.label}.png`);
      await page.screenshot({ path: modePath });
      if (godotConfig.label === 'fxaa3d') {
        await page.screenshot({ path: path.join(OUT_DIR, 'B_godot_corrected.png') });
      }
    } else {
      await page.screenshot({ path: path.join(OUT_DIR, screenName) });
    }
  }

  const results = {};

  // 1. Idle (parado)
  results.idle = await measureRAF(page, 3000, 1000);

  // 2. Movimento contínuo (Continuous movement around center)
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
  results.movement = await measureRAF(page, 3500, 1000);
  clearInterval(moveTimer);

  // Return near center
  await page.mouse.click(610, 320, { button: 'right' });
  await new Promise(r => setTimeout(r, 800));

  // 3. Ataque e kiting (alternating A-click and move)
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
  results.kiting = await measureRAF(page, 3500, 1000);
  clearInterval(kiteTimer);

  // 4. Combate sustentado com números de dano
  await page.mouse.move(680, 405);
  await page.mouse.click(680, 405, { button: 'right' });
  const dmgTimer = setInterval(async () => {
    try {
      await page.mouse.move(680, 405);
      await page.keyboard.press('KeyA');
    } catch (_) {}
  }, 260);

  await new Promise(r => setTimeout(r, 900));
  if (uncapped && (!godotConfig || godotConfig.label === 'fxaa3d')) {
    const combatPath = path.join(OUT_DIR, isGodot ? 'combat_godot.png' : 'combat_three.png');
    await page.screenshot({ path: combatPath });
  }
  results.damage = await measureRAF(page, 3500, 1000);
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
  results.camera = await measureRAF(page, 3500, 1000);
  clearInterval(camTimer);

  await browser.close();
  return results;
}

(async () => {
  console.log('=== STARTING RIGOROUS MULTI-SCENARIO BENCHMARKS ===');

  console.log('\n--- 1. Three.js Baseline (Uncapped) ---');
  const threeUncapped = await runSuite('http://localhost:3005/', 'Three.js (Uncapped)', false, true);

  console.log('\n--- 2. Godot 4: FXAA-3D ON (Uncapped) [Proposed Solution] ---');
  const godotFxaaUncapped = await runSuite('http://localhost:8080/', 'Godot 4 FXAA-3D', true, true, { fxaa: true, msaa: false, shadows: true, label: 'fxaa3d' });

  console.log('\n--- 3. Godot 4: AA OFF (Uncapped) [No Post-Process] ---');
  const godotOffUncapped = await runSuite('http://localhost:8080/', 'Godot 4 AA OFF', true, true, { fxaa: false, msaa: false, shadows: true, label: 'msaa0x' });

  console.log('\n--- 4. Godot 4: MSAA 2X (Uncapped) [Native FBO Resolve] ---');
  const godotMsaa2xUncapped = await runSuite('http://localhost:8080/', 'Godot 4 MSAA 2X', true, true, { fxaa: false, msaa: true, shadows: true, label: 'msaa2x' });

  console.log('\n--- 5. Godot 4: Shadows OFF (Uncapped) [Isolate Shadow Map Cost] ---');
  const godotNoShadowsUncapped = await runSuite('http://localhost:8080/', 'Godot 4 No Shadows', true, true, { fxaa: true, msaa: false, shadows: false, label: 'no_shadows' });

  console.log('\n--- 6. Standard Browser V-Sync Comparisons ---');
  const threeVsync = await runSuite('http://localhost:3005/', 'Three.js (V-Sync)', false, false);
  const godotFxaaVsync = await runSuite('http://localhost:8080/', 'Godot 4 FXAA-3D (V-Sync)', true, false, { fxaa: true, msaa: false, shadows: true, label: 'fxaa3d_vsync' });

  const summary = {
    timestamp: new Date().toISOString(),
    viewport: '1280x720 (deviceScaleFactor=1, DPR=1.0)',
    methodology: {
      warmupSec: 1.0,
      measureSec: 3.5,
      channels: ['Browser RAF delta-times (Mean, Median, P95, P99, Min, Max)', 'Engine Telemetry (FPS, FrameTime, DrawCalls, Prims)'],
      testedModes: ['Three.js WebGL', 'Godot 4 FXAA-3D', 'Godot 4 AA OFF', 'Godot 4 MSAA 2X', 'Godot 4 No Shadows']
    },
    uncapped: {
      threejs: threeUncapped,
      godot4_fxaa3d: godotFxaaUncapped,
      godot4_aa_off: godotOffUncapped,
      godot4_msaa2x: godotMsaa2xUncapped,
      godot4_no_shadows: godotNoShadowsUncapped
    },
    standardVsync: {
      threejs: threeVsync,
      godot4_fxaa3d: godotFxaaVsync
    }
  };

  fs.writeFileSync(path.join(OUT_DIR, 'multi_scenario_benchmark.json'), JSON.stringify(summary, null, 2));
  console.log('\n=== BENCHMARK SUITE COMPLETE ===');
  console.log(JSON.stringify(summary, null, 2));
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
