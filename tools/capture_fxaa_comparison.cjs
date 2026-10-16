const path = require('path');
const puppeteer = require(path.resolve(__dirname, '..', '..', 'game-x0-moba', 'jogo', 'node_modules', 'puppeteer'));

const OUT_DIR = path.join(__dirname, '..', 'docs', 'migration', 'visual');

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

(async () => {
  console.log('[CAPTURE] Launching Chrome to capture full, pass_only, and no_fxaa screenshots...');
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
  await sleep(1500);

  // Center cursor
  await page.mouse.move(640, 360);
  await sleep(500);

  // 1. Capture FULL (production FXAA)
  await page.evaluate(() => { window._cmd_set_fxaa = 1; });
  await sleep(800);
  await page.screenshot({ path: path.join(OUT_DIR, 'mode_full.png') });
  console.log('[CAPTURE] Saved mode_full.png');

  // 2. Capture NO_FXAA
  await page.evaluate(() => { window._cmd_set_fxaa = 0; });
  await sleep(800);
  await page.screenshot({ path: path.join(OUT_DIR, 'mode_no_fxaa.png') });
  console.log('[CAPTURE] Saved mode_no_fxaa.png');

  await browser.close();
  console.log('[CAPTURE] Done capturing baseline modes!');
})().catch(err => {
  console.error('[CAPTURE] Error:', err);
  process.exit(1);
});
