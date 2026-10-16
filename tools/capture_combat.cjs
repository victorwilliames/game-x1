const path = require('path');
const puppeteer = require(path.resolve(__dirname, '..', '..', 'game-x0-moba', 'jogo', 'node_modules', 'puppeteer'));

const OUT_DIR = path.join(__dirname, '..', 'docs', 'migration', 'visual');

async function captureCombat(url, isGodot) {
  const browser = await puppeteer.launch({
    headless: false,
    executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    defaultViewport: { width: 1280, height: 720, deviceScaleFactor: 1 },
    args: [
      '--window-size=1296,860',
      '--ignore-gpu-blocklist',
      '--enable-gpu-rasterization',
      '--disable-frame-rate-limit',
      '--disable-gpu-vsync',
    ]
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

  // Hover over Dummy (Estático) at (745, 435)
  await page.mouse.move(745, 435);
  await new Promise(r => setTimeout(r, 800));

  // Press KeyX repeatedly to fire Hextech projectiles at Dummy (Estático) and spawn floating damage numbers
  for (let i = 0; i < 5; i++) {
    await page.keyboard.press('KeyX');
    await new Promise(r => setTimeout(r, 280));
  }

  // Wait 120ms after the 5th shot so projectile hit + floating damage numbers are mid-air
  await new Promise(r => setTimeout(r, 120));
  const outPath = path.join(OUT_DIR, isGodot ? 'combat_godot.png' : 'combat_three.png');
  await page.screenshot({ path: outPath });
  console.log('Saved combat capture:', outPath);
  await browser.close();
}

(async () => {
  await captureCombat('http://localhost:3005/', false);
  await captureCombat('http://localhost:8080/', true);
})();
