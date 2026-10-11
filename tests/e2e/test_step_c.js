const { chromium } = require('playwright');
const fs = require('fs');

async function runStepC() {
  console.log('--- Starting Step C Automated Test (Visual Style Polish) ---');
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
    } else {
      console.log('[BROWSER LOG]', msg.text());
    }
  });

  page.on('pageerror', err => {
    errors.push(err.message);
    console.error('[PAGE ERROR]', err.message);
  });

  await page.goto('http://127.0.0.1:8000/');
  await page.waitForFunction(() => window.__SL && window.__SL.ready === true, null, { timeout: 60000 });
  await page.locator('canvas').click();
  await page.waitForTimeout(500);

  // Load Level 1
  await page.keyboard.press('Enter');
  await page.waitForTimeout(500);
  await page.evaluate(() => window.__SL_cmd('load_level', { level: 1 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(600);

  fs.mkdirSync('qa/shots/step_c', { recursive: true });

  // 1. Idle vector robot
  await page.screenshot({ path: 'qa/shots/step_c/01_player_vector_idle.png' });
  console.log('Saved 01_player_vector_idle.png');

  // 2. Charging pulse (Space held) -> Eye turns cyan, charge rings radiate
  console.log('Holding Space to charge pulse...');
  await page.keyboard.down('Space');
  await page.waitForTimeout(400); // 400ms into charge
  await page.screenshot({ path: 'qa/shots/step_c/02_player_eye_charging_cyan.png' });
  console.log('Saved 02_player_eye_charging_cyan.png');

  // Release Space to fire Normal pulse
  await page.keyboard.up('Space');
  await page.waitForTimeout(300);
  await page.screenshot({ path: 'qa/shots/step_c/03_normal_pulse_reveal.png' });
  console.log('Saved 03_normal_pulse_reveal.png');

  await page.waitForTimeout(2500);

  // 3. Fire Scream pulse to test screen shake & chromatic aberration
  console.log('Spawning Scream pulse for shake & chromatic aberration test...');
  await page.evaluate(() => window.__SL_cmd('spawn_pulse', { tier: 'scream' }));
  await page.waitForTimeout(200);
  await page.screenshot({ path: 'qa/shots/step_c/04_scream_shake_and_ca.png' });
  console.log('Saved 04_scream_shake_and_ca.png');

  await page.waitForTimeout(500);
  await page.screenshot({ path: 'qa/shots/step_c/05_interactables_revealed.png' });
  console.log('Saved 05_interactables_revealed.png');

  await page.waitForTimeout(3000);

  console.log(`\nTotal Errors Recorded: ${errors.length}`);
  if (errors.length > 0) {
    console.error('Errors encountered:');
    errors.forEach(e => console.error(' - ', e));
    await browser.close();
    process.exit(1);
  }

  console.log('Step C test completed with ZERO ERRORS!');
  await browser.close();
}

runStepC().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
