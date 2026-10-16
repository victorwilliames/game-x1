const path = require('path');
const fs = require('fs');
const puppeteer = require(path.resolve(__dirname, '..', '..', 'game-x0-moba', 'jogo', 'node_modules', 'puppeteer'));

const OUT_FILE = path.join(__dirname, '..', 'docs', 'migration', 'visual', 'fxaa_cost_web.json');

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

(async () => {
  console.log('[FXAA-WEB-BENCH] Launching Chrome for web FXAA cost diagnostic benchmark...');
  const browser = await puppeteer.launch({
    headless: false,
    executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    defaultViewport: { width: 1280, height: 720, deviceScaleFactor: 1 },
    protocolTimeout: 1200000, // 20 minutes to prevent CDP timeout
    args: [
      '--window-size=1296,860',
      '--ignore-gpu-blocklist',
      '--enable-gpu-rasterization',
      '--autoplay-policy=no-user-gesture-required',
      '--disable-background-timer-throttling',
      '--disable-backgrounding-occluded-windows',
      '--disable-renderer-backgrounding',
      '--disable-frame-rate-limit',
      '--disable-gpu-vsync'
    ]
  });

  const page = await browser.newPage();
  
  // Forward browser console logs to Node stdout to see benchmark progress
  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('[PerfBench]') || text.includes('[game-x1]')) {
      console.log(`[BROWSER] ${text}`);
    }
  });

  const url = 'http://localhost:8080/?bench=1&runs=3&sec=12&warmup=6&configs=full,pass_only,no_fxaa';
  console.log(`[FXAA-WEB-BENCH] Navigating to: ${url}`);
  await page.goto(url, { waitUntil: 'load', timeout: 120000 });

  console.log('[FXAA-WEB-BENCH] Waiting for benchmark to start and complete...');
  
  // Poll periodically with try/catch to avoid any single-call hang
  let result = null;
  const startTime = Date.now();
  const maxWaitMs = 1200000; // 20 minutes

  while (Date.now() - startTime < maxWaitMs) {
    await sleep(5000);
    try {
      const res = await page.evaluate(() => {
        if (typeof window._gamex1_bench_result === 'string') {
          return window._gamex1_bench_result;
        }
        return null;
      });
      if (res) {
        result = res;
        break;
      }
    } catch (err) {
      console.log('[FXAA-WEB-BENCH] Poll error (ignored):', err.message);
    }
  }

  if (!result) {
    throw new Error('Benchmark timed out after 20 minutes without setting window._gamex1_bench_result');
  }

  let parsed;
  try {
    parsed = JSON.parse(result);
  } catch (e) {
    parsed = result;
  }

  fs.writeFileSync(OUT_FILE, typeof parsed === 'string' ? parsed : JSON.stringify(parsed, null, 2), 'utf-8');
  console.log(`[FXAA-WEB-BENCH] Results saved to ${OUT_FILE}`);

  await browser.close();
  console.log('[FXAA-WEB-BENCH] Finished successfully!');
  process.exit(0);
})().catch((err) => {
  console.error('[FXAA-WEB-BENCH] Error:', err);
  process.exit(1);
});
