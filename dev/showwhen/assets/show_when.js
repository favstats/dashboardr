/**
 * Conditional visibility (show_when) for dashboardr
 *
 * Elements with data-show-when attribute are shown or hidden based on
 * current input values. Condition is JSON: { var, op, val } or { op, conditions } for and/or.
 */
(function() {
  'use strict';

  var debugState = window.dashboardrDebugState = window.dashboardrDebugState || { events: [] };
  function isDebugEnabled() {
    if (window.DASHBOARDR_DEBUG === true || window.dashboardrDebug === true) return true;
    try {
      if (window.localStorage && window.localStorage.getItem('dashboardr_debug') === '1') return true;
    } catch (e) {
      // ignore localStorage errors
    }
    try {
      var qs = new URLSearchParams(window.location.search || '');
      if (qs.get('dashboardr_debug') === '1' || qs.get('debug') === '1') return true;
    } catch (e) {
      // ignore URL parsing errors
    }
    return false;
  }
  function debugLog(event, payload) {
    if (!isDebugEnabled()) return;
    var row = { ts: Date.now(), event: event, payload: payload || null };
    debugState.events.push(row);
    if (debugState.events.length > 1000) debugState.events.shift();
    try {
      console.log('[dashboardr:debug]', event, payload || {});
    } catch (e) {
      // no-op
    }
  }

  // Inject hiding helpers that use !important to override bslib's grid styles.
  // Includes an explicit rule for Quarto/bslib "hidden" filler nodes that can
  // otherwise reserve full grid rows.
  var styleEl = document.createElement('style');
  styleEl.textContent = ''
    + '.dashboardr-sw-hidden { display: none !important; height: 0 !important; min-height: 0 !important; overflow: hidden !important; margin: 0 !important; padding: 0 !important; }'
    + '.bslib-grid > .hidden.html-fill-item.html-fill-container { display: none !important; height: 0 !important; min-height: 0 !important; overflow: hidden !important; margin: 0 !important; padding: 0 !important; }';
  document.head.appendChild(styleEl);

  function hasVizContent(node) {
    if (!node || typeof node.querySelector !== 'function') return false;
    return !!node.querySelector(
      '.html-widget, .js-plotly-plot, .echarts4r, .echarts, .highcharts-container, [id^="htmlwidget-"]'
    );
  }

  function collapseGridFillers() {
    document
      .querySelectorAll('.bslib-grid > .hidden.html-fill-item.html-fill-container')
      .forEach(function(el) {
        el.classList.add('dashboardr-sw-hidden');
      });
  }

  function collapseMarkerCards() {
    document.querySelectorAll('[id^="pw-sidebar-marker-"]').forEach(function(marker) {
      var card = marker.closest('.card, .bslib-card');
      if (!card) return;
      var hasViz = !!card.querySelector(
        '.html-widget, .js-plotly-plot, .echarts4r, .echarts, .highcharts-container, [id^="htmlwidget-"]'
      );
      if (!hasViz) {
        card.classList.add('dashboardr-sw-hidden');
        var rowGrid = card.closest('.bslib-grid');
        if (rowGrid && rowGrid.children.length === 1) {
          rowGrid.classList.add('dashboardr-sw-hidden');
        }
      }
    });
  }

  // Override bslib's grid row sizing in sidebar layouts so charts aren't squished.
  // CSS !important can't override bslib's inline styles, so we do it via JS.
  function fixChartMinHeight() {
    var minH = getComputedStyle(document.documentElement)
                .getPropertyValue('--chart-min-height').trim() || '400px';
    document.querySelectorAll('.sidebar-content .bslib-grid[style*="grid-template-rows"]')
      .forEach(function(grid) {
        // Skip non-visualization grids.
        if (!hasVizContent(grid)) return;
        // Skip mixed-content grids (text/markers + chart rows), otherwise
        // forcing min-height on auto-rows creates large empty cards above charts.
        var children = Array.from(grid.children || []);
        if (children.length > 1) {
          var hasVisibleNonVizChild = children.some(function(child) {
            var hiddenByClass = child.classList && child.classList.contains('dashboardr-sw-hidden');
            var hiddenAttr = child.hasAttribute && child.hasAttribute('hidden');
            var hiddenFiller = child.classList &&
              child.classList.contains('hidden') &&
              child.children &&
              child.children.length === 0 &&
              String(child.textContent || '').trim() === '';
            if (hiddenByClass || hiddenAttr || hiddenFiller) return false;
            return !hasVizContent(child);
          });
          if (hasVisibleNonVizChild) return;
        }
        grid.style.setProperty('grid-template-rows', 'none', 'important');
        grid.style.setProperty('grid-auto-rows', 'minmax(' + minH + ', max-content)', 'important');
      });
  }

  function collectInputValues() {
    var values = {};

    // Collect from <select> elements (Choices.js-aware)
    var choicesMap = window.dashboardrChoicesInstances || {};
    document.querySelectorAll('select').forEach(function(el) {
      var id = el.getAttribute('data-input-id') || el.name || el.id;
      // Read value from Choices.js instance if available (native select may be stale)
      var val = el.value;
      if (id && choicesMap[id] && typeof choicesMap[id].getValue === 'function') {
        var choicesVal = choicesMap[id].getValue(true);
        if (choicesVal !== undefined && choicesVal !== null) {
          val = Array.isArray(choicesVal) ? (choicesVal[0] || '') : choicesVal;
        }
      } else if (el.id && choicesMap[el.id] && typeof choicesMap[el.id].getValue === 'function') {
        var choicesVal2 = choicesMap[el.id].getValue(true);
        if (choicesVal2 !== undefined && choicesVal2 !== null) {
          val = Array.isArray(choicesVal2) ? (choicesVal2[0] || '') : choicesVal2;
        }
      }
      if (id) values[id] = val;
      // Also map by data-filter-var if present on the element or parent
      var fv = el.getAttribute('data-filter-var');
      if (!fv) {
        var group = el.closest('[data-filter-var]');
        if (group) fv = group.getAttribute('data-filter-var');
      }
      if (fv && val) values[fv] = val;
    });

    // Collect from checked radio buttons
    document.querySelectorAll('input[type="radio"]:checked').forEach(function(el) {
      var id = el.getAttribute('data-input-id') || el.name || el.id;
      if (id) values[id] = el.value;
      // Also resolve filter_var from the parent radio group container
      var group = el.closest('[data-filter-var]');
      if (group) {
        var fv = group.getAttribute('data-filter-var');
        if (fv && el.value) values[fv] = el.value;
      }
    });

    // Collect from checkbox groups (multi-select semantics)
    document.querySelectorAll('.dashboardr-checkbox-group[data-filter-var]').forEach(function(group) {
      var fv = group.getAttribute('data-filter-var');
      if (!fv) return;
      var selected = Array.from(group.querySelectorAll('input[type="checkbox"]:checked'))
        .map(function(el) { return el.value; })
        .filter(function(v) { return String(v || '') !== ''; });
      values[fv] = selected;
    });

    // Collect from button groups
    document.querySelectorAll('.dashboardr-button-group[data-filter-var]').forEach(function(group) {
      var fv = group.getAttribute('data-filter-var');
      if (!fv) return;
      var active = group.querySelector('.dashboardr-button-option.active');
      if (active) {
        var btnVal = active.getAttribute('data-value') || active.value;
        if (btnVal != null) values[fv] = btnVal;
      }
    });

    // Collect from non-radio/checkbox inputs (slider, text, number, etc.)
    document.querySelectorAll('input[data-filter-var], textarea[data-filter-var]').forEach(function(el) {
      var fv = el.getAttribute('data-filter-var');
      if (!fv) return;
      var type = String(el.type || '').toLowerCase();
      if (type === 'radio' || type === 'checkbox') return;
      values[fv] = el.value;
    });

    return values;
  }

  function evaluateCondition(cond, inputs) {
    if (cond.op === 'and') {
      return cond.conditions.every(function(c) { return evaluateCondition(c, inputs); });
    }
    if (cond.op === 'or') {
      return cond.conditions.some(function(c) { return evaluateCondition(c, inputs); });
    }
    if (cond.op === 'not') {
      return !evaluateCondition(cond.condition, inputs);
    }
    var val = inputs[cond.var];
    // Try numeric comparison for gt/lt/gte/lte operators
    var numVal = parseFloat(val);
    var numCond = parseFloat(cond.val);
    var valueIsArray = Array.isArray(val);
    var condIsArray = Array.isArray(cond.val);
    switch (cond.op) {
      case 'eq':
        if (valueIsArray) return val.indexOf(cond.val) !== -1;
        return val === cond.val;
      case 'neq':
        if (valueIsArray) return val.indexOf(cond.val) === -1;
        return val !== cond.val;
      case 'in':
        if (valueIsArray && condIsArray) return val.some(function(v) { return cond.val.indexOf(v) !== -1; });
        if (condIsArray) return cond.val.indexOf(val) !== -1;
        return false;
      case 'gt': return !isNaN(numVal) && !isNaN(numCond) && numVal > numCond;
      case 'lt': return !isNaN(numVal) && !isNaN(numCond) && numVal < numCond;
      case 'gte': return !isNaN(numVal) && !isNaN(numCond) && numVal >= numCond;
      case 'lte': return !isNaN(numVal) && !isNaN(numCond) && numVal <= numCond;
      default: return true;
    }
  }

  /**
   * Hide/show parent card containers based on whether their show-when
   * descendants are all hidden.  Only hides the NEAREST card ancestor
   * of each show-when element — never shared layout grids.
   */
  function updateParentContainers() {
    // Collect all cards that contain at least one show-when element
    var cards = new Map(); // card DOM node -> { total, hidden }
    document.querySelectorAll('[data-show-when]').forEach(function(el) {
      var card = el.closest('.card, .bslib-card');
      if (!card) return;
      if (!cards.has(card)) cards.set(card, { total: 0, hidden: 0 });
      var info = cards.get(card);
      info.total++;
      if (el.classList.contains('dashboardr-sw-hidden')) info.hidden++;
    });

    cards.forEach(function(info, card) {
      // Hide the card only when ALL its show-when children are hidden
      var allHidden = info.hidden === info.total;
      if (allHidden) {
        card.classList.add('dashboardr-sw-hidden');
      } else {
        card.classList.remove('dashboardr-sw-hidden');
      }
    });

    // Second pass: propagate hiding to .bslib-grid wrappers.
    // Quarto nests each card section in its own .bslib-grid div.
    // Walk all .bslib-grid elements (bottom-up order) and hide any
    // whose child elements are all hidden.
    var grids = Array.from(document.querySelectorAll('.bslib-grid'));
    // Process innermost grids first so hiding propagates outward
    grids.reverse();
    grids.forEach(function(grid) {
      // Skip grids that are major layout containers
      if (grid.classList.contains('sidebar-content') ||
          grid.classList.contains('sidebar-layout')) return;

      var children = grid.children;
      if (children.length === 0) return;
      var allChildrenHidden = true;
      for (var i = 0; i < children.length; i++) {
        var child = children[i];
        var hiddenByClass = child.classList.contains('dashboardr-sw-hidden');
        var hiddenAttr = child.hasAttribute('hidden');
        var hiddenFiller = child.classList.contains('hidden') &&
          child.children.length === 0 &&
          String(child.textContent || '').trim() === '';
        if (!(hiddenByClass || hiddenAttr || hiddenFiller)) {
          allChildrenHidden = false;
          break;
        }
      }
      if (allChildrenHidden) {
        grid.classList.add('dashboardr-sw-hidden');
      } else {
        grid.classList.remove('dashboardr-sw-hidden');
      }
    });
  }

  /**
   * Force Highcharts charts inside newly-visible containers to recalculate
   * their dimensions. Charts rendered inside display:none containers
   * initialize with zero width/height and must be reflowed.
   */
  function reflowVisibleCharts() {
    if (typeof Highcharts !== 'undefined' && Highcharts.charts) {
      Highcharts.charts.forEach(function(chart) {
        if (!chart || !chart.renderTo) return;
        // Only reflow charts whose container is currently visible
        var container = chart.renderTo;
        if (container.offsetWidth > 0 || container.offsetHeight > 0) {
          try {
            chart.reflow();
          } catch(e) { /* ignore reflow errors on destroyed charts */ }
        }
      });
    }
    if (typeof echarts !== 'undefined' && typeof echarts.getInstanceByDom === 'function') {
      document.querySelectorAll('.echarts4r, .echarts, [id^="htmlwidget-"]').forEach(function(el) {
        var inst = echarts.getInstanceByDom(el);
        if (!inst) return;
        if (el.offsetWidth > 0 || el.offsetHeight > 0) {
          try {
            inst.resize();
          } catch (e) { /* ignore resize errors */ }
        }
      });
    }
    if (typeof Plotly !== 'undefined' && Plotly.Plots && typeof Plotly.Plots.resize === 'function') {
      document.querySelectorAll('.js-plotly-plot').forEach(function(el) {
        if (el.offsetWidth > 0 || el.offsetHeight > 0) {
          try {
            Plotly.Plots.resize(el);
          } catch (e) { /* ignore resize errors */ }
        }
      });
    }
  }

  function evaluateAllShowWhen() {
    var inputs = collectInputValues();
    var elements = document.querySelectorAll('[data-show-when]');
    var beforeVisible = 0;
    elements.forEach(function(el) {
      if (!el.classList.contains('dashboardr-sw-hidden')) beforeVisible++;
    });

    elements.forEach(function(el) {
      try {
        var condition = JSON.parse(el.getAttribute('data-show-when'));
        var visible = evaluateCondition(condition, inputs);
        if (visible) {
          el.classList.remove('dashboardr-sw-hidden');
        } else {
          el.classList.add('dashboardr-sw-hidden');
        }
      } catch (e) {
        console.warn('dashboardr show_when: invalid condition', e);
      }
    });

    // First collapse filler nodes that should never consume layout space.
    collapseGridFillers();
    // Collapse marker-only cards used by Playwright smoke checks.
    collapseMarkerCards();

    // Second pass: hide parent cards whose show-when children are all hidden
    updateParentContainers();

    // Third pass: resize charts that just became visible
    // Use requestAnimationFrame to ensure DOM has updated layout first
    requestAnimationFrame(function() {
      reflowVisibleCharts();
    });

    var afterVisible = 0;
    elements.forEach(function(el) {
      if (!el.classList.contains('dashboardr-sw-hidden')) afterVisible++;
    });
    debugLog('show-when-evaluated', {
      inputs: inputs,
      elements: elements.length,
      beforeVisible: beforeVisible,
      afterVisible: afterVisible
    });
  }

  document.addEventListener('change', evaluateAllShowWhen);
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      evaluateAllShowWhen();
      fixChartMinHeight();
    });
  } else {
    evaluateAllShowWhen();
    fixChartMinHeight();
  }
  // Re-run after short delay for async-rendered charts and bslib init
  setTimeout(function() { evaluateAllShowWhen(); fixChartMinHeight(); }, 500);
  setTimeout(function() { evaluateAllShowWhen(); fixChartMinHeight(); }, 2000);
  window.addEventListener('load', function() {
    evaluateAllShowWhen();
    fixChartMinHeight();
  });

  window.dashboardrShowWhenDebug = {
    enabled: isDebugEnabled,
    collectInputValues: collectInputValues,
    evaluate: evaluateAllShowWhen
  };
})();
