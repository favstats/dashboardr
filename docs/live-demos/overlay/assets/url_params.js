/**
 * URL Deep Linking & Parameterized Dashboards for dashboardr
 *
 * Reads filter state from URL query parameters on page load,
 * updates URL as filters/tabs change, and supports tab deep linking via hash.
 *
 * Query params: ?filterVar=value1,value2&tab=TabName
 * Hash: #TabName or #Parent/Child for nested tabs
 */

(function() {
  'use strict';

  var updateTimer = null;
  var initialized = false;
  // Track whether we are restoring from URL (suppress URL updates during restore)
  var restoring = false;

  // =========================================================
  // Tab Deep Linking (hash-based)
  // =========================================================

  function activateTabFromHash() {
    var hash = window.location.hash;
    if (!hash || hash.length <= 1) return;

    var tabPath = decodeURIComponent(hash.substring(1));
    var parts = tabPath.split('/');

    parts.forEach(function(tabName, depth) {
      // Find all tab elements matching this name
      var tabs = document.querySelectorAll('[role="tab"]');
      for (var i = 0; i < tabs.length; i++) {
        var tab = tabs[i];
        var tabText = (tab.textContent || tab.innerText || '').trim();
        if (tabText === tabName) {
          tab.click();
          break;
        }
      }
    });
  }

  // Update hash when tabs change
  function watchTabChanges() {
    document.addEventListener('click', function(e) {
      var tab = e.target.closest ? e.target.closest('[role="tab"]') : null;
      if (!tab || restoring) return;

      // Build tab path from active tabs (handle nesting)
      setTimeout(function() {
        var activeTabs = document.querySelectorAll('[role="tab"][aria-selected="true"], [role="tab"].active');
        if (activeTabs.length > 0) {
          var names = [];
          activeTabs.forEach(function(t) {
            var text = (t.textContent || t.innerText || '').trim();
            if (text) names.push(text);
          });
          if (names.length > 0) {
            var newHash = '#' + encodeURIComponent(names.join('/'));
            if (window.location.hash !== newHash) {
              history.replaceState(null, '', newHash + window.location.search);
            }
          }
        }
      }, 50);
    });
  }

  // =========================================================
  // Query Parameter Deserialization (page load)
  // =========================================================

  function restoreFromURL() {
    var params;
    try {
      params = new URLSearchParams(window.location.search);
    } catch (e) {
      return; // URLSearchParams not supported
    }

    if (!params || params.toString() === '') return;

    restoring = true;

    params.forEach(function(value, key) {
      // Skip internal params
      if (key === 'dashboardr_debug' || key === 'debug') return;
      // Skip tab param (handled separately via hash)
      if (key === 'tab') {
        // Activate tab by name
        var tabs = document.querySelectorAll('[role="tab"]');
        for (var i = 0; i < tabs.length; i++) {
          var tabText = (tabs[i].textContent || tabs[i].innerText || '').trim();
          if (tabText === value) {
            tabs[i].click();
            break;
          }
        }
        return;
      }

      // Find input by filter_var
      var input = document.querySelector('[data-filter-var="' + key + '"]');
      if (!input) return;

      var inputType = input.dataset.inputType || input.getAttribute('data-input-type') || '';
      var inputId = input.id;

      if (inputType === 'select' || input.tagName === 'SELECT') {
        setSelectValue(input, value);
      } else if (inputType === 'checkbox') {
        setCheckboxValues(input, value.split(','));
      } else if (inputType === 'radio') {
        setRadioValue(input, value);
      } else if (inputType === 'slider') {
        setSliderValue(input, value);
      } else if (inputType === 'date') {
        input.value = value;
        input.dispatchEvent(new Event('change', { bubbles: true }));
      } else if (inputType === 'daterange') {
        var dates = value.split(',');
        var startInput = input.querySelector('[data-role="start"]');
        var endInput = input.querySelector('[data-role="end"]');
        if (startInput && dates[0]) {
          startInput.value = dates[0];
        }
        if (endInput && dates[1]) {
          endInput.value = dates[1];
        }
        if (startInput) startInput.dispatchEvent(new Event('change', { bubbles: true }));
      } else if (inputType === 'button_group') {
        setButtonGroupValue(input, value);
      } else if (inputType === 'number') {
        var numInput = input.querySelector('input[type="number"]') || input;
        numInput.value = value;
        numInput.dispatchEvent(new Event('input', { bubbles: true }));
      } else if (inputType === 'text') {
        var textInput = input.querySelector('input[type="text"]') || input;
        textInput.value = value;
        textInput.dispatchEvent(new Event('input', { bubbles: true }));
      }
    });

    // Trigger a single filter application after all params restored
    setTimeout(function() {
      restoring = false;
      // applyAllFilters is called by individual change events, but we ensure
      // the URL isn't updated during the restore process
    }, 300);
  }

  // Helper: set select value (supports Choices.js)
  function setSelectValue(selectEl, value) {
    var values = value.split(',');
    var choicesInstance = window.dashboardrChoicesInstances &&
                         window.dashboardrChoicesInstances[selectEl.id];

    if (choicesInstance) {
      // Use Choices.js API
      choicesInstance.removeActiveItems();
      choicesInstance.setChoiceByValue(values);
    } else {
      // Native select
      var options = selectEl.querySelectorAll('option');
      options.forEach(function(opt) {
        opt.selected = values.includes(opt.value);
      });
      selectEl.dispatchEvent(new Event('change', { bubbles: true }));
    }
  }

  // Helper: set checkbox values
  function setCheckboxValues(container, values) {
    var checkboxes = container.querySelectorAll('input[type="checkbox"]');
    checkboxes.forEach(function(cb) {
      cb.checked = values.includes(cb.value);
    });
    // Trigger change on last checkbox to trigger filter update
    if (checkboxes.length > 0) {
      checkboxes[checkboxes.length - 1].dispatchEvent(new Event('change', { bubbles: true }));
    }
  }

  // Helper: set radio value
  function setRadioValue(container, value) {
    var radios = container.querySelectorAll('input[type="radio"]');
    radios.forEach(function(r) {
      r.checked = (r.value === value);
    });
    var selected = container.querySelector('input[type="radio"]:checked');
    if (selected) selected.dispatchEvent(new Event('change', { bubbles: true }));
  }

  // Helper: set slider value
  function setSliderValue(sliderEl, value) {
    var rangeInput = sliderEl.querySelector('input[type="range"]') || sliderEl;
    rangeInput.value = value;
    rangeInput.dispatchEvent(new Event('input', { bubbles: true }));
  }

  // Helper: set button group value
  function setButtonGroupValue(container, value) {
    var buttons = container.querySelectorAll('.dashboardr-button-option');
    buttons.forEach(function(btn) {
      btn.classList.toggle('active', btn.dataset.value === value);
    });
    var activeBtn = container.querySelector('.dashboardr-button-option.active');
    if (activeBtn) activeBtn.click();
  }

  // =========================================================
  // Query Parameter Serialization (on filter change)
  // =========================================================

  function serializeToURL() {
    if (restoring) return;

    clearTimeout(updateTimer);
    updateTimer = setTimeout(function() {
      var params = new URLSearchParams();

      // Get inputState from the dashboardr filter system
      // We read DOM state directly to avoid needing a global reference
      var allInputs = document.querySelectorAll('[data-filter-var]');

      allInputs.forEach(function(el) {
        var filterVar = el.dataset.filterVar;
        var inputType = el.dataset.inputType || '';
        if (!filterVar) return;

        var value = '';

        if (inputType === 'select' || el.tagName === 'SELECT') {
          var selected = Array.from(el.selectedOptions || []).map(function(o) { return o.value; });
          // Check Choices.js instance
          var ci = window.dashboardrChoicesInstances && window.dashboardrChoicesInstances[el.id];
          if (ci && ci.getValue) {
            var choiceVals = ci.getValue(true);
            selected = Array.isArray(choiceVals) ? choiceVals : [choiceVals];
          }
          value = selected.join(',');
        } else if (inputType === 'checkbox') {
          var checked = Array.from(el.querySelectorAll('input[type="checkbox"]:checked'));
          value = checked.map(function(c) { return c.value; }).join(',');
        } else if (inputType === 'radio') {
          var checkedRadio = el.querySelector('input[type="radio"]:checked');
          value = checkedRadio ? checkedRadio.value : '';
        } else if (inputType === 'slider') {
          var range = el.querySelector('input[type="range"]') || el;
          value = range.value || '';
        } else if (inputType === 'switch') {
          // Don't serialize switches (they toggle series, not filter values)
          return;
        } else if (inputType === 'date') {
          value = el.value || '';
        } else if (inputType === 'daterange') {
          var s = el.querySelector('[data-role="start"]');
          var e = el.querySelector('[data-role="end"]');
          value = (s ? s.value : '') + ',' + (e ? e.value : '');
          if (value === ',') return; // Both empty
        } else if (inputType === 'button_group') {
          var active = el.querySelector('.dashboardr-button-option.active');
          value = active ? (active.dataset.value || '') : '';
        } else if (inputType === 'number') {
          var numInput = el.querySelector('input[type="number"]') || el;
          value = numInput.value || '';
        } else if (inputType === 'text') {
          var txtInput = el.querySelector('input[type="text"]') || el;
          value = txtInput.value || '';
        }

        if (value) {
          params.set(filterVar, value);
        }
      });

      var newSearch = params.toString();
      var currentUrl = window.location.pathname + window.location.hash;
      if (newSearch) {
        currentUrl = window.location.pathname + '?' + newSearch + window.location.hash;
      }

      try {
        history.replaceState(null, '', currentUrl);
      } catch (e) {
        // Some browsers restrict replaceState
      }
    }, 300); // 300ms debounce
  }

  // =========================================================
  // Initialization
  // =========================================================

  function initUrlParams() {
    if (initialized) return;
    initialized = true;

    // Watch tab changes for hash updates
    watchTabChanges();

    // Listen for filter changes to update URL
    document.addEventListener('dashboardr:filter-changed', serializeToURL);

    // On page load: restore from URL after inputs are initialized
    // Use a delay to ensure inputs are ready
    setTimeout(function() {
      restoreFromURL();
      activateTabFromHash();
    }, 500);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initUrlParams);
  } else {
    initUrlParams();
  }

  // Also run on window load as fallback
  window.addEventListener('load', function() {
    setTimeout(initUrlParams, 100);
  });

})();
