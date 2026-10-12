const { chromium } = require('playwright');
const fs = require('fs');

async function run5MinSoak() {
  console.log('=== Final 5-Minute Soak Test (300 seconds) ===');
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

  await page.goto('http://127.0.0.1:8000/');
  await page.waitForFunction(() => window.__SL && window.__SL.ready === true, null, { timeout: 60000 });
  await page.keyboard.press('Enter');
  await page.waitForTimeout(600);

  await page.evaluate(() => window.__SL_cmd('load_level', { level: 1 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(600);

  const durationMs = 300000; // 5 minutes
  const startTime = Date.now();
  let step = 0;
  let webglLostCount = 0;
  const fpsSamples = [];

  console.log('Running 5-minute gameplay soak loop...');

  while (Date.now() - startTime < durationMs) {
    step++;
    const currentLvl = (step % 9) + 1;

    if (step % 25 === 0) {
      await page.evaluate((lvl) => window.__SL_cmd('load_level', { level: lvl }), currentLvl);
      await page.waitForTimeout(300);
    }

    if (step % 3 === 0) await page.keyboard.press('KeyD');
    else if (step % 3 === 1) await page.keyboard.press('KeyA');

    if (step % 4 === 0) await page.keyboard.press('KeyW');
    if (step % 5 === 0) await page.keyboard.press('KeyJ');
    if (step % 7 === 0) await page.evaluate(() => window.__SL_cmd('spawn_pulse', { tier: 'normal' }));
    if (step % 13 === 0) await page.evaluate(() => window.__SL_cmd('cycle_weapon'));

    const isContextLost = await page.evaluate(() => {
      const c = document.querySelector('canvas');
      if (!c) return false;
      const gl = c.getContext('webgl2') || c.getContext('webgl');
      return gl ? gl.isContextLost() : false;
    });

    if (isContextLost) {
      webglLostCount++;
      errors.push('WebGL context lost during 5-minute soak!');
    }

    await page.waitForTimeout(300);

    const snap = await page.evaluate(() => window.__SL);
    if (snap && snap.fps > 0) {
      fpsSamples.push(snap.fps);
    }

    if (step % 100 === 0) {
      const elapsed = Math.round((Date.now() - startTime) / 1000);
      console.log(`[Soak ${elapsed}s / 300s] Samples: ${fpsSamples.length}, Errors: ${errors.length}, WebGL Lost: ${webglLostCount}`);
    }
  }

  await page.screenshot({ path: 'qa/shots/phase_9/soak_5min_end.png' });
  const avgFps = fpsSamples.reduce((a, b) => a + b, 0) / (fpsSamples.length || 1);

  console.log('\n--- 5-Minute Soak Complete ---');
  console.log(`Duration: ${Math.round((Date.now() - startTime) / 1000)}s | Samples: ${fpsSamples.length}`);
  console.log(`Avg FPS: ${avgFps.toFixed(1)} | WebGL Lost: ${webglLostCount} | Total Errors: ${errors.length}`);

  await browser.close();

  if (errors.length > 0 || webglLostCount > 0) {
    process.exit(1);
  }
  console.log('5-MINUTE SOAK TEST PASSED WITH 0 ERRORS!');
}

run5MinSoak().catch(err => {
  console.error('Fatal soak error:', err);
  process.exit(1);
});
