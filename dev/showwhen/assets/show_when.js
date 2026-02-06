/**
 * Conditional visibility (show_when) for dashboardr
 *
 * Elements with data-show-when attribute are shown or hidden based on
 * current input values. Condition is JSON: { var, op, val } or { op, conditions } for and/or.
 */
(function() {
  'use strict';

  // Inject a hiding class that uses !important to override bslib's grid styles
  var styleEl = document.createElement('style');
  styleEl.textContent = '.dashboardr-sw-hidden { display: none !important; height: 0 !important; min-height: 0 !important; overflow: hidden !important; margin: 0 !important; padding: 0 !important; }';
  document.head.appendChild(styleEl);

  // Override bslib's grid row sizing in sidebar layouts so charts aren't squished.
  // CSS !important can't override bslib's inline styles, so we do it via JS.
  function fixChartMinHeight() {
    var minH = getComputedStyle(document.documentElement)
                .getPropertyValue('--chart-min-height').trim() || '400px';
    document.querySelectorAll('.sidebar-content .bslib-grid[style*="grid-template-rows"]')
      .forEach(function(grid) {
        grid.style.setProperty('grid-template-rows', 'none', 'important');
        grid.style.setProperty('grid-auto-rows', 'minmax(' + minH + ', max-content)', 'important');
      });
  }

  function collectInputValues() {
    var values = {};

    // Collect from <select> elements
    document.querySelectorAll('select').forEach(function(el) {
      var id = el.getAttribute('data-input-id') || el.name || el.id;
      if (id) values[id] = el.value;
      // Also map by data-filter-var if present on the element or parent
      var fv = el.getAttribute('data-filter-var');
      if (!fv) {
        var group = el.closest('[data-filter-var]');
        if (group) fv = group.getAttribute('data-filter-var');
      }
      if (fv && el.value) values[fv] = el.value;
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

    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/cbfd47d0-c39e-4a3e-892f-ab3041f60f5c',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'show_when.js:collectInputValues',message:'Collected input values (post-fix)',data:{values:values,keyCount:Object.keys(values).length},timestamp:Date.now(),sessionId:'debug-session',runId:'post-fix',hypothesisId:'H-B'})}).catch(function(){});
    // #endregion
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
    switch (cond.op) {
      case 'eq': return val === cond.val;
      case 'neq': return val !== cond.val;
      case 'in': return Array.isArray(cond.val) && cond.val.indexOf(val) !== -1;
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
    var cards = new Map(); // card DOM node → { total, hidden }
    document.querySelectorAll('[data-show-when]').forEach(function(el) {
      var card = el.closest('.card, .bslib-card');
      if (!card) return;
      if (!cards.has(card)) cards.set(card, { total: 0, hidden: 0 });
      var info = cards.get(card);
      info.total++;
      if (el.classList.contains('dashboardr-sw-hidden')) info.hidden++;
    });

    // #region agent log
    var cardDebug = [];
    cards.forEach(function(info, card) { cardDebug.push({total:info.total,hidden:info.hidden,allHidden:info.hidden===info.total}); });
    fetch('http://127.0.0.1:7242/ingest/cbfd47d0-c39e-4a3e-892f-ab3041f60f5c',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'show_when.js:updateParentContainers',message:'Card visibility summary',data:{cards:cardDebug},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'H-D'})}).catch(function(){});
    // #endregion
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
        if (!children[i].classList.contains('dashboardr-sw-hidden')) {
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

  function evaluateAllShowWhen() {
    var inputs = collectInputValues();
    var elements = document.querySelectorAll('[data-show-when]');
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/cbfd47d0-c39e-4a3e-892f-ab3041f60f5c',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'show_when.js:evaluateAllShowWhen',message:'Evaluating show_when conditions',data:{inputKeys:Object.keys(inputs),inputValues:inputs,elementCount:elements.length},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'H-B'})}).catch(function(){});
    // #endregion

    elements.forEach(function(el) {
      try {
        var condition = JSON.parse(el.getAttribute('data-show-when'));
        var visible = evaluateCondition(condition, inputs);
        // #region agent log
        fetch('http://127.0.0.1:7242/ingest/cbfd47d0-c39e-4a3e-892f-ab3041f60f5c',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'show_when.js:evaluateElement',message:'Condition evaluation result',data:{condition:condition,visible:visible,inputsUsed:inputs},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'H-B'})}).catch(function(){});
        // #endregion
        if (visible) {
          el.classList.remove('dashboardr-sw-hidden');
        } else {
          el.classList.add('dashboardr-sw-hidden');
        }
      } catch (e) {
        console.warn('dashboardr show_when: invalid condition', e);
      }
    });

    // Second pass: hide parent cards whose show-when children are all hidden
    updateParentContainers();
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
})();
