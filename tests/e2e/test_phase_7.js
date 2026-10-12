const { chromium } = require('playwright');
const fs = require('fs');

async function runPhase7Test() {
  console.log('--- Starting Phase 7 Verification Test (Samurai Rig, HUD, Slash Arcs) ---');
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

  fs.mkdirSync('qa/shots/phase_7', { recursive: true });

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

  // 1. Samurai idle silhouette with scarf
  await page.screenshot({ path: 'qa/shots/phase_7/01_samurai_hero_idle.png' });
  console.log('Saved 01_samurai_hero_idle.png');

  // 2. Weapon swap badge test
  console.log('Testing weapon swap Q badge in HUD...');
  await page.keyboard.press('KeyQ');
  await page.waitForTimeout(300);
  await page.screenshot({ path: 'qa/shots/phase_7/02_weapon_swapped_naginata.png' });
  console.log('Saved 02_weapon_swapped_naginata.png');

  await page.keyboard.press('KeyQ');
  await page.waitForTimeout(300);
  await page.screenshot({ path: 'qa/shots/phase_7/03_weapon_swapped_kunai.png' });
  console.log('Saved 03_weapon_swapped_kunai.png');

  // Swap back to Katana
  await page.keyboard.press('KeyQ');
  await page.waitForTimeout(200);

  // 3. Attack with Katana - check slash arc
  console.log('Testing attack swing and slash arc...');
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(50);
  await page.screenshot({ path: 'qa/shots/phase_7/04_katana_slash_arc.png' });
  console.log('Saved 04_katana_slash_arc.png');

  await page.waitForTimeout(400);

  // 4. Parallax Shoji / background reveal
  console.log('Spawning pulse to check background parallax and shoji geometry...');
  await page.evaluate(() => window.__SL_cmd('spawn_pulse', { tier: 'normal' }));
  await page.waitForTimeout(400);
  await page.screenshot({ path: 'qa/shots/phase_7/05_shoji_parallax_reveal.png' });
  console.log('Saved 05_shoji_parallax_reveal.png');

  await page.waitForTimeout(1000);

  console.log(`\nPhase 7 Errors: ${errors.length}`);
  if (errors.length > 0) {
    console.error('Errors encountered:');
    errors.forEach(e => console.error(' - ', e));
    await browser.close();
    process.exit(1);
  }

  console.log('Phase 7 Verification PASSED with ZERO ERRORS!');
  await browser.close();
}

runPhase7Test().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
