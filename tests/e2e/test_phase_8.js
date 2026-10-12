const { chromium } = require('playwright');
const fs = require('fs');

async function runPhase8Test() {
  console.log('--- Starting Phase 8 Verification Test (Shogun Mech Boss & BossBar) ---');
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

  fs.mkdirSync('qa/shots/phase_8', { recursive: true });

  await page.goto('http://127.0.0.1:8000/');
  await page.waitForFunction(() => window.__SL && window.__SL.ready === true, null, { timeout: 60000 });
  await page.locator('canvas').click();
  await page.waitForTimeout(500);

  // Load Level 9: Shogun Citadel
  console.log('Loading Level 9 (Shogun Citadel)...');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(500);
  await page.evaluate(() => window.__SL_cmd('load_level', { level: 9 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(800);

  // 1. Sector 9 start screenshot
  await page.screenshot({ path: 'qa/shots/phase_8/01_boss_encounter_start.png' });
  console.log('Saved 01_boss_encounter_start.png');

  // 2. Pulse to illuminate Shogun Mech in arena
  console.log('Emitting pulse to reveal Shogun Mech in throne hall...');
  await page.evaluate(() => window.__SL_cmd('spawn_pulse', { tier: 'normal' }));
  await page.waitForTimeout(400);
  await page.screenshot({ path: 'qa/shots/phase_8/02_shogun_mech_revealed.png' });
  console.log('Saved 02_shogun_mech_revealed.png');

  // 3. Move closer to boss and test attack interaction
  console.log('Walking towards Shogun Mech arena center...');
  await page.keyboard.down('KeyD');
  await page.waitForTimeout(1000);
  await page.keyboard.up('KeyD');

  // Attack with Katana
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(300);

  // Scream pulse for dramatic arena illumination
  await page.evaluate(() => window.__SL_cmd('spawn_pulse', { tier: 'scream' }));
  await page.waitForTimeout(300);
  await page.screenshot({ path: 'qa/shots/phase_8/03_boss_combat_duel.png' });
  console.log('Saved 03_boss_combat_duel.png');

  await page.waitForTimeout(1000);

  console.log(`\nPhase 8 Total Errors: ${errors.length}`);
  if (errors.length > 0) {
    console.error('Errors encountered:');
    errors.forEach(e => console.error(' - ', e));
    await browser.close();
    process.exit(1);
  }

  console.log('Phase 8 Verification PASSED with ZERO ERRORS!');
  await browser.close();
}

runPhase8Test().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
