// Diagnostic only: full-scene AA coverage test. MSAA affects geometry edges,
// not grid/shader aliasing. Production keeps custom fullscreen FXAA.
const fs = require('fs');
const path = require('path');
let puppeteer;
try {
  puppeteer = require(path.resolve(__dirname, '..', '..', 'game-x0-moba', 'jogo', 'node_modules', 'puppeteer'));
} catch (_) {
  puppeteer = require('puppeteer');
}
const modes = ['full', 'msaa2x', 'msaa4x', 'no_fxaa'];
const scenarios = ['idle', 'movement', 'kiting', 'combat', 'camera'];
const runs = 3;
const outFile = path.resolve(__dirname, '..', 'docs', 'migration', 'visual', 'aa_fullscreen_web.json');
const wait = ms => new Promise(r => setTimeout(r, ms));

async function main() {
  const browser = await puppeteer.launch({
    headless: false,
    executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    defaultViewport: { width: 1280, height: 720, deviceScaleFactor: 1 },
    protocolTimeout: 1200000,
    args: [
      '--window-size=1296,860', '--ignore-gpu-blocklist',
      '--enable-gpu-rasterization', '--autoplay-policy=no-user-gesture-required',
      '--disable-background-timer-throttling', '--disable-backgrounding-occluded-windows',
      '--disable-renderer-backgrounding', '--disable-frame-rate-limit', '--disable-gpu-vsync'
    ]
  });
  try {
    const page = await browser.newPage();
    page.on('console', msg => {
      const line = msg.text();
      if (line.includes('[PerfBench]') || line.includes('[game-x1]')) console.log(line);
    });
    const url = 'http://localhost:8080/?bench=1&runs=3&sec=12&warmup=6&configs=' + modes.join(',');
    console.log('[AA-WEB] Starting full-scene AA comparison: ' + url);
    await page.goto(url, { waitUntil: 'load', timeout: 120000 });
    let raw = null;
    const start = Date.now();
    while (Date.now() - start < 1200000) {
      await wait(5000);
      try {
        raw = await page.evaluate(() => typeof window._gamex1_bench_result === 'string'
          ? window._gamex1_bench_result : null);
      } catch (err) {
        console.log('[AA-WEB] Transient read problem: ' + err.message);
      }
      if (raw) break;
    }
    if (!raw) throw new Error('Benchmark timed out without a complete payload');
    const result = JSON.parse(raw);
    const expected = modes.length * scenarios.length * runs;
    if (!result || !result.info || !result.info.web || !Array.isArray(result.results) || result.results.length !== expected)
      throw new Error('Invalid record count/platform: expected ' + expected + ' Web measurements');
    const configList = result.info.configs || [];
    if (modes.some(mode => !configList.includes(mode)) || configList.length !== modes.length)
      throw new Error('Mode list mismatch');
    const seen = new Set();
    for (const record of result.results) {
      if (!modes.includes(record.config) || !scenarios.includes(record.scenario) ||
          !Number.isInteger(record.run) || record.run < 0 || record.run >= runs ||
          !Number.isFinite(record.frame_ms_mean) || record.frame_ms_mean <= 0)
        throw new Error('Invalid record: ' + JSON.stringify(record));
      const key = record.config + '/' + record.scenario + '/' + record.run;
      if (seen.has(key)) throw new Error('Duplicate record: ' + key);
      seen.add(key);
    }
    fs.mkdirSync(path.dirname(outFile), { recursive: true });
    fs.writeFileSync(outFile, JSON.stringify(result, null, 2), 'utf8');
    console.log('[AA-WEB] Validated ' + expected + ' measurements: ' + outFile);
  } finally {
    await browser.close();
  }
}
main().catch(e => { console.error('[AA-WEB] Failed:', e); process.exitCode = 1; });
