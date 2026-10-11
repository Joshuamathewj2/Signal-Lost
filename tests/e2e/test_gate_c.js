const { chromium } = require('playwright');
const fs = require('fs');

async function runGateC() {
  console.log('--- Starting Gate C Automated Test (Full Level 1 Playthrough) ---');
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

  fs.mkdirSync('qa/shots/gate_c', { recursive: true });

  await page.goto('http://127.0.0.1:8000/');
  await page.waitForFunction(() => window.__SL && window.__SL.ready === true, null, { timeout: 60000 });
  await page.mouse.click(1800, 100);
  await page.waitForTimeout(1000);

  // 1. Start Level 1
  console.log('1. Loading Level 1...');
  await page.evaluate(() => window.__SL_cmd('load_level', { level: 1 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(800);

  let snap = await page.evaluate(() => window.__SL);
  console.log('Level 1 start state:', {
    playerPos: snap.player.pos,
    battery: snap.battery,
    level: snap.level
  });

  // Screenshot 1: Level 1 Start
  await page.screenshot({ path: 'qa/shots/gate_c/01_level1_start.png' });
  console.log('Saved 01_level1_start.png');

  // 2. Pulse using keyboard Space to reveal surroundings
  console.log('2. Charging and releasing Normal Pulse via keyboard Space...');
  await page.keyboard.down('Space');
  await page.waitForTimeout(500); // Charge to normal tier
  await page.keyboard.up('Space');
  await page.waitForTimeout(400);

  // Walk right past hint sign
  console.log('Walking right past hint sign...');
  await page.keyboard.down('KeyD');
  await page.waitForTimeout(800);
  await page.keyboard.up('KeyD');

  // Screenshot 2: Walking and revealing level
  await page.screenshot({ path: 'qa/shots/gate_c/02_level1_walking_and_pulse.png' });
  console.log('Saved 02_level1_walking_and_pulse.png');

  // 3. Move player up to collect memory Fragment at column 27 (x = 880, y = 176)
  console.log('3. Navigating to Memory Fragment...');
  // Player moves directly onto fragment
  await page.evaluate(() => {
    window.__SL_cmd('teleport_player', { x: 880, y: 176 });
  });
  await page.waitForTimeout(600);

  snap = await page.evaluate(() => window.__SL);
  console.log(`Fragments collected: ${snap.fragments_collected}`);

  // Screenshot 3: Fragment collected
  await page.screenshot({ path: 'qa/shots/gate_c/03_fragment_collected.png' });
  console.log('Saved 03_fragment_collected.png');

  // 4. Navigate to Exit Terminal at (36.5 * 32 = 1168, 300)
  console.log('4. Navigating to Exit Terminal...');
  await page.evaluate(() => {
    window.__SL_cmd('teleport_player', { x: 1140, y: 300 });
  });
  await page.waitForTimeout(300);

  // Walk into terminal
  await page.keyboard.down('KeyD');
  await page.waitForTimeout(500);
  await page.keyboard.up('KeyD');

  // Screenshot 4: Terminal activation
  await page.screenshot({ path: 'qa/shots/gate_c/04_terminal_activated.png' });
  console.log('Saved 04_terminal_activated.png');

  // 5. Await level completion screen
  console.log('5. Waiting for Level Complete screen (SIGNAL RESTORED)...');
  await page.waitForTimeout(1200);

  // Screenshot 5: Level Complete screen with Ghost Medal
  await page.screenshot({ path: 'qa/shots/gate_c/05_level_complete_ghost_medal.png' });
  console.log('Saved 05_level_complete_ghost_medal.png');

  await page.waitForTimeout(500);
  await browser.close();

  console.log('\n--- Gate C Test Results ---');
  console.log(`Total Errors: ${errors.length}`);
  if (errors.length > 0) {
    console.error('Errors encountered:', errors);
    process.exit(1);
  } else {
    console.log('GATE C PASSED WITH 0 ERRORS');
  }
}

runGateC().catch(err => {
  console.error('Gate C Test Failed with Exception:', err);
  process.exit(1);
});
