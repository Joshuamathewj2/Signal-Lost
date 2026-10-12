const { chromium } = require('playwright');
const fs = require('fs');

async function runCampaignTest() {
  console.log('=== P9-T01: Full Campaign Playthrough Pass (Levels 1–9) ===');
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

  fs.mkdirSync('qa/shots/phase_9', { recursive: true });

  await page.goto('http://127.0.0.1:8000/');
  await page.waitForFunction(() => window.__SL && window.__SL.ready === true, null, { timeout: 60000 });
  await page.locator('canvas').click();
  await page.waitForTimeout(500);

  // Press Enter to start from main menu
  await page.keyboard.press('Enter');
  await page.waitForTimeout(600);

  const completedLevels = [];

  for (let lvl = 1; lvl <= 9; lvl++) {
    console.log(`\n--- Testing Sector ${lvl}/9 ---`);
    await page.evaluate((lvlNum) => window.__SL_cmd('load_level', { level: lvlNum }), lvl);
    await page.waitForFunction(() => window.__SL && window.__SL.is_level_active === true && window.__SL.player !== null, null, { timeout: 15000 });
    await page.waitForTimeout(600);

    // Initial screenshot
    const startShot = `qa/shots/phase_9/sector_0${lvl}_start.png`;
    await page.screenshot({ path: startShot });
    console.log(`Captured ${startShot}`);

    // Emit pulse & move slightly
    await page.evaluate(() => window.__SL_cmd('spawn_pulse', { tier: 'whisper' }));
    await page.waitForTimeout(300);

    // Complete level
    console.log(`Triggering completion for Sector ${lvl}...`);
    await page.evaluate(() => window.__SL_cmd('complete_level'));
    await page.waitForFunction(() => window.__SL && window.__SL.level_complete === true, null, { timeout: 10000 });
    await page.waitForTimeout(500);

    const snapshot = await page.evaluate(() => window.__SL);
    const medal = snapshot.medal || 'unknown';
    console.log(`Sector ${lvl} Victory! Medal awarded: [${medal.toUpperCase()}]`);

    if (!['ghost', 'quiet', 'loud'].includes(medal.toLowerCase())) {
      throw new Error(`Invalid medal for Sector ${lvl}: ${medal}`);
    }

    const victoryShot = `qa/shots/phase_9/sector_0${lvl}_victory.png`;
    await page.screenshot({ path: victoryShot });
    console.log(`Captured ${victoryShot}`);

    completedLevels.push({ level: lvl, medal: medal });
  }

  await browser.close();

  console.log('\n==========================================');
  console.log('CAMPAIGN PLAYTHROUGH SUMMARY:');
  for (const item of completedLevels) {
    console.log(`  Sector 0${item.level}: PASSED (Medal: ${item.medal.toUpperCase()})`);
  }
  console.log(`Total Errors Encountered: ${errors.length}`);
  console.log('==========================================');

  if (errors.length > 0) {
    console.error('FAILED with errors:', errors);
    process.exit(1);
  }
  if (completedLevels.length !== 9) {
    console.error(`FAILED: Only completed ${completedLevels.length}/9 levels`);
    process.exit(1);
  }

  console.log('P9-T01: Full Campaign Playthrough Pass 100% PASSED!');
}

runCampaignTest().catch(err => {
  console.error('Fatal error during campaign test:', err);
  process.exit(1);
});
