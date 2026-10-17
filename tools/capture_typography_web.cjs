const path = require('path');
const puppeteer = require(path.resolve(__dirname, '..', '..', 'game-x0-moba', 'jogo', 'node_modules', 'puppeteer'));

const OUT_DIR = path.join(__dirname, '..', 'docs', 'migration', 'visual');

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

(async () => {
  console.log('[TYPO-WEB] Launching Chrome to capture typography validation in WebGL...');
  const browser = await puppeteer.launch({
    headless: false,
    executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    defaultViewport: { width: 1280, height: 720, deviceScaleFactor: 1 },
    protocolTimeout: 300000,
    args: [
      '--window-size=1296,860',
      '--ignore-gpu-blocklist',
      '--enable-gpu-rasterization',
      '--autoplay-policy=no-user-gesture-required'
    ]
  });

  const page = await browser.newPage();
  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('[game-x1]') || text.includes('ready')) {
      console.log(`[PAGE] ${text}`);
    }
  });

  console.log('[TYPO-WEB] Navigating to http://localhost:8080/ ...');
  await page.goto('http://localhost:8080/', { waitUntil: 'load', timeout: 180000 });
  
  console.log('[TYPO-WEB] Waiting for window._gamex1_ready === true ...');
  await page.waitForFunction(() => window._gamex1_ready === true, { timeout: 180000 });
  console.log('[TYPO-WEB] Game is ready!');
  await sleep(2000);

  // Center cursor
  await page.mouse.move(640, 360);
  await sleep(500);

  // 1. Capture Idle
  await page.screenshot({ path: path.join(OUT_DIR, 'typography_9px_after_web_idle.png') });
  console.log('[TYPO-WEB] Saved typography_9px_after_web_idle.png');

  // 2. Move hero
  await page.mouse.click(750, 480, { button: 'right' });
  await sleep(400); // in mid movement at 16 m/s
  await page.screenshot({ path: path.join(OUT_DIR, 'typography_9px_after_web_moving.png') });
  console.log('[TYPO-WEB] Saved typography_9px_after_web_moving.png');

  // 3. Camera pan
  await page.keyboard.press('KeyY'); // unlock camera
  await sleep(150);
  await page.mouse.move(640, 360);
  await page.mouse.down({ button: 'middle' });
  await page.mouse.move(780, 430, { steps: 5 });
  await page.mouse.up({ button: 'middle' });
  await sleep(300);
  await page.screenshot({ path: path.join(OUT_DIR, 'typography_9px_after_web_camera.png') });
  console.log('[TYPO-WEB] Saved typography_9px_after_web_camera.png');

  await browser.close();
  console.log('[TYPO-WEB] Web capture finished successfully!');
  process.exit(0);
})().catch(err => {
  console.error('[TYPO-WEB] Error:', err);
  process.exit(1);
});
