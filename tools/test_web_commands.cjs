const path = require('path');
const puppeteer = require(path.resolve(__dirname, '..', '..', 'game-x0-moba', 'jogo', 'node_modules', 'puppeteer'));

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

(async () => {
  console.log('[TEST-COMMANDS] Launching Chrome to test web commands and hotkeys...');
  const browser = await puppeteer.launch({
    headless: false,
    executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    defaultViewport: { width: 1280, height: 720, deviceScaleFactor: 1 },
    args: [
      '--window-size=1296,860',
      '--ignore-gpu-blocklist',
      '--enable-gpu-rasterization',
      '--autoplay-policy=no-user-gesture-required'
    ]
  });

  const page = await browser.newPage();
  await page.goto('http://localhost:8080/', { waitUntil: 'load', timeout: 60000 });
  await page.waitForFunction(() => window._gamex1_ready === true, { timeout: 60000 });
  await sleep(1000);

  let passed = 0;
  let failed = 0;

  function assert(condition, testName) {
    if (condition) {
      console.log(`  ✓ PASS: ${testName}`);
      passed++;
    } else {
      console.error(`  ✗ FAIL: ${testName}`);
      failed++;
    }
  }

  // Helper to read current flags
  async function getState() {
    return await page.evaluate(() => {
      return {
        aa_mode: window._gamex1_aa_mode,
        shadows: window._gamex1_shadows,
        cmd_fxaa: window._cmd_set_fxaa,
        cmd_msaa: window._cmd_set_msaa,
        cmd_shadows: window._cmd_set_shadows
      };
    });
  }

  console.log('\n--- 1. Testing Individual Commands ---');

  // 1. Turn FXAA OFF
  await page.evaluate(() => { window._cmd_set_fxaa = 0; });
  await sleep(650); // allow 50ms poll + 500ms telemetry update
  let s = await getState();
  assert(s.aa_mode === 'OFF' && s.cmd_fxaa === undefined, 'window._cmd_set_fxaa = 0 turns FXAA OFF and deletes command');

  // 2. Turn FXAA ON
  await page.evaluate(() => { window._cmd_set_fxaa = 1; });
  await sleep(650);
  s = await getState();
  assert(s.aa_mode === 'FXAA-3D' && s.cmd_fxaa === undefined, 'window._cmd_set_fxaa = 1 turns FXAA ON and deletes command');

  // 3. Turn MSAA ON (2X)
  await page.evaluate(() => { window._cmd_set_msaa = 1; });
  await sleep(650);
  s = await getState();
  assert(s.aa_mode === 'MSAA-2X' && s.cmd_msaa === undefined, 'window._cmd_set_msaa = 1 sets MSAA-2X and deletes command');

  // 4. Turn MSAA OFF
  await page.evaluate(() => { window._cmd_set_msaa = 0; });
  await sleep(650);
  s = await getState();
  assert((s.aa_mode === 'OFF' || s.aa_mode === 'FXAA-3D') && s.cmd_msaa === undefined, 'window._cmd_set_msaa = 0 disables MSAA and deletes command');

  // 5. Turn Shadows OFF
  await page.evaluate(() => { window._cmd_set_shadows = 0; });
  await sleep(650);
  s = await getState();
  assert(s.shadows === 0 && s.cmd_shadows === undefined, 'window._cmd_set_shadows = 0 turns shadows OFF and deletes command');

  // 6. Turn Shadows ON
  await page.evaluate(() => { window._cmd_set_shadows = 1; });
  await sleep(650);
  s = await getState();
  assert(s.shadows === 1 && s.cmd_shadows === undefined, 'window._cmd_set_shadows = 1 turns shadows ON and deletes command');

  console.log('\n--- 2. Testing Simultaneous & Repeated Commands ---');

  // 7. Simultaneous commands: FXAA=0, Shadows=0
  await page.evaluate(() => {
    window._cmd_set_fxaa = 0;
    window._cmd_set_shadows = 0;
  });
  await sleep(650);
  s = await getState();
  assert(s.aa_mode === 'OFF' && s.shadows === 0 && s.cmd_fxaa === undefined && s.cmd_shadows === undefined,
    'Simultaneous FXAA=0 and Shadows=0 applied atomically');

  // 8. Repeated identical commands (no-op)
  await page.evaluate(() => { window._cmd_set_shadows = 0; });
  await sleep(650);
  s = await getState();
  assert(s.shadows === 0 && s.cmd_shadows === undefined, 'Repeated window._cmd_set_shadows = 0 consumed cleanly');

  // Reset to FXAA=1, Shadows=1
  await page.evaluate(() => {
    window._cmd_set_fxaa = 1;
    window._cmd_set_shadows = 1;
  });
  await sleep(650);

  console.log('\n--- 3. Testing Hotkeys F1, F2, F4 ---');

  // 9. F1 toggles shadows
  await page.keyboard.press('F1');
  await sleep(650);
  s = await getState();
  assert(s.shadows === 0, 'F1 key toggles shadows OFF');

  await page.keyboard.press('F1');
  await sleep(650);
  s = await getState();
  assert(s.shadows === 1, 'F1 key toggles shadows ON back');

  // 10. F4 toggles FXAA
  await page.keyboard.press('F4');
  await sleep(650);
  s = await getState();
  assert(s.aa_mode === 'OFF', 'F4 key toggles FXAA OFF');

  await page.keyboard.press('F4');
  await sleep(650);
  s = await getState();
  assert(s.aa_mode === 'FXAA-3D', 'F4 key toggles FXAA ON back');

  // 11. F2 toggles MSAA
  await page.keyboard.press('F2');
  await sleep(650);
  s = await getState();
  assert(s.aa_mode === 'MSAA-2X', 'F2 key toggles MSAA-2X ON');

  await page.keyboard.press('F2');
  await sleep(650);
  s = await getState();
  assert(s.aa_mode !== 'MSAA-2X', 'F2 key toggles MSAA-2X OFF back');

  await browser.close();

  console.log(`\n[TEST-COMMANDS] Results: ${passed} Passed, ${failed} Failed`);
  process.exit(failed > 0 ? 1 : 0);
})().catch(err => {
  console.error('[TEST-COMMANDS] Error:', err);
  process.exit(1);
});
