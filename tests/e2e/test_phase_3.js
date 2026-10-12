const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function runPhase3Test() {
  console.log('--- Starting Phase 3 E2E Test (Adversary Roster & Combat Duel) ---');
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

  const shotDir = 'qa/shots/phase_3';
  fs.mkdirSync(shotDir, { recursive: true });

  // Load Level 2 (contains Listener and patrolling enemies)
  console.log('Loading Level 2...');
  await page.evaluate(() => window.__SL_cmd && window.__SL_cmd('load_level', { level: 2 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null && window.__SL.enemies.length > 0, null, { timeout: 15000 });
  await page.waitForTimeout(500);

  let snap = await page.evaluate(() => window.__SL);
  console.log('Enemies detected in Level 2:', snap.enemies.length);
  if (snap.enemies.length === 0) {
    throw new Error('Expected enemies in Level 2');
  }

  const enemy = snap.enemies[0];
  console.log('Target enemy initial state:', enemy.name, 'state =', enemy.state, 'health =', enemy.health, 'poise =', enemy.poise);

  await page.screenshot({ path: path.join(shotDir, '01_enemy_patrol.png') });

  // Teleport player close to enemy to engage in melee combat
  console.log('Engaging enemy in combat duel...');
  await page.evaluate((targetPos) => {
    window.__SL_cmd('teleport_player', { x: targetPos[0] - 30, y: targetPos[1] });
  }, enemy.pos);
  await page.waitForTimeout(300);

  // Attack enemy
  console.log('Executing Katana Slash...');
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(150);

  snap = await page.evaluate(() => window.__SL);
  console.log('Player combat state after swing:', snap.player.combat_state);
  await page.screenshot({ path: path.join(shotDir, '02_combat_clash.png') });

  // Test Parry stance
  console.log('Executing Parry stance against enemy...');
  await page.keyboard.down('KeyK');
  await page.waitForTimeout(50);
  snap = await page.evaluate(() => window.__SL);
  console.log('Player parry state:', snap.player.combat_state);
  await page.screenshot({ path: path.join(shotDir, '03_parry_duel.png') });
  await page.keyboard.up('KeyK');
  await page.waitForTimeout(200);

  await browser.close();

  if (errors.length > 0) {
    throw new Error(`Browser console errors detected: ${JSON.stringify(errors)}`);
  }

  console.log('--- Phase 3 Adversary E2E Test PASSED ---');
}

runPhase3Test().catch(err => {
  console.error('Phase 3 E2E Test FAILED:', err);
  process.exit(1);
});
