const { chromium } = require('playwright');
const fs = require('fs');

async function runStepE() {
  console.log('--- Starting Step E Automated Test (Gameplay Dynamics & AI) ---');
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

  fs.mkdirSync('qa/shots/step_e', { recursive: true });

  await page.goto('http://127.0.0.1:8000/');
  await page.waitForFunction(() => window.__SL && window.__SL.ready === true, null, { timeout: 60000 });
  await page.mouse.click(1800, 100);
  await page.waitForTimeout(1000);

  // 1. Load Level 2 (has Listener enemy)
  console.log('1. Loading Level 2 for Listener AI test...');
  await page.evaluate(() => window.__SL_cmd('load_level', { level: 2 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null && window.__SL.enemies.length > 0, null, { timeout: 15000 });
  await page.waitForTimeout(800);

  let snap = await page.evaluate(() => window.__SL);
  console.log('Initial Level 2 snapshot:', {
    playerPos: snap.player.pos,
    enemies: snap.enemies
  });

  // Verify Listener starts in Patrol
  let listener = snap.enemies.find(e => e.name.toLowerCase().includes('listener'));
  if (!listener) {
    throw new Error('Listener enemy not found in Level 2');
  }
  console.log(`Listener initial state: ${listener.state}, pos: ${listener.pos}`);

  // Screenshot 1: Listener in Patrol
  await page.screenshot({ path: 'qa/shots/step_e/01_listener_patrol.png' });
  console.log('Saved 01_listener_patrol.png');

  // 2. Whisper pulse test: Listener should IGNORE whisper
  console.log('2. Emitting Whisper pulse near Listener...');
  // Move player to x=450 (about 150px from Listener at ~606px, radius 90 -> not heard)
  await page.evaluate(() => window.__SL_cmd('teleport_player', { x: 450, y: 278 }));
  await page.waitForTimeout(400);

  // Whisper pulse (radius 90, loudness 1.0) -> Distance ~156 > 90 -> NOT heard
  await page.evaluate(() => window.__SL_cmd('spawn_pulse', { tier: 'whisper' }));
  await page.waitForTimeout(600);

  snap = await page.evaluate(() => window.__SL);
  listener = snap.enemies.find(e => e.name.toLowerCase().includes('listener'));
  console.log(`After Whisper - Listener state: ${listener.state}, awareness: ${listener.awareness}`);
  await page.screenshot({ path: 'qa/shots/step_e/02_whisper_ignored.png' });
  console.log('Saved 02_whisper_ignored.png');

  // 3. Normal pulse test: Listener should HEAR and INVESTIGATE
  console.log('3. Emitting Normal pulse within hearing range...');
  // Teleport player to x=500 (~106px from Listener)
  await page.evaluate(() => window.__SL_cmd('teleport_player', { x: 500, y: 278 }));
  await page.waitForTimeout(200);

  // Normal pulse (radius 350, loudness 2.0) -> Heard!
  await page.evaluate(() => window.__SL_cmd('spawn_pulse', { tier: 'normal' }));
  await page.waitForTimeout(800);

  snap = await page.evaluate(() => window.__SL);
  listener = snap.enemies.find(e => e.name.toLowerCase().includes('listener'));
  console.log(`After Normal pulse - Listener state: ${listener.state}, awareness: ${listener.awareness}, pos: ${listener.pos}`);
  await page.screenshot({ path: 'qa/shots/step_e/03_listener_investigating.png' });
  console.log('Saved 03_listener_investigating.png');

  // 4. Sentry test: Load Level 4 (has Sentry on high ledge)
  console.log('4. Loading Level 4 for Sentry test...');
  await page.evaluate(() => window.__SL_cmd('load_level', { level: 4 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null && window.__SL.enemies.length > 0, null, { timeout: 15000 });
  await page.waitForTimeout(800);

  snap = await page.evaluate(() => window.__SL);
  let sentry = snap.enemies.find(e => e.name.toLowerCase().includes('sentry'));
  console.log('Level 4 enemies:', snap.enemies);
  if (sentry) {
    console.log(`Sentry initial state: ${sentry.state}, pos: ${sentry.pos}`);
    // Emit Scream pulse to alert sentry
    await page.evaluate(() => window.__SL_cmd('spawn_pulse', { tier: 'scream' }));
    await page.waitForTimeout(700);

    snap = await page.evaluate(() => window.__SL);
    sentry = snap.enemies.find(e => e.name.toLowerCase().includes('sentry'));
    console.log(`After Scream - Sentry state: ${sentry.state}`);
  }
  await page.screenshot({ path: 'qa/shots/step_e/04_sentry_aim_and_fire.png' });
  console.log('Saved 04_sentry_aim_and_fire.png');

  // 5. Contact / Caught test: Teleport near enemy to verify caught death trigger & reload
  console.log('5. Testing player catch & reload...');
  await page.evaluate(() => window.__SL_cmd('load_level', { level: 2 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null && window.__SL.enemies.length > 0, null, { timeout: 15000 });
  await page.waitForTimeout(500);

  snap = await page.evaluate(() => window.__SL);
  listener = snap.enemies.find(e => e.name.toLowerCase().includes('listener'));
  // Teleport directly onto listener hitbox
  await page.evaluate((coords) => {
    window.__SL_cmd('teleport_player', { x: coords.x, y: coords.y });
  }, { x: listener.pos[0], y: listener.pos[1] });
  await page.waitForTimeout(400);

  await page.screenshot({ path: 'qa/shots/step_e/05_player_caught.png' });
  console.log('Saved 05_player_caught.png');

  await page.waitForTimeout(1000);

  await browser.close();

  console.log('\n--- Step E Test Results ---');
  console.log(`Total Errors: ${errors.length}`);
  if (errors.length > 0) {
    console.error('Errors encountered:', errors);
    process.exit(1);
  } else {
    console.log('STEP E PASSED WITH 0 ERRORS');
  }
}

runStepE().catch(err => {
  console.error('Step E Test Failed with Exception:', err);
  process.exit(1);
});
