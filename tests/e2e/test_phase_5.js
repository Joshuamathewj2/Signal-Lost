const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function runPhase5Test() {
  console.log('--- Starting Phase 5 E2E Test (Vertical Pipeline & Zero Soft-Locks) ---');
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

  const shotDir = 'qa/shots/phase_5';
  fs.mkdirSync(shotDir, { recursive: true });

  // 1. Test Level 3 (Iron Tier vertical descent & ladder)
  console.log('Loading Level 3 (Iron Tier)...');
  await page.evaluate(() => window.__SL_cmd && window.__SL_cmd('load_level', { level: 3 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(500);

  let snap = await page.evaluate(() => window.__SL);
  console.log('Level 3 player position:', snap.player.pos);
  await page.screenshot({ path: path.join(shotDir, '01_level_3_start.png') });

  // 2. Pulse to illuminate the vertical tiers
  console.log('Emitting normal pulse in Level 3...');
  await page.evaluate(() => window.__SL_cmd && window.__SL_cmd('spawn_pulse', { tier: 'normal' }));
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(shotDir, '02_level_3_pulse.png') });

  // 3. Move right and drop through catwalk
  console.log('Moving right across upper platform...');
  await page.keyboard.down('KeyD');
  await page.waitForTimeout(1200);
  await page.keyboard.up('KeyD');
  await page.waitForTimeout(400);

  snap = await page.evaluate(() => window.__SL);
  console.log('Player position after traversal:', snap.player.pos);
  await page.screenshot({ path: path.join(shotDir, '03_level_3_descending.png') });

  // 4. Test Level 4 (Glass Foundry)
  console.log('Loading Level 4 (Glass Foundry)...');
  await page.evaluate(() => window.__SL_cmd && window.__SL_cmd('load_level', { level: 4 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(500);

  snap = await page.evaluate(() => window.__SL);
  console.log('Level 4 player position:', snap.player.pos);
  await page.screenshot({ path: path.join(shotDir, '04_level_4_start.png') });

  await page.evaluate(() => window.__SL_cmd && window.__SL_cmd('spawn_pulse', { tier: 'scream' }));
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(shotDir, '05_level_4_scream.png') });

  await browser.close();

  const realErrors = errors.filter(e => !e.includes('favicon'));
  if (realErrors.length > 0) {
    console.error(`Phase 5 E2E FAILED with ${realErrors.length} errors:`, realErrors);
    process.exit(1);
  }

  console.log('Phase 5 E2E PASSED with ZERO ERRORS!');
}

runPhase5Test().catch(err => {
  console.error('Fatal error during Phase 5 test:', err);
  process.exit(1);
});
