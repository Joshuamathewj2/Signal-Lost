const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function runPhase2Test() {
  console.log('--- Starting Phase 2 E2E Test (Weapon Arsenal & Sub-Weapons) ---');
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

  const shotDir = 'qa/shots/phase_2';
  fs.mkdirSync(shotDir, { recursive: true });

  let snap = await page.evaluate(() => window.__SL);
  console.log('Initial player weapon:', snap.player.weapon);
  if (snap.player.weapon !== 'Katana') {
    throw new Error(`Expected initial weapon Katana, got ${snap.player.weapon}`);
  }

  // Test 1: Cycle to Naginata
  console.log('Cycling weapon (Q) -> Naginata...');
  await page.keyboard.press('KeyQ');
  await page.waitForTimeout(100);
  snap = await page.evaluate(() => window.__SL);
  console.log('After Q: weapon =', snap.player.weapon);
  if (snap.player.weapon !== 'Naginata') {
    throw new Error(`Expected Naginata, got ${snap.player.weapon}`);
  }
  await page.screenshot({ path: path.join(shotDir, '01_naginata_equipped.png') });

  // Test 2: Attack with Naginata
  console.log('Attacking with Naginata (J)...');
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(100);
  snap = await page.evaluate(() => window.__SL);
  console.log('Naginata attack: combat_state =', snap.player.combat_state, 'combo =', snap.player.combo);
  if (snap.player.combat_state !== 'attacking') {
    throw new Error(`Expected attacking state, got ${snap.player.combat_state}`);
  }
  await page.waitForTimeout(400);

  // Test 3: Cycle to Kunai
  console.log('Cycling weapon (Q) -> Kunai...');
  await page.keyboard.press('KeyQ');
  await page.waitForTimeout(100);
  snap = await page.evaluate(() => window.__SL);
  console.log('After Q: weapon =', snap.player.weapon);
  if (snap.player.weapon !== 'Kunai') {
    throw new Error(`Expected Kunai, got ${snap.player.weapon}`);
  }
  await page.screenshot({ path: path.join(shotDir, '02_kunai_equipped.png') });

  // Test 4: Attack with Kunai
  console.log('Attacking with Kunai (J)...');
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(80);
  snap = await page.evaluate(() => window.__SL);
  console.log('Kunai attack: combat_state =', snap.player.combat_state, 'combo =', snap.player.combo);
  if (snap.player.combat_state !== 'attacking') {
    throw new Error(`Expected attacking state, got ${snap.player.combat_state}`);
  }
  await page.waitForTimeout(400);

  // Test 5: Cycle back to Katana
  console.log('Cycling weapon (Q) -> Katana...');
  await page.keyboard.press('KeyQ');
  await page.waitForTimeout(100);
  snap = await page.evaluate(() => window.__SL);
  console.log('After Q: weapon =', snap.player.weapon);
  if (snap.player.weapon !== 'Katana') {
    throw new Error(`Expected Katana, got ${snap.player.weapon}`);
  }

  // Test 6: Throw Shuriken (F)
  console.log('Throwing Shuriken (F)...');
  await page.keyboard.press('KeyF');
  await page.waitForTimeout(150);
  await page.screenshot({ path: path.join(shotDir, '03_shuriken_thrown.png') });

  await browser.close();

  if (errors.length > 0) {
    throw new Error(`Browser console errors detected: ${JSON.stringify(errors)}`);
  }

  console.log('--- Phase 2 Weapon E2E Test PASSED ---');
}

runPhase2Test().catch(err => {
  console.error('Phase 2 E2E Test FAILED:', err);
  process.exit(1);
});
