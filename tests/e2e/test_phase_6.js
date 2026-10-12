const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function runPhase6Test() {
  console.log('--- Starting Phase 6 E2E Test (Escape-Room Puzzle Layer & Hint Beacon) ---');
  const browser = await chromium.launch({
    headless: true,
    channel: 'msedge',
    args: ['--enable-webgl', '--use-gl=angle']
  });
  const context = await browser.newContext({ viewport: { width: 1920, height: 1080 } });
  const page = await context.newPage();

  const errors = [];
  page.on('console', msg => {
    const text = msg.text();
    const type = msg.type();
    if (type === 'error') {
      errors.push(text);
      console.error('[BROWSER ERROR]', text);
    } else if (type === 'warning') {
      console.warn('[BROWSER WARN]', text);
    } else {
      console.log('[BROWSER LOG]', text);
    }
  });
  page.on('pageerror', err => {
    errors.push(err.message);
    console.error('[PAGE ERROR]', err.message);
  });

  await page.goto('http://127.0.0.1:8000/');
  console.log('Waiting for engine initialization...');
  await page.waitForFunction(() => window.__SL && window.__SL.ready === true, null, { timeout: 60000 });
  await page.locator('canvas').click();
  await page.waitForTimeout(1000);

  const shotDir = 'qa/shots/phase_6';
  fs.mkdirSync(shotDir, { recursive: true });

  console.log('Loading Level 1...');
  await page.evaluate(() => window.__SL_cmd && window.__SL_cmd('load_level', { level: 1 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(500);

  let snap = await page.evaluate(() => window.__SL);
  console.log('Level 1 player ready:', snap.player.pos);
  await page.screenshot({ path: path.join(shotDir, '01_level_start.png') });

  // Test emergency hint beacon (KeyH)
  console.log('Pressing H (Hint Beacon)...');
  await page.keyboard.press('KeyH');
  await page.waitForTimeout(400);

  snap = await page.evaluate(() => window.__SL);
  console.log('Noise events after hint beacon:', snap.noise_events.length);
  await page.screenshot({ path: path.join(shotDir, '02_hint_beacon_fired.png') });

  // Test pulse wavefront
  console.log('Emitting whisper pulse...');
  await page.evaluate(() => window.__SL_cmd && window.__SL_cmd('spawn_pulse', { tier: 'whisper' }));
  await page.waitForTimeout(500);
  await page.screenshot({ path: path.join(shotDir, '03_whisper_pulse.png') });

  await browser.close();

  const realErrors = errors.filter(e => !e.includes('favicon'));
  if (realErrors.length > 0) {
    console.error(`Phase 6 E2E FAILED with ${realErrors.length} errors:`, realErrors);
    process.exit(1);
  }

  console.log('Phase 6 E2E PASSED with ZERO ERRORS!');
}

runPhase6Test().catch(err => {
  console.error('Fatal error during Phase 6 test:', err);
  process.exit(1);
});
