const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function runPhase4Test() {
  console.log('--- Starting Phase 4 E2E Test (Adversary Roster: Kenshi, Yumi & Brute) ---');
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

  const shotDir = 'qa/shots/phase_4';
  fs.mkdirSync(shotDir, { recursive: true });

  console.log('Loading Level 2...');
  await page.evaluate(() => window.__SL_cmd && window.__SL_cmd('load_level', { level: 2 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(500);

  let snap = await page.evaluate(() => window.__SL);
  console.log('Initial player position:', snap.player.pos);
  await page.screenshot({ path: path.join(shotDir, '01_level_start.png') });

  // Test Weapon cycle to Naginata & Kunai
  console.log('Testing Weapon Swap (Q key)...');
  await page.keyboard.press('KeyQ');
  await page.waitForTimeout(100);
  snap = await page.evaluate(() => window.__SL);
  console.log('Swapped weapon:', snap.player.weapon);

  // Execute heavy impale
  console.log('Executing Heavy Attack (I key)...');
  await page.keyboard.press('KeyI');
  await page.waitForTimeout(150);
  snap = await page.evaluate(() => window.__SL);
  console.log('Player combat state during heavy attack:', snap.player.combat_state);
  await page.screenshot({ path: path.join(shotDir, '02_heavy_attack.png') });

  // Execute Parry
  console.log('Testing Parry Deflect Stance (K key)...');
  await page.keyboard.down('KeyK');
  await page.waitForTimeout(50);
  snap = await page.evaluate(() => window.__SL);
  console.log('Player parry state:', snap.player.combat_state);
  await page.screenshot({ path: path.join(shotDir, '03_kenshi_parry.png') });
  await page.keyboard.up('KeyK');
  await page.waitForTimeout(200);

  await browser.close();

  if (errors.length > 0) {
    throw new Error(`Browser console errors detected: ${JSON.stringify(errors)}`);
  }

  console.log('--- Phase 4 Adversary E2E Test PASSED ---');
}

runPhase4Test().catch(err => {
  console.error('Phase 4 E2E Test FAILED:', err);
  process.exit(1);
});
