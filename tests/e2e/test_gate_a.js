const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function runGateA() {
  console.log('--- Starting Gate A Automated Test ---');
  const browser = await chromium.launch({
    headless: true,
    channel: 'msedge',
    args: ['--enable-webgl', '--use-gl=angle']
  });
  const context = await browser.newContext({ viewport: { width: 1920, height: 1080 } });
  const page = await context.newPage();

  const errors = [];
  const warnings = [];

  page.on('console', msg => {
    const text = msg.text();
    const type = msg.type();
    if (type === 'error') {
      errors.push(text);
      console.error('[BROWSER ERROR]', text);
    } else if (type === 'warning') {
      warnings.push(text);
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
  console.log('Page loaded. Waiting for engine initialization...');
  await page.waitForFunction(() => window.__SL && window.__SL.ready === true, null, { timeout: 60000 });
  await page.locator('canvas').click();
  await page.waitForTimeout(1000);

  // Take main menu screenshot
  fs.mkdirSync('qa/shots/gate_a', { recursive: true });
  await page.screenshot({ path: 'qa/shots/gate_a/01_gate_a_menu.png' });

  // Load Level 1
  console.log('Starting Level 1...');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(500);
  await page.evaluate(() => window.__SL_cmd && window.__SL_cmd('load_level', { level: 1 }));
  
  console.log('Waiting for player spawn in Level 1...');
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });

  const snap1 = await page.evaluate(() => window.__SL);
  console.log('Initial Level 1 snapshot:', JSON.stringify(snap1.player));
  await page.screenshot({ path: 'qa/shots/gate_a/02_gate_a_level_start.png' });

  console.log('Running 30-second movement sequence (Left, Right, Jump, Crouch)...');
  const startTime = Date.now();
  let cycle = 0;

  while (Date.now() - startTime < 30000) {
    cycle++;
    // Walk Right
    await page.keyboard.down('KeyD');
    await page.waitForTimeout(1500);
    await page.keyboard.up('KeyD');
    if (cycle === 1) await page.screenshot({ path: 'qa/shots/gate_a/03_gate_a_walking_right.png' });

    // Walk Left
    await page.keyboard.down('KeyA');
    await page.waitForTimeout(1500);
    await page.keyboard.up('KeyA');
    if (cycle === 1) await page.screenshot({ path: 'qa/shots/gate_a/04_gate_a_walking_left.png' });

    // Jump
    await page.keyboard.down('KeyW');
    await page.waitForTimeout(200);
    await page.keyboard.up('KeyW');
    await page.waitForTimeout(400);
    if (cycle === 1) await page.screenshot({ path: 'qa/shots/gate_a/05_gate_a_jumping.png' });

    // Crouch / Sneak
    await page.keyboard.down('Shift');
    await page.keyboard.down('KeyD');
    await page.waitForTimeout(1000);
    await page.keyboard.up('KeyD');
    await page.keyboard.up('Shift');
    if (cycle === 1) await page.screenshot({ path: 'qa/shots/gate_a/06_gate_a_crouch_sneak.png' });

    const currentSnap = await page.evaluate(() => window.__SL);
    console.log(`Cycle ${cycle} [elapsed ${Math.round((Date.now() - startTime)/1000)}s] Pos: ${JSON.stringify(currentSnap.player?.pos)} Errors: ${errors.length}`);
  }

  await page.screenshot({ path: 'qa/shots/gate_a/07_gate_a_after_30s.png' });

  // Check in-engine recorded errors
  const engineErrors = await page.evaluate(() => window.__SL_errors || []);
  console.log('In-engine captured errors:', engineErrors);

  await browser.close();

  const totalErrors = errors.length + engineErrors.length;
  console.log(`--- Gate A Complete: Total Errors = ${totalErrors} ---`);

  if (totalErrors > 0) {
    console.error('Gate A FAILED with errors:', { browserErrors: errors, engineErrors });
    process.exit(1);
  } else {
    console.log('Gate A PASSED: 30 seconds of movement with 0 errors.');
    process.exit(0);
  }
}

runGateA().catch(err => {
  console.error('Fatal Gate A error:', err);
  process.exit(1);
});
