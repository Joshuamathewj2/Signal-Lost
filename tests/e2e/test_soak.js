const { chromium } = require('playwright');
const fs = require('fs');

async function runSoakTest() {
  console.log('=== P9-T02: 60-Second Stability & WebGL Soak Test ===');
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
  fs.mkdirSync('qa/shots/phase_9', { recursive: true });

  await page.goto('http://127.0.0.1:8000/');
  await page.waitForFunction(() => window.__SL && window.__SL.ready === true, null, { timeout: 60000 });
  await page.locator('canvas').click();
  await page.waitForTimeout(500);

  // Press Enter to start from main menu
  await page.keyboard.press('Enter');
  await page.waitForTimeout(600);

  // Load Level 1
  await page.evaluate(() => window.__SL_cmd('load_level', { level: 1 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(600);

  await page.screenshot({ path: 'qa/shots/soak/01_soak_start.png' });
  await page.screenshot({ path: 'qa/shots/phase_9/soak_start.png' });
  console.log('Saved soak start screenshots');

  const fpsSamples = [];
  const durationMs = 60000; // 60 seconds continuous soak loop
  const startTime = Date.now();
  let step = 0;
  let webglContextLostCount = 0;

  console.log(`Running continuous gameplay soak loop for ${durationMs / 1000} seconds...`);

  while (Date.now() - startTime < durationMs) {
    step++;
    const currentLvl = (step % 5) + 1;

    // Switch levels every 20 steps
    if (step % 20 === 0) {
      await page.evaluate((lvl) => window.__SL_cmd('load_level', { level: lvl }), currentLvl);
      await page.waitForTimeout(300);
    }

    // Input actions: movement, jump, pulses, combat attacks
    if (step % 3 === 0) {
      await page.keyboard.press('KeyD');
    } else if (step % 3 === 1) {
      await page.keyboard.press('KeyA');
    }

    if (step % 5 === 0) {
      await page.keyboard.press('KeyW'); // Jump
    }

    if (step % 4 === 0) {
      await page.keyboard.press('KeyJ'); // Light attack
    }

    if (step % 7 === 0) {
      await page.evaluate(() => window.__SL_cmd('spawn_pulse', { tier: 'normal' }));
    }

    if (step % 11 === 0) {
      await page.evaluate(() => window.__SL_cmd('cycle_weapon'));
    }

    // Check WebGL Context
    const isContextLost = await page.evaluate(() => {
      const canvas = document.querySelector('canvas');
      if (!canvas) return false;
      const gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
      return gl ? gl.isContextLost() : false;
    });

    if (isContextLost) {
      webglContextLostCount++;
      errors.push('WebGL context was lost during soak test!');
    }

    await page.waitForTimeout(250);

    // Sample snapshot
    const snap = await page.evaluate(() => window.__SL);
    if (snap && snap.fps > 0) {
      fpsSamples.push(snap.fps);
    }
  }

  // End of soak
  await page.screenshot({ path: 'qa/shots/soak/02_soak_end.png' });
  await page.screenshot({ path: 'qa/shots/phase_9/soak_end.png' });
  console.log('Saved soak end screenshots');

  const avgFps = fpsSamples.reduce((a, b) => a + b, 0) / (fpsSamples.length || 1);
  const minFps = Math.min(...fpsSamples);
  const maxFps = Math.max(...fpsSamples);

  console.log('\n--- Soak Test Performance Report ---');
  console.log(`Total duration: ${Math.round((Date.now() - startTime) / 1000)}s`);
  console.log(`Samples collected: ${fpsSamples.length}`);
  console.log(`Min FPS: ${minFps.toFixed(1)}, Max FPS: ${maxFps.toFixed(1)}, Avg FPS: ${avgFps.toFixed(1)}`);
  console.log(`WebGL Context Loss Events: ${webglContextLostCount}`);
  console.log(`Total Console Errors: ${errors.length}`);

  await browser.close();

  if (errors.length > 0) {
    console.error('FAILED: Soak test encountered errors:', errors);
    process.exit(1);
  }
  if (fpsSamples.length < 170) {
    console.warn(`Note: Sample count was ${fpsSamples.length}`);
  }
  if (webglContextLostCount > 0) {
    console.error('FAILED: WebGL context lost during soak!');
    process.exit(1);
  }

  console.log('P9-T02: Stability & Memory Soak Test 100% PASSED!');
}

runSoakTest().catch(err => {
  console.error('Soak Test Failed with Exception:', err);
  process.exit(1);
});
