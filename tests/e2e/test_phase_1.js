const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function runPhase1Test() {
  console.log('--- Starting Phase 1 E2E Test (Combat System) ---');
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
  console.log('Waiting for engine initialization...');
  await page.waitForFunction(() => window.__SL && window.__SL.ready === true, null, { timeout: 60000 });
  await page.locator('canvas').click();
  await page.waitForTimeout(1000);

  // Load Level 1
  console.log('Loading Level 1...');
  await page.evaluate(() => window.__SL_cmd && window.__SL_cmd('load_level', { level: 1 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(500);

  const shotDir = 'qa/shots/phase_1';
  fs.mkdirSync(shotDir, { recursive: true });

  let snap = await page.evaluate(() => window.__SL);
  console.log('Initial player state:', JSON.stringify(snap.player));
  if (snap.player.health !== 3) {
    throw new Error(`Expected health 3, got ${snap.player.health}`);
  }
  if (snap.player.poise !== 100) {
    throw new Error(`Expected poise 100, got ${snap.player.poise}`);
  }

  // Test 1: Attack Combo via key 'KeyJ'
  console.log('Executing Attack Combo (J)...');
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(100);
  snap = await page.evaluate(() => window.__SL);
  console.log('After attack 1: combat_state =', snap.player.combat_state, 'combo =', snap.player.combo);
  if (snap.player.combat_state !== 'attacking') {
    throw new Error(`Expected attacking state, got ${snap.player.combat_state}`);
  }
  await page.screenshot({ path: path.join(shotDir, '01_katana_slash.png') });

  // Test 2: Dash roll via 'KeyL'
  console.log('Executing Dash Roll (L)...');
  await page.waitForTimeout(400); // Wait for attack recovery
  await page.keyboard.press('KeyL');
  await page.waitForTimeout(50);
  snap = await page.evaluate(() => window.__SL);
  console.log('After dash: combat_state =', snap.player.combat_state);
  if (snap.player.combat_state !== 'dashing') {
    throw new Error(`Expected dashing state, got ${snap.player.combat_state}`);
  }
  await page.screenshot({ path: path.join(shotDir, '02_dash_roll.png') });

  // Test 3: Parry & Guard via 'KeyK'
  console.log('Executing Parry (K)...');
  await page.waitForTimeout(400); // Wait for dash to finish
  await page.keyboard.down('KeyK');
  await page.waitForTimeout(40);
  snap = await page.evaluate(() => window.__SL);
  console.log('After parry key down: combat_state =', snap.player.combat_state);
  if (snap.player.combat_state !== 'parrying') {
    throw new Error(`Expected parrying state, got ${snap.player.combat_state}`);
  }
  await page.screenshot({ path: path.join(shotDir, '03_parry_stance.png') });

  await page.waitForTimeout(100);
  snap = await page.evaluate(() => window.__SL);
  console.log('After holding block: combat_state =', snap.player.combat_state);
  if (snap.player.combat_state !== 'guarding') {
    throw new Error(`Expected guarding state, got ${snap.player.combat_state}`);
  }
  await page.keyboard.up('KeyK');
  await page.waitForTimeout(50);

  // Test 4: Damage reception
  console.log('Testing damage taking...');
  await page.evaluate(() => window.__SL_cmd('damage_player', { damage: 1 }));
  await page.waitForTimeout(100);
  snap = await page.evaluate(() => window.__SL);
  console.log('After damage: health =', snap.player.health);
  if (snap.player.health !== 2) {
    throw new Error(`Expected health 2 after 1 damage, got ${snap.player.health}`);
  }

  await browser.close();

  if (errors.length > 0) {
    throw new Error(`Browser console errors detected: ${JSON.stringify(errors)}`);
  }

  console.log('--- Phase 1 Combat E2E Test PASSED ---');
}

runPhase1Test().catch(err => {
  console.error('Phase 1 E2E Test FAILED:', err);
  process.exit(1);
});
