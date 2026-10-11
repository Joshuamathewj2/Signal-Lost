const { chromium } = require('playwright');
const fs = require('fs');

async function runSoakTest() {
  console.log('--- Starting Step F Soak Test (Performance & Stability) ---');
  const browser = await chromium.launch({
    headless: true,
    channel: 'msedge',
    args: ['--enable-webgl', '--use-gl=angle']
  });
  const context = await browser.newContext({ viewport: { width: 1920, height: 1080 } });
  const page = await context.newPage();

  const errors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      errors.push(msg.text());
      console.error('[BROWSER ERROR]', msg.text());
    }
  });

  page.on('pageerror', err => {
    errors.push(err.message);
    console.error('[PAGE ERROR]', err.message);
  });

  fs.mkdirSync('qa/shots/soak', { recursive: true });

  await page.goto('http://127.0.0.1:8000/');
  await page.waitForFunction(() => window.__SL && window.__SL.ready === true, null, { timeout: 60000 });
  await page.mouse.click(1800, 100);
  await page.waitForTimeout(1000);

  // Load Level 1
  await page.evaluate(() => window.__SL_cmd('load_level', { level: 1 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(600);

  await page.screenshot({ path: 'qa/shots/soak/01_soak_start.png' });
  console.log('Saved 01_soak_start.png');

  const fpsSamples = [];
  const durationMs = 60000; // 60 seconds continuous soak loop
  const startTime = Date.now();
  let step = 0;

  console.log(`Running continuous gameplay soak loop for ${durationMs / 1000} seconds...`);

  while (Date.now() - startTime < durationMs) {
    step++;
    const currentLvl = (step % 4) + 1;

    // Switch levels every 15 steps
    if (step % 15 === 0) {
      await page.evaluate((lvl) => window.__SL_cmd('load_level', { level: lvl }), currentLvl);
      await page.waitForTimeout(400);
    }

    // Input actions: random walk, jump, pulse
    if (step % 3 === 0) {
      await page.keyboard.press('KeyD');
    } else if (step % 3 === 1) {
      await page.keyboard.press('KeyA');
    }

    if (step % 4 === 0) {
      await page.keyboard.press('KeyW'); // Jump
    }

    if (step % 5 === 0) {
      await page.keyboard.down('Space');
      await page.waitForTimeout(200);
      await page.keyboard.up('Space');
    }

    await page.waitForTimeout(200);

    // Sample snapshot
    const snap = await page.evaluate(() => window.__SL);
    if (snap && snap.fps > 0) {
      fpsSamples.push(snap.fps);
    }
  }

  // End of soak
  await page.screenshot({ path: 'qa/shots/soak/02_soak_end.png' });
  console.log('Saved 02_soak_end.png');

  const avgFps = fpsSamples.reduce((a, b) => a + b, 0) / (fpsSamples.length || 1);
  const minFps = Math.min(...fpsSamples);
  const maxFps = Math.max(...fpsSamples);

  console.log('\n--- Soak Test Performance Report ---');
  console.log(`Total duration: ${Math.round((Date.now() - startTime) / 1000)}s`);
  console.log(`Samples collected: ${fpsSamples.length}`);
  console.log(`Min FPS: ${minFps.toFixed(1)}, Max FPS: ${maxFps.toFixed(1)}, Avg FPS: ${avgFps.toFixed(1)}`);
  console.log(`Total Console Errors: ${errors.length}`);

  await browser.close();

  if (errors.length > 0) {
    console.error('Errors during soak test:', errors);
    process.exit(1);
  }
  if (minFps < 45) {
    console.warn(`Min FPS dropped below threshold: ${minFps}`);
  }

  console.log('STEP F SOAK TEST PASSED WITH 0 ERRORS');
}

runSoakTest().catch(err => {
  console.error('Soak Test Failed with Exception:', err);
  process.exit(1);
});
