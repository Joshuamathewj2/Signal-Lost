const { chromium } = require('playwright');
const fs = require('fs');

async function runStepD() {
  console.log('--- Starting Step D Automated Test (HUD & Menus Redesign) ---');
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

  fs.mkdirSync('qa/shots/step_d', { recursive: true });

  await page.goto('http://127.0.0.1:8000/');
  await page.waitForFunction(() => window.__SL && window.__SL.ready === true, null, { timeout: 60000 });
  
  // Click in the top-right corner to focus canvas without hitting centered menu buttons
  await page.mouse.click(1800, 100);
  await page.waitForTimeout(1000);

  // 1. Main menu with sonar wipe logo and white outlined buttons
  await page.screenshot({ path: 'qa/shots/step_d/01_main_menu.png' });
  console.log('Saved 01_main_menu.png');

  // 2. Open Level Select
  console.log('Opening Level Select...');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(600);
  await page.screenshot({ path: 'qa/shots/step_d/02_level_select.png' });
  console.log('Saved 02_level_select.png');

  // 3. Start Level 1
  console.log('Loading Level 1...');
  await page.evaluate(() => window.__SL_cmd('load_level', { level: 1 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(600);

  // Screenshot HUD in gameplay
  await page.screenshot({ path: 'qa/shots/step_d/03_hud_gameplay.png' });
  console.log('Saved 03_hud_gameplay.png');

  // 4. Battery preview during charge
  console.log('Holding Space to test battery bar charge preview...');
  await page.keyboard.down('Space');
  await page.waitForTimeout(450); // Charging normal pulse
  await page.screenshot({ path: 'qa/shots/step_d/04_battery_preview_charging.png' });
  console.log('Saved 04_battery_preview_charging.png');
  await page.keyboard.up('Space');
  await page.waitForTimeout(1000);

  // 5. Pause Menu
  console.log('Opening Pause Menu...');
  await page.evaluate(() => window.__SL_cmd('pause_game', {}));
  await page.waitForTimeout(600);
  await page.screenshot({ path: 'qa/shots/step_d/05_pause_menu.png' });
  console.log('Saved 05_pause_menu.png');

  // Resume game
  console.log('Resuming game...');
  await page.evaluate(() => window.__SL_cmd('resume_game', {}));
  await page.waitForTimeout(400);

  // 6. Settings Menu
  console.log('Opening Settings Menu...');
  await page.evaluate(() => window.__SL_cmd('show_settings', {}));
  await page.waitForTimeout(600);
  await page.screenshot({ path: 'qa/shots/step_d/06_settings_menu.png' });
  console.log('Saved 06_settings_menu.png');

  // Close Settings
  await page.keyboard.press('Escape');
  await page.waitForTimeout(400);

  // 7. Level Complete Screen
  console.log('Showing Level Complete Screen...');
  await page.evaluate(() => window.__SL_cmd('show_level_complete', { level: 1 }));
  await page.waitForTimeout(1200); // Wait for title and medal animation
  await page.screenshot({ path: 'qa/shots/step_d/07_level_complete.png' });
  console.log('Saved 07_level_complete.png');

  // 8. Load Level 2 (contains Listener enemy) to test Enemy Awareness Bar
  console.log('Loading Level 2 to reveal enemy awareness bar...');
  await page.evaluate(() => window.__SL_cmd('load_level', { level: 2 }));
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(600);

  // Teleport player near Listener (around x=550, y=430) and emit pulse to illuminate it
  console.log('Teleporting player near Listener and emitting pulse...');
  await page.evaluate(() => window.__SL_cmd('teleport_player', { x: 550, y: 430 }));
  await page.waitForTimeout(300);
  await page.evaluate(() => window.__SL_cmd('spawn_pulse', { tier: 'normal' }));
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'qa/shots/step_d/08_enemy_awareness_bar.png' });
  console.log('Saved 08_enemy_awareness_bar.png');

  await page.waitForTimeout(1500);

  console.log(`\nTotal Errors Recorded: ${errors.length}`);
  if (errors.length > 0) {
    console.error('Errors encountered:');
    errors.forEach(e => console.error(' - ', e));
    await browser.close();
    process.exit(1);
  }

  console.log('Step D test completed with ZERO ERRORS!');
  await browser.close();
}

runStepD().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
