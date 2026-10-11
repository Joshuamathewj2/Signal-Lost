const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function runGateB() {
  console.log('--- Starting Gate B Automated Test (Pulse Verification) ---');
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

  // Load Level 1
  console.log('Starting Level 1...');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(500);
  await page.evaluate(() => window.__SL_cmd && window.__SL_cmd('load_level', { level: 1 }));

  console.log('Waiting for player spawn in Level 1...');
  await page.waitForFunction(() => window.__SL && window.__SL.player !== null, null, { timeout: 15000 });
  await page.waitForTimeout(500);

  fs.mkdirSync('qa/shots/gate_b', { recursive: true });

  const tiers = [
    { name: 'whisper', label: 'Whisper' },
    { name: 'normal', label: 'Normal' },
    { name: 'scream', label: 'Scream' }
  ];

  for (const tier of tiers) {
    console.log(`\n=== Testing Tier: ${tier.label} ===`);
    // Allow state to settle
    await page.waitForTimeout(1000);

    // Fire pulse
    await page.evaluate(t => window.__SL_cmd('spawn_pulse', { tier: t }), tier.name);

    // t = 0.1s (leading edge expanding)
    await page.waitForTimeout(100);
    const p1 = `qa/shots/gate_b/${tier.name}_01.png`;
    await page.screenshot({ path: p1 });
    console.log(`Saved ${p1} (t = 0.1s)`);

    // t = 0.5s (full expansion, occlusion shadows)
    await page.waitForTimeout(400); // 100 + 400 = 500ms
    const p2 = `qa/shots/gate_b/${tier.name}_02.png`;
    await page.screenshot({ path: p2 });
    console.log(`Saved ${p2} (t = 0.5s)`);

    // t = 2.0s (decay / echo persistence)
    await page.waitForTimeout(1500); // 500 + 1500 = 2000ms
    const p3 = `qa/shots/gate_b/${tier.name}_03.png`;
    await page.screenshot({ path: p3 });
    console.log(`Saved ${p3} (t = 2.0s)`);

    // Wait extra time for pulse to clear completely before next tier
    await page.waitForTimeout(1500);
  }

  // Also test native user input Space hold and release (keyboard pulse)
  console.log('\n=== Testing Native Keyboard Input Pulse (Space charge & release) ===');
  await page.keyboard.down('Space');
  await page.waitForTimeout(600); // Hold for normal tier
  await page.keyboard.up('Space');
  await page.waitForTimeout(200);
  await page.screenshot({ path: 'qa/shots/gate_b/keyboard_space_pulse.png' });
  console.log('Saved keyboard_space_pulse.png');

  await page.waitForTimeout(1500);

  const snapshot = await page.evaluate(() => window.__SL);
  console.log('\n--- Final Snapshot ---', JSON.stringify(snapshot));

  console.log(`\nTotal Errors Recorded: ${errors.length}`);
  if (errors.length > 0) {
    console.error('Errors encountered:');
    errors.forEach(e => console.error(' - ', e));
    await browser.close();
    process.exit(1);
  }

  console.log('Gate B test completed with ZERO ERRORS!');
  await browser.close();
}

runGateB().catch(err => {
  console.error('Fatal test error:', err);
  process.exit(1);
});
