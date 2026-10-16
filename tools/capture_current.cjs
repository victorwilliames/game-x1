const path = require('path');
const puppeteer = require(path.resolve(__dirname, '..', '..', 'game-x0-moba', 'jogo', 'node_modules', 'puppeteer'));

(async () => {
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

  // Center cursor
  await page.mouse.move(640, 360);
  await new Promise(r => setTimeout(r, 2000));

  const outDir = path.join(__dirname, '..', 'docs', 'migration', 'visual');
  await page.screenshot({ path: path.join(outDir, 'B_godot_fxaa3d.png') });
  await page.screenshot({ path: path.join(outDir, 'B_godot_corrected.png') });

  console.log('Captured fresh Godot 4 screenshot with updated grid ribbons & FXAA!');
  await browser.close();
})().catch(console.error);
