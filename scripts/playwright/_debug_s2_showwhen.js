/**
 * Debug script for S2 pie show_when visibility issue.
 *
 * Problem: show_when condition {"var":"education","op":"neq","val":"Graduate"}
 * doesn't toggle visibility when the education select is changed via Playwright.
 *
 * This script instruments every step so we can see exactly what
 * collectInputValues() returns and whether the change event reaches
 * the show_when evaluator.
 *
 * Usage:
 *   npx playwright test --config=playwright.config.js scripts/playwright/_debug_s2_showwhen.js
 *   -- or simply --
 *   node scripts/playwright/_debug_s2_showwhen.js
 */

const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  // Capture all console messages from the page
  const consoleLogs = [];
  page.on('console', msg => {
    const text = msg.text();
    consoleLogs.push(`[${msg.type()}] ${text}`);
  });

  const htmlPath = 'file:///Users/favstats/Dropbox/dashboardr/dashboardr/sidebar_single_echarts/docs/s2_pie_showwhen.html';
  console.log('=== S2 Pie ShowWhen Debug ===');
  console.log('Opening:', htmlPath);
  await page.goto(htmlPath);
  console.log('Waiting 3s for initialization...');
  await page.waitForTimeout(3000);

  // ─── PHASE 1: Initial state ───────────────────────────────────────
  console.log('\n=== PHASE 1: Initial State (before any change) ===');

  const phase1 = await page.evaluate(() => {
    const result = {};

    // 1) All select elements and their values
    const selects = Array.from(document.querySelectorAll('select'));
    result.selects = selects.map(sel => ({
      id: sel.id,
      name: sel.name,
      filterVar: sel.getAttribute('data-filter-var'),
      inputType: sel.getAttribute('data-input-type'),
      value: sel.value,
      selectedIndex: sel.selectedIndex,
      optionCount: sel.options.length,
      options: Array.from(sel.options).map(o => ({
        value: o.value,
        text: o.text,
        selected: o.selected
      }))
    }));

    // 2) All data-show-when elements and their visibility
    const showWhens = Array.from(document.querySelectorAll('[data-show-when]'));
    result.showWhenElements = showWhens.map(el => {
      const condition = el.getAttribute('data-show-when');
      const cs = window.getComputedStyle(el);
      return {
        condition: condition,
        conditionParsed: JSON.parse(condition),
        classList: Array.from(el.classList),
        hasHiddenClass: el.classList.contains('dashboardr-sw-hidden'),
        computedDisplay: cs.display,
        computedVisibility: cs.visibility,
        offsetWidth: el.offsetWidth,
        offsetHeight: el.offsetHeight,
        isEffectivelyVisible: cs.display !== 'none' && cs.visibility !== 'hidden' && el.offsetWidth > 0
      };
    });

    // 3) Choices.js instances
    const choicesMap = window.dashboardrChoicesInstances || {};
    result.choicesKeys = Object.keys(choicesMap);

    // 4) Education select Choices.js details
    const educationSelect = document.querySelector('select[data-filter-var="education"]');
    result.educationSelectId = educationSelect ? educationSelect.id : null;

    if (educationSelect && choicesMap[educationSelect.id]) {
      const inst = choicesMap[educationSelect.id];
      const val = typeof inst.getValue === 'function' ? inst.getValue(true) : 'N/A';
      // Access internal store safely
      let storeChoices = 'N/A';
      let storeState = 'N/A';
      try {
        if (inst._store) {
          storeChoices = inst._store.choices;
          storeState = inst._store.state ? inst._store.state.choices : 'no state';
        }
      } catch (e) {
        storeChoices = 'error: ' + e.message;
      }

      result.educationChoices = {
        getValueTrue: val,
        storeChoices: storeChoices,
        storeState: storeState
      };
    } else {
      result.educationChoices = {
        found: false,
        selectId: educationSelect ? educationSelect.id : 'no select',
        availableKeys: Object.keys(choicesMap)
      };
    }

    // 5) Simulate what collectInputValues would return by
    //    re-implementing the same logic from show_when.js
    const inputs = {};
    const choicesMapLocal = window.dashboardrChoicesInstances || {};
    document.querySelectorAll('select').forEach(function(el) {
      var id = el.getAttribute('data-input-id') || el.name || el.id;
      var val = el.value;
      if (id && choicesMapLocal[id] && typeof choicesMapLocal[id].getValue === 'function') {
        var choicesVal = choicesMapLocal[id].getValue(true);
        if (choicesVal !== undefined && choicesVal !== null) {
          val = Array.isArray(choicesVal) ? (choicesVal[0] || '') : choicesVal;
        }
      } else if (el.id && choicesMapLocal[el.id] && typeof choicesMapLocal[el.id].getValue === 'function') {
        var choicesVal2 = choicesMapLocal[el.id].getValue(true);
        if (choicesVal2 !== undefined && choicesVal2 !== null) {
          val = Array.isArray(choicesVal2) ? (choicesVal2[0] || '') : choicesVal2;
        }
      }
      if (id) inputs[id] = val;
      var fv = el.getAttribute('data-filter-var');
      if (!fv) {
        var group = el.closest('[data-filter-var]');
        if (group) fv = group.getAttribute('data-filter-var');
      }
      if (fv && val) inputs[fv] = val;
    });
    result.simulatedInputValues = inputs;

    // 6) Evaluate the neq condition manually
    const neqCondition = { var: 'education', op: 'neq', val: 'Graduate' };
    const educationVal = inputs['education'];
    result.manualEval = {
      educationValue: educationVal,
      neqGraduateResult: educationVal !== 'Graduate',
      eqGraduateResult: educationVal === 'Graduate'
    };

    return result;
  });

  console.log('\n--- Select elements ---');
  phase1.selects.forEach(s => {
    console.log(`  id=${s.id}, filterVar=${s.filterVar}, value="${s.value}", options=[${s.options.map(o => `"${o.value}"${o.selected ? '*' : ''}`).join(', ')}]`);
  });

  console.log('\n--- data-show-when elements ---');
  phase1.showWhenElements.forEach((sw, i) => {
    console.log(`  [${i}] condition=${JSON.stringify(sw.conditionParsed)}`);
    console.log(`      hidden-class=${sw.hasHiddenClass}, display=${sw.computedDisplay}, visible=${sw.isEffectivelyVisible}`);
    console.log(`      classes=[${sw.classList.join(', ')}]`);
  });

  console.log('\n--- Choices.js instances ---');
  console.log('  Keys:', phase1.choicesKeys);
  console.log('  Education select id:', phase1.educationSelectId);
  console.log('  Education Choices.js getValue(true):', phase1.educationChoices.getValueTrue);
  if (phase1.educationChoices.storeChoices !== 'N/A') {
    console.log('  Education store.choices:', JSON.stringify(phase1.educationChoices.storeChoices, null, 2));
  }
  if (phase1.educationChoices.storeState !== 'N/A') {
    console.log('  Education store.state.choices:', JSON.stringify(phase1.educationChoices.storeState, null, 2));
  }

  console.log('\n--- Simulated collectInputValues() ---');
  console.log('  ', JSON.stringify(phase1.simulatedInputValues, null, 2));

  console.log('\n--- Manual condition evaluation ---');
  console.log('  education value:', JSON.stringify(phase1.manualEval.educationValue));
  console.log('  neq "Graduate" =>', phase1.manualEval.neqGraduateResult);
  console.log('  eq "Graduate"  =>', phase1.manualEval.eqGraduateResult);

  // ─── PHASE 2: Change education to "Graduate" via Choices.js API ──
  console.log('\n=== PHASE 2: Changing education to "Graduate" via Choices.js API ===');

  const changeResult = await page.evaluate(() => {
    const result = {};
    const educationSelect = document.querySelector('select[data-filter-var="education"]');
    if (!educationSelect) {
      result.error = 'Education select not found';
      return result;
    }

    const choicesMap = window.dashboardrChoicesInstances || {};
    const inst = choicesMap[educationSelect.id];

    result.selectIdUsed = educationSelect.id;
    result.hasChoicesInstance = !!inst;

    if (inst) {
      // Record value before
      result.valueBefore = inst.getValue(true);
      result.nativeValueBefore = educationSelect.value;

      // Change via Choices.js API
      inst.setChoiceByValue('Graduate');

      // Record value immediately after API call
      result.valueAfterApi = inst.getValue(true);
      result.nativeValueAfterApi = educationSelect.value;

      // Check if a native 'change' event was dispatched by checking the
      // show_when elements right now (before manually dispatching)
      const showWhens = Array.from(document.querySelectorAll('[data-show-when]'));
      result.showWhenAfterApiOnly = showWhens.map(el => ({
        condition: JSON.parse(el.getAttribute('data-show-when')),
        hasHiddenClass: el.classList.contains('dashboardr-sw-hidden'),
        computedDisplay: window.getComputedStyle(el).display
      }));
    } else {
      // Fallback: change native select value
      educationSelect.value = 'Graduate';
      result.nativeValueAfterSet = educationSelect.value;
      result.fallbackUsed = true;
    }

    return result;
  });

  console.log('  Select id used:', changeResult.selectIdUsed);
  console.log('  Has Choices instance:', changeResult.hasChoicesInstance);
  if (changeResult.hasChoicesInstance) {
    console.log('  Value before (Choices):', changeResult.valueBefore);
    console.log('  Native value before:', changeResult.nativeValueBefore);
    console.log('  Value after API (Choices):', changeResult.valueAfterApi);
    console.log('  Native value after API:', changeResult.nativeValueAfterApi);
    console.log('  show_when visibility after Choices API (BEFORE manual event):');
    changeResult.showWhenAfterApiOnly.forEach((sw, i) => {
      console.log(`    [${i}] ${JSON.stringify(sw.condition)} => hidden=${sw.hasHiddenClass}, display=${sw.computedDisplay}`);
    });
  } else {
    console.log('  Fallback used:', changeResult.fallbackUsed);
    console.log('  Native value after set:', changeResult.nativeValueAfterSet);
  }

  // Wait 1s for any async event handling
  console.log('\n  Waiting 1s for async event handling...');
  await page.waitForTimeout(1000);

  // ─── PHASE 3: State after waiting ─────────────────────────────────
  console.log('\n=== PHASE 3: State after 1s wait (no manual event dispatch yet) ===');

  const phase3 = await page.evaluate(() => {
    const result = {};

    // Education select current value
    const educationSelect = document.querySelector('select[data-filter-var="education"]');
    const choicesMap = window.dashboardrChoicesInstances || {};
    const inst = educationSelect ? choicesMap[educationSelect.id] : null;

    result.nativeValue = educationSelect ? educationSelect.value : 'N/A';
    result.choicesValue = inst ? inst.getValue(true) : 'N/A';

    // show_when elements
    const showWhens = Array.from(document.querySelectorAll('[data-show-when]'));
    result.showWhenElements = showWhens.map(el => {
      const cs = window.getComputedStyle(el);
      return {
        condition: JSON.parse(el.getAttribute('data-show-when')),
        hasHiddenClass: el.classList.contains('dashboardr-sw-hidden'),
        computedDisplay: cs.display,
        isVisible: cs.display !== 'none' && el.offsetWidth > 0
      };
    });

    // Re-simulate collectInputValues
    const inputs = {};
    document.querySelectorAll('select').forEach(function(el) {
      var id = el.getAttribute('data-input-id') || el.name || el.id;
      var val = el.value;
      if (id && choicesMap[id] && typeof choicesMap[id].getValue === 'function') {
        var choicesVal = choicesMap[id].getValue(true);
        if (choicesVal !== undefined && choicesVal !== null) {
          val = Array.isArray(choicesVal) ? (choicesVal[0] || '') : choicesVal;
        }
      }
      if (id) inputs[id] = val;
      var fv = el.getAttribute('data-filter-var');
      if (!fv) {
        var group = el.closest('[data-filter-var]');
        if (group) fv = group.getAttribute('data-filter-var');
      }
      if (fv && val) inputs[fv] = val;
    });
    result.simulatedInputValues = inputs;

    return result;
  });

  console.log('  Education native value:', phase3.nativeValue);
  console.log('  Education Choices value:', phase3.choicesValue);
  console.log('  Simulated inputs:', JSON.stringify(phase3.simulatedInputValues));
  console.log('  show_when elements:');
  phase3.showWhenElements.forEach((sw, i) => {
    console.log(`    [${i}] ${JSON.stringify(sw.condition)} => hidden=${sw.hasHiddenClass}, display=${sw.computedDisplay}, visible=${sw.isVisible}`);
  });

  // ─── PHASE 4: Manually dispatch change event ─────────────────────
  console.log('\n=== PHASE 4: Manually dispatching native "change" event on select ===');

  await page.evaluate(() => {
    const educationSelect = document.querySelector('select[data-filter-var="education"]');
    if (educationSelect) {
      educationSelect.dispatchEvent(new Event('change', { bubbles: true }));
    }
  });

  // Wait 500ms for the event to propagate
  await page.waitForTimeout(500);

  const phase4 = await page.evaluate(() => {
    const result = {};
    const showWhens = Array.from(document.querySelectorAll('[data-show-when]'));
    result.showWhenElements = showWhens.map(el => {
      const cs = window.getComputedStyle(el);
      return {
        condition: JSON.parse(el.getAttribute('data-show-when')),
        hasHiddenClass: el.classList.contains('dashboardr-sw-hidden'),
        computedDisplay: cs.display,
        isVisible: cs.display !== 'none' && el.offsetWidth > 0
      };
    });

    // Check input values one more time
    const educationSelect = document.querySelector('select[data-filter-var="education"]');
    const choicesMap = window.dashboardrChoicesInstances || {};
    const inst = educationSelect ? choicesMap[educationSelect.id] : null;
    result.nativeValue = educationSelect ? educationSelect.value : 'N/A';
    result.choicesValue = inst ? inst.getValue(true) : 'N/A';

    return result;
  });

  console.log('  Education native value:', phase4.nativeValue);
  console.log('  Education Choices value:', phase4.choicesValue);
  console.log('  show_when elements after manual change event:');
  phase4.showWhenElements.forEach((sw, i) => {
    console.log(`    [${i}] ${JSON.stringify(sw.condition)} => hidden=${sw.hasHiddenClass}, display=${sw.computedDisplay}, visible=${sw.isVisible}`);
  });

  // ─── PHASE 5: Try calling evaluateAllShowWhen if accessible ──────
  console.log('\n=== PHASE 5: Check if evaluateAllShowWhen is globally accessible ===');

  const phase5 = await page.evaluate(() => {
    const result = {};
    result.isGlobal = typeof window.evaluateAllShowWhen === 'function';
    result.isDashboardr = typeof window.dashboardrEvaluateShowWhen === 'function';

    // If not global, try to trigger it via a synthetic document-level change event
    if (!result.isGlobal && !result.isDashboardr) {
      result.note = 'evaluateAllShowWhen is inside IIFE, not globally accessible. Dispatching document-level change.';
      document.dispatchEvent(new Event('change', { bubbles: true }));
    } else if (result.isGlobal) {
      window.evaluateAllShowWhen();
    } else if (result.isDashboardr) {
      window.dashboardrEvaluateShowWhen();
    }

    return result;
  });

  console.log('  window.evaluateAllShowWhen exists:', phase5.isGlobal);
  console.log('  window.dashboardrEvaluateShowWhen exists:', phase5.isDashboardr);
  if (phase5.note) console.log('  Note:', phase5.note);

  await page.waitForTimeout(500);

  // ─── PHASE 6: Final state ─────────────────────────────────────────
  console.log('\n=== PHASE 6: Final State ===');

  const phase6 = await page.evaluate(() => {
    const result = {};
    const educationSelect = document.querySelector('select[data-filter-var="education"]');
    const choicesMap = window.dashboardrChoicesInstances || {};
    const inst = educationSelect ? choicesMap[educationSelect.id] : null;

    result.nativeValue = educationSelect ? educationSelect.value : 'N/A';
    result.choicesValue = inst ? inst.getValue(true) : 'N/A';

    const showWhens = Array.from(document.querySelectorAll('[data-show-when]'));
    result.showWhenElements = showWhens.map(el => {
      const cs = window.getComputedStyle(el);
      return {
        condition: JSON.parse(el.getAttribute('data-show-when')),
        hasHiddenClass: el.classList.contains('dashboardr-sw-hidden'),
        computedDisplay: cs.display,
        isVisible: cs.display !== 'none' && el.offsetWidth > 0
      };
    });

    // Count visible show-when blocks
    result.visibleCount = result.showWhenElements.filter(sw => sw.isVisible).length;
    result.totalCount = result.showWhenElements.length;

    return result;
  });

  console.log('  Education native value:', phase6.nativeValue);
  console.log('  Education Choices value:', phase6.choicesValue);
  console.log(`  Visible show_when blocks: ${phase6.visibleCount}/${phase6.totalCount}`);
  phase6.showWhenElements.forEach((sw, i) => {
    console.log(`    [${i}] ${JSON.stringify(sw.condition)} => hidden=${sw.hasHiddenClass}, display=${sw.computedDisplay}, visible=${sw.isVisible}`);
  });

  // ─── Summary ──────────────────────────────────────────────────────
  console.log('\n=== SUMMARY ===');
  const eqBlock = phase6.showWhenElements.find(sw => sw.condition.op === 'eq');
  const neqBlock = phase6.showWhenElements.find(sw => sw.condition.op === 'neq');
  console.log(`  Education value is now: "${phase6.choicesValue}"`);
  console.log(`  eq "Graduate" block:  visible=${eqBlock ? eqBlock.isVisible : 'N/A'} (expected: true)`);
  console.log(`  neq "Graduate" block: visible=${neqBlock ? neqBlock.isVisible : 'N/A'} (expected: false)`);

  if (eqBlock && eqBlock.isVisible && neqBlock && !neqBlock.isVisible) {
    console.log('  RESULT: show_when is working correctly after manual change event dispatch.');
  } else {
    console.log('  RESULT: show_when toggle FAILED. Likely causes:');
    console.log('    1. Choices.js setChoiceByValue() does not fire native "change" event');
    console.log('    2. show_when.js evaluateAllShowWhen() is not triggered');
    console.log('    3. collectInputValues() reads stale value from native select');
  }

  // Print any console messages from the page
  if (consoleLogs.length > 0) {
    console.log('\n=== Browser Console Messages ===');
    consoleLogs.forEach(msg => console.log('  ' + msg));
  }

  await browser.close();
  console.log('\nDone.');
})();
