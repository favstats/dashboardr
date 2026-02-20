/**
 * Interactive Input Filter System for dashboardr
 * ================================================
 *
 * The largest JS file in dashboardr. Handles ALL client-side input
 * interactions: initialising inputs, tracking state, and updating
 * charts/tables when filters change.
 *
 * ## Supported Input Types
 *
 * - Select dropdowns (single/multiple) via Choices.js
 * - Checkboxes (multiple selection)
 * - Radio buttons (single selection)
 * - Switches/toggles (boolean with optional series toggle)
 * - Sliders (numeric range with optional custom labels)
 * - Text search (partial match filtering)
 * - Number inputs (precise numeric filtering)
 * - Button groups (segmented controls)
 * - Date / date-range inputs
 *
 * ## File Structure (major sections)
 *
 *   Lines ~50-100    Global state, helpers, debug
 *   Lines ~107-700   Input initialisation (one init* function per type)
 *   Lines ~700-880   Lazy cross-tab data fetching (asset mode)
 *   Lines ~880-1550  applyAllFilters() — Highcharts cross-tab filtering
 *   Lines ~1556-1750 Plotly / ECharts / table filtering
 *   Lines ~1800-1960 Dynamic titles, select/clear all, reset
 *   Lines ~1960-3980 Cross-tab filtering engine (series-based, grouped,
 *                    stacked, scatter, boxplot, heatmap, etc.)
 *   Lines ~3980-4060 Bootstrap: init, event listeners, public API
 *
 * ## Event Flow
 *
 *   User clicks input → init*() handler fires
 *     → updates inputState[filterVar]
 *     → calls applyAllFilters()
 *       → for each chart in registry:
 *           store original data if not stored
 *           filter cross-tab JSON by current inputState
 *           update Highcharts series/categories
 *       → dispatches 'dashboardr:filter-changed' event
 *       → dispatches standard 'change' event (for show_when.js)
 *
 * ## Public API
 *
 *   window.dashboardrInputs.init()          — re-initialise inputs
 *   window.dashboardrInputs.applyFilters()  — force filter re-apply
 *   window.dashboardrInputs.reapply()       — reapply after DOM change
 *   window.dashboardrInputs.resetFilters(btn) — reset to defaults
 *   window.dashboardrInputs.state           — current filter state
 *   window.dashboardrInputs.defaults        — default filter values
 *   window.dashboardrInputs.choices          — Choices.js instances
 *
 *   window.dashboardrInputDebug.getState()   — snapshot of filter state
 *   window.dashboardrInputDebug.getCharts()  — registered chart entries
 */

(function() {
  'use strict';

  // Global state
  window.dashboardrChoicesInstances = window.dashboardrChoicesInstances || {};
  const choicesInstances = window.dashboardrChoicesInstances;
  const inputState = {};
  const defaultValues = {};  // Store default values for reset

  // Quarto sidebar code triggers jQuery events during collapse transitions.
  // Provide a tiny fallback when jQuery is not present to avoid runtime errors.
  if (typeof window.$ === 'undefined') {
    window.$ = function(node) {
      return {
        trigger: function(eventName) {
          if (!node || !eventName) return;
          try {
            node.dispatchEvent(new CustomEvent(String(eventName), { bubbles: true }));
          } catch (e) {
            // no-op
          }
        }
      };
    };
  }
  
  // Store original data for restoration
  const originalSeriesData = new WeakMap();
  const chartRegistry = window.dashboardrChartRegistry || null;
  const debugState = window.dashboardrDebugState = window.dashboardrDebugState || { events: [] };

  function isDebugEnabled() {
    if (window.DASHBOARDR_DEBUG === true || window.dashboardrDebug === true) return true;
    try {
      if (window.localStorage && window.localStorage.getItem('dashboardr_debug') === '1') return true;
    } catch (e) {
      // ignore localStorage errors
    }
    try {
      const qs = new URLSearchParams(window.location.search || '');
      if (qs.get('dashboardr_debug') === '1' || qs.get('debug') === '1') return true;
    } catch (e) {
      // ignore URL parsing errors
    }
    return false;
  }

  function debugLog(event, payload) {
    if (!isDebugEnabled()) return;
    const row = {
      ts: Date.now(),
      event: event,
      payload: payload || null
    };
    debugState.events.push(row);
    if (debugState.events.length > 1000) debugState.events.shift();
    try {
      console.log('[dashboardr:debug]', event, payload || {});
    } catch (e) {
      // no-op
    }
  }

  function debugInputState(inputId, source) {
    if (!isDebugEnabled()) return;
    const st = inputState[inputId];
    if (!st) {
      debugLog('input-missing-state', { inputId: inputId, source: source });
      return;
    }
    debugLog('input-change', {
      source: source,
      inputId: inputId,
      filterVar: st.filterVar,
      inputType: st.inputType,
      selected: Array.isArray(st.selected) ? st.selected.slice() : st.selected,
      value: Object.prototype.hasOwnProperty.call(st, 'value') ? st.value : null
    });
  }

  function getChartEntries() {
    if (chartRegistry && typeof chartRegistry.getCharts === 'function') {
      return chartRegistry.getCharts();
    }
    return [];
  }

  // =================================================================
  // Input Initialisation
  // =================================================================
  // One init* function per input type. Each:
  //   1. Finds all DOM elements for that input type
  //   2. Reads the data-filter-var and data-default-value attributes
  //   3. Stores the initial value in inputState and defaultValues
  //   4. Attaches event listeners that call applyAllFilters() on change
  // =================================================================

  function initDashboardrInputs() {
    const hasChoices = typeof Choices !== 'undefined';
    debugLog('init-start', {
      hasChoices: hasChoices,
      existingChartEntries: getChartEntries().map(function(e) {
        return { id: e.id, backend: e.backend, x: e.x, filterVars: e.filterVars };
      })
    });
    
    if (!hasChoices) {
      console.warn('Choices.js not loaded - using native HTML for selects');
    }

    // Initialize SELECT inputs
    initSelectInputs(hasChoices);
    
    // Initialize CHECKBOX groups
    initCheckboxInputs();
    
    // Initialize RADIO groups
    initRadioInputs();
    
    // Initialize SWITCH inputs
    initSwitchInputs();
    
    // Initialize SLIDER inputs
    initSliderInputs();
    
    // Initialize TEXT inputs
    initTextInputs();
    
    // Initialize NUMBER inputs
    initNumberInputs();
    
    // Initialize BUTTON GROUP inputs
    initButtonGroupInputs();

    // Initialize DATE inputs
    initDateInputs();

    // Initialize DATERANGE inputs
    initDaterangeInputs();

    // Note: storeOriginalData and applyAllFilters are called by waitForChartsAndApply
    // after charts are fully loaded to avoid flickering
  }

  /**
   * Initialize SELECT dropdowns
   */
  function initSelectInputs(hasChoices) {
    const selects = document.querySelectorAll('.dashboardr-input[data-input-type="select"], select.dashboardr-input');

    selects.forEach(input => {
      const inputId = input.id;
      
      if (input.dataset.dashboardrInitialized === 'true') {
        return;
      }

      const filterVar = input.dataset.filterVar;
      if (!filterVar) {
        console.warn(`Input ${inputId} missing data-filter-var`);
        return;
      }

      input.dataset.dashboardrInitialized = 'true';

      if (hasChoices && input.tagName === 'SELECT') {
        try {
          const isMultiple = input.multiple;
          const choices = new Choices(input, {
            allowHTML: false,
            removeItemButton: isMultiple,
            searchEnabled: true,
            searchPlaceholderValue: 'Search...',
            placeholderValue: input.dataset.placeholder || 'Select...',
            itemSelectText: '',
            noResultsText: 'No results found',
            noChoicesText: 'No options available',
            shouldSort: false,
            searchResultLimit: 100,
            renderChoiceLimit: -1,
            classNames: {
              containerOuter: 'choices dashboardr-choices' + (isMultiple ? '' : ' single-select')
            }
          });
          choicesInstances[inputId] = choices;
          // Choices.js may not fire native 'change' on the select; listen on the instance if available
          if (typeof choices.addEventListener === 'function') {
            choices.addEventListener('change', () => {
              const selected = getSelectedValues(input);
              inputState[inputId].selected = selected;
              debugInputState(inputId, 'select-choices-change');
              applyAllFilters();
            });
          }
        } catch (e) {
          console.error(`Failed to initialize Choices.js for ${inputId}:`, e);
        }
      } else if (!hasChoices && input.tagName === 'SELECT' && input.multiple) {
        enhanceNativeMultiSelect(input);
      }

      const selected = getSelectedValues(input);
      inputState[inputId] = {
        filterVar,
        inputType: 'select',
        selected: selected
      };
      
      // Store default for reset
      defaultValues[inputId] = { selected: selected.slice() };

      input.addEventListener('change', () => {
        const selected = getSelectedValues(input);
        inputState[inputId].selected = selected;
        debugInputState(inputId, 'select-native-change');
        applyAllFilters();
      });
    });
  }

  /**
   * Initialize CHECKBOX groups
   */
  function initCheckboxInputs() {
    const checkboxGroups = document.querySelectorAll('.dashboardr-checkbox-group');
    
    checkboxGroups.forEach(group => {
      const inputId = group.id;
      
      if (group.dataset.dashboardrInitialized === 'true') {
        return;
      }
      
      const filterVar = group.dataset.filterVar;
      if (!filterVar) {
        console.warn(`Checkbox group ${inputId} missing data-filter-var`);
        return;
      }
      
      group.dataset.dashboardrInitialized = 'true';
      
      const selected = getCheckboxValues(group);
      inputState[inputId] = {
        filterVar,
        inputType: 'checkbox',
        selected: selected
      };
      
      // Store default for reset
      defaultValues[inputId] = { selected: selected.slice() };
      
      // Listen to all checkboxes in the group
      const checkboxes = group.querySelectorAll('input[type="checkbox"]');
      checkboxes.forEach(cb => {
        cb.addEventListener('change', () => {
          inputState[inputId].selected = getCheckboxValues(group);
          debugInputState(inputId, 'checkbox-change');
          applyAllFilters();
        });
      });
    });
  }

  /**
   * Initialize RADIO groups
   */
  function initRadioInputs() {
    const radioGroups = document.querySelectorAll('.dashboardr-radio-group');
    
    radioGroups.forEach(group => {
      const inputId = group.id;
      
      if (group.dataset.dashboardrInitialized === 'true') {
        return;
      }
      
      const filterVar = group.dataset.filterVar;
      if (!filterVar) {
        console.warn(`Radio group ${inputId} missing data-filter-var`);
        return;
      }
      
      group.dataset.dashboardrInitialized = 'true';
      
      const selected = getRadioValue(group);
      inputState[inputId] = {
        filterVar,
        inputType: 'radio',
        selected: selected
      };
      
      // Store default for reset
      defaultValues[inputId] = { selected: selected.slice() };
      
      // Listen to all radios in the group
      const radios = group.querySelectorAll('input[type="radio"]');
      radios.forEach(radio => {
        radio.addEventListener('change', () => {
          inputState[inputId].selected = getRadioValue(group);
          debugInputState(inputId, 'radio-change');
          applyAllFilters();
        });
      });
    });
  }

  /**
   * Initialize SWITCH/toggle inputs
   */
  function initSwitchInputs() {
    const switches = document.querySelectorAll('input[data-input-type="switch"]');
    
    switches.forEach(input => {
      const inputId = input.id;
      
      if (input.dataset.dashboardrInitialized === 'true') {
        return;
      }
      
      const filterVar = input.dataset.filterVar;
      if (!filterVar) {
        console.warn(`Switch ${inputId} missing data-filter-var`);
        return;
      }
      
      input.dataset.dashboardrInitialized = 'true';
      
      // Check for toggle-series attribute (specifies which series to show/hide)
      const toggleSeries = input.dataset.toggleSeries || null;
      // Check for override attribute (if true, switch overrides other filters)
      const override = input.dataset.override === 'true';
      
      inputState[inputId] = {
        filterVar,
        inputType: 'switch',
        selected: input.checked ? ['true'] : ['false'],
        value: input.checked,
        toggleSeries: toggleSeries,
        override: override
      };
      
      // Store default for reset
      defaultValues[inputId] = { value: input.checked };
      
      input.addEventListener('change', () => {
        inputState[inputId].selected = input.checked ? ['true'] : ['false'];
        inputState[inputId].value = input.checked;
        debugInputState(inputId, 'switch-change');
        applyAllFilters();
      });
    });
  }

  /**
   * Initialize SLIDER inputs
   */
  function initSliderInputs() {
    const sliders = document.querySelectorAll('input[data-input-type="slider"]');
    
    sliders.forEach(input => {
      const inputId = input.id;
      
      if (input.dataset.dashboardrInitialized === 'true') {
        return;
      }
      
      const filterVar = input.dataset.filterVar;
      if (!filterVar) {
        console.warn(`Slider ${inputId} missing data-filter-var`);
        return;
      }
      
      input.dataset.dashboardrInitialized = 'true';
      
      const value = parseFloat(input.value);
      const min = parseFloat(input.min);
      const max = parseFloat(input.max);
      const step = parseFloat(input.step) || 1;
      
      // Parse custom labels if provided
      let labels = null;
      if (input.dataset.labels) {
        try {
          labels = JSON.parse(input.dataset.labels);
        } catch (e) {
          console.warn(`Failed to parse slider labels for ${inputId}:`, e);
        }
      }
      
      inputState[inputId] = {
        filterVar,
        inputType: 'slider',
        selected: [input.value],
        value: value,
        min: min,
        max: max,
        step: step,
        labels: labels
      };
      
      // Store default for reset
      defaultValues[inputId] = { value: value };
      
      // Update displayed value
      updateSliderDisplay(inputId, input, labels, value, min, step);
      
      // Update CSS variable for track fill
      updateSliderTrack(input);
      
      input.addEventListener('input', () => {
        const newValue = parseFloat(input.value);
        inputState[inputId].selected = [input.value];
        inputState[inputId].value = newValue;
        
        updateSliderDisplay(inputId, input, labels, newValue, min, step);
        updateSliderTrack(input);
        debugInputState(inputId, 'slider-input');
        applyAllFilters();
      });
    });
  }
  
  /**
   * Update slider display value (supports custom labels)
   */
  function updateSliderDisplay(inputId, input, labels, value, min, step) {
    const valueDisplay = document.getElementById(inputId + '_value');
    if (valueDisplay) {
      if (labels && labels.length > 0) {
        // Calculate which label to show
        const idx = Math.round((value - min) / step);
        if (idx >= 0 && idx < labels.length) {
          valueDisplay.textContent = labels[idx];
        } else {
          valueDisplay.textContent = value;
        }
      } else {
        valueDisplay.textContent = value;
      }
    }
  }

  /**
   * Initialize TEXT inputs
   */
  function initTextInputs() {
    const textInputs = document.querySelectorAll('input[data-input-type="text"]');
    
    textInputs.forEach(input => {
      const inputId = input.id;
      
      if (input.dataset.dashboardrInitialized === 'true') {
        return;
      }
      
      const filterVar = input.dataset.filterVar;
      if (!filterVar) {
        console.warn(`Text input ${inputId} missing data-filter-var`);
        return;
      }
      
      input.dataset.dashboardrInitialized = 'true';
      
      inputState[inputId] = {
        filterVar,
        inputType: 'text',
        selected: [input.value],
        value: input.value
      };
      
      // Store default for reset
      defaultValues[inputId] = { value: input.value };
      
      // Debounce text input to avoid too many filter calls
      let debounceTimer;
      input.addEventListener('input', () => {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(() => {
          inputState[inputId].selected = [input.value];
          inputState[inputId].value = input.value;
          debugInputState(inputId, 'text-input');
          applyAllFilters();
        }, 300);
      });
    });
  }

  /**
   * Initialize NUMBER inputs
   */
  function initNumberInputs() {
    const numberInputs = document.querySelectorAll('input[data-input-type="number"]');
    
    numberInputs.forEach(input => {
      const inputId = input.id;
      
      if (input.dataset.dashboardrInitialized === 'true') {
        return;
      }
      
      const filterVar = input.dataset.filterVar;
      if (!filterVar) {
        console.warn(`Number input ${inputId} missing data-filter-var`);
        return;
      }
      
      input.dataset.dashboardrInitialized = 'true';
      
      const value = parseFloat(input.value) || 0;
      inputState[inputId] = {
        filterVar,
        inputType: 'number',
        selected: [input.value],
        value: value,
        min: parseFloat(input.min),
        max: parseFloat(input.max)
      };
      
      // Store default for reset
      defaultValues[inputId] = { value: value };
      
      input.addEventListener('input', () => {
        const newValue = parseFloat(input.value) || 0;
        inputState[inputId].selected = [input.value];
        inputState[inputId].value = newValue;
        debugInputState(inputId, 'number-input');
        applyAllFilters();
      });
    });
  }

  /**
   * Initialize BUTTON GROUP inputs
   */
  function initButtonGroupInputs() {
    const buttonGroups = document.querySelectorAll('.dashboardr-button-group');
    
    buttonGroups.forEach(group => {
      const inputId = group.id;
      
      if (group.dataset.dashboardrInitialized === 'true') {
        return;
      }
      
      const filterVar = group.dataset.filterVar;
      if (!filterVar) {
        console.warn(`Button group ${inputId} missing data-filter-var`);
        return;
      }
      
      group.dataset.dashboardrInitialized = 'true';
      
      // Get initial active button
      const activeBtn = group.querySelector('.dashboardr-button-option.active');
      const selected = activeBtn ? [activeBtn.dataset.value] : [];
      
      inputState[inputId] = {
        filterVar,
        inputType: 'button_group',
        selected: selected
      };
      
      // Store default for reset
      defaultValues[inputId] = { selected: selected.slice() };
      
      // Listen to all buttons in the group
      const buttons = group.querySelectorAll('.dashboardr-button-option');
      buttons.forEach(btn => {
        btn.addEventListener('click', () => {
          // Remove active from all buttons
          buttons.forEach(b => b.classList.remove('active'));
          // Add active to clicked button
          btn.classList.add('active');
          
          inputState[inputId].selected = [btn.dataset.value];
          debugInputState(inputId, 'button-group-click');
          applyAllFilters();
        });
      });
    });
  }

  /**
   * Initialize DATE inputs
   */
  function initDateInputs() {
    const dateInputs = document.querySelectorAll('input[data-input-type="date"]');

    dateInputs.forEach(input => {
      const inputId = input.id;

      if (input.dataset.dashboardrInitialized === 'true') return;

      const filterVar = input.dataset.filterVar;
      if (!filterVar) {
        console.warn('Date input ' + inputId + ' missing data-filter-var');
        return;
      }

      input.dataset.dashboardrInitialized = 'true';

      inputState[inputId] = {
        filterVar: filterVar,
        inputType: 'date',
        value: input.value || ''
      };

      defaultValues[inputId] = { value: input.value || '' };

      input.addEventListener('change', function() {
        inputState[inputId].value = input.value || '';
        debugInputState(inputId, 'date-change');
        applyAllFilters();
      });
    });
  }

  /**
   * Initialize DATERANGE inputs
   */
  function initDaterangeInputs() {
    var containers = document.querySelectorAll('[data-input-type="daterange"]');

    containers.forEach(function(container) {
      var inputId = container.id;

      if (container.dataset.dashboardrInitialized === 'true') return;

      var filterVar = container.dataset.filterVar;
      if (!filterVar) {
        console.warn('Daterange input ' + inputId + ' missing data-filter-var');
        return;
      }

      container.dataset.dashboardrInitialized = 'true';

      var startInput = container.querySelector('[data-role="start"]');
      var endInput = container.querySelector('[data-role="end"]');

      inputState[inputId] = {
        filterVar: filterVar,
        inputType: 'daterange',
        start: startInput ? startInput.value : '',
        end: endInput ? endInput.value : ''
      };

      defaultValues[inputId] = {
        start: startInput ? startInput.value : '',
        end: endInput ? endInput.value : ''
      };

      function onDateChange() {
        inputState[inputId].start = startInput ? startInput.value : '';
        inputState[inputId].end = endInput ? endInput.value : '';
        debugInputState(inputId, 'daterange-change');
        applyAllFilters();
      }

      if (startInput) startInput.addEventListener('change', onDateChange);
      if (endInput) endInput.addEventListener('change', onDateChange);
    });
  }

  /**
   * Update slider track fill based on value
   */
  function updateSliderTrack(input) {
    const min = parseFloat(input.min) || 0;
    const max = parseFloat(input.max) || 100;
    const value = parseFloat(input.value);
    const percent = ((value - min) / (max - min)) * 100;
    input.style.setProperty('--slider-percent', percent + '%');
  }

  /**
   * Parse a date-like string into a comparable ISO date string (YYYY-MM-DD).
   * Handles: ISO (2024-01-15), YYYY (2024), YYYY-QN (2024-Q1),
   * Mon YYYY (Jan 2024), and various date-like formats.
   * Returns '' if parsing fails.
   */
  function _parseDateLike(str) {
    if (!str || typeof str !== 'string') return '';
    str = str.trim();

    // Already ISO YYYY-MM-DD
    if (/^\d{4}-\d{2}-\d{2}$/.test(str)) return str;

    // Year only (YYYY) → first day of year
    if (/^\d{4}$/.test(str)) return str + '-01-01';

    // Quarter (2024-Q1, 2024 Q2, Q3 2024)
    var qMatch = str.match(/^(\d{4})[- ]?Q([1-4])$/i) || str.match(/^Q([1-4])[- ]?(\d{4})$/i);
    if (qMatch) {
      var year = qMatch[1].length === 4 ? qMatch[1] : qMatch[2];
      var q = qMatch[1].length === 4 ? qMatch[2] : qMatch[1];
      var month = String((parseInt(q, 10) - 1) * 3 + 1).padStart(2, '0');
      return year + '-' + month + '-01';
    }

    // Month names: Jan 2024, January 2024, 2024-Jan
    var months = { jan: '01', feb: '02', mar: '03', apr: '04', may: '05', jun: '06',
                   jul: '07', aug: '08', sep: '09', oct: '10', nov: '11', dec: '12' };
    var mMatch = str.match(/^([A-Za-z]+)\s+(\d{4})$/) || str.match(/^(\d{4})[- ]([A-Za-z]+)$/);
    if (mMatch) {
      var mName = (mMatch[1].length > 2 ? mMatch[1] : mMatch[2]).substring(0, 3).toLowerCase();
      var mYear = mMatch[1].length === 4 ? mMatch[1] : mMatch[2];
      if (months[mName]) return mYear + '-' + months[mName] + '-01';
    }

    // Try native Date parse as last resort
    var d = new Date(str);
    if (!isNaN(d.getTime())) {
      return d.toISOString().substring(0, 10);
    }

    return '';
  }

  /**
   * Resolve slider label index from current slider metadata.
   * Supports both numeric ranges (min/max/step) and legacy 1-based sliders.
   */
  function resolveSliderLabelIndex(sliderInfo) {
    if (!sliderInfo || !Array.isArray(sliderInfo.labels) || sliderInfo.labels.length === 0) {
      return -1;
    }

    const labelsLen = sliderInfo.labels.length;
    const value = Number(sliderInfo.value);
    const min = Number(sliderInfo.min);
    const step = Number(sliderInfo.step);

    let idx;
    if (Number.isFinite(value) && Number.isFinite(min) && Number.isFinite(step) && step > 0) {
      idx = Math.round((value - min) / step);
    } else {
      // Fallback for legacy sliders that encode selected label as 1..N.
      idx = Math.round(value) - 1;
    }

    if (!Number.isFinite(idx)) idx = 0;
    if (idx < 0) idx = 0;
    if (idx >= labelsLen) idx = labelsLen - 1;
    return idx;
  }

  /**
   * Get selected values from checkbox group
   */
  function getCheckboxValues(group) {
    const checked = group.querySelectorAll('input[type="checkbox"]:checked');
    return Array.from(checked).map(cb => cb.value);
  }

  /**
   * Get selected value from radio group
   */
  function getRadioValue(group) {
    const checked = group.querySelector('input[type="radio"]:checked');
    return checked ? [checked.value] : [];
  }

  function enhanceNativeMultiSelect(input) {
    input.addEventListener('mousedown', function(e) {
      if (e.target.tagName !== 'OPTION') return;
      e.preventDefault();
      e.target.selected = !e.target.selected;
      input.dispatchEvent(new Event('change'));
    });
  }

  function getSelectedValues(input) {
    if (input.tagName === 'SELECT') {
      return Array.from(input.selectedOptions).map(opt => opt.value);
    }
    return [input.value];
  }

  /**
   * Store original series data for later restoration
   */
  function storeOriginalData() {
    const entries = getChartEntries();
    if (!entries || entries.length === 0) return;

    entries.forEach(entry => {
      if (!entry || !entry.backend) return;
      if (entry.backend === 'highcharter') {
        const chart = chartRegistry && chartRegistry.resolveHighchart
          ? chartRegistry.resolveHighchart(entry)
          : null;
        if (!chart || !chart.series) return;
        chart.series.forEach(series => {
          if (!series || typeof series !== 'object') return;
          if (!originalSeriesData.has(series)) {
            const seriesOptions = series.options || {};
            const data = seriesOptions.data ? JSON.parse(JSON.stringify(seriesOptions.data)) : [];
            originalSeriesData.set(series, { data: data, name: series.name });
          }
        });
      } else if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters[entry.backend]) {
        chartRegistry.adapters[entry.backend].storeOriginal(entry);
      }
    });
  }

  /**
   * Ensure cross-tab data is loaded for a lazy entry.
   * Returns a Promise that resolves with the crossTabInfo (with .data populated).
   * If already loaded or not lazy, resolves immediately.
   */
  function _ensureCrossTabData(chartId, info) {
    // Already loaded or not lazy
    if (!info._lazy || info.data) {
      return Promise.resolve(info);
    }

    // Already fetching - return existing promise
    if (info._fetchPromise) {
      return info._fetchPromise;
    }

    // Show a small loading indicator on the chart container
    var chartEl = document.querySelector('[data-dashboardr-chart-id="' + chartId + '"]');
    if (!chartEl) {
      // Try finding by Highcharts chart id
      chartEl = document.getElementById(chartId);
    }
    var spinner = null;
    if (chartEl) {
      spinner = document.createElement('div');
      spinner.className = 'dashboardr-crosstab-loading';
      spinner.style.cssText = 'position:absolute;top:0;left:0;right:0;bottom:0;display:flex;align-items:center;justify-content:center;background:rgba(255,255,255,0.7);z-index:10;pointer-events:none;';
      spinner.innerHTML = '<div style="width:24px;height:24px;border:3px solid #e5e7eb;border-top-color:#f39917;border-radius:50%;animation:spin 0.8s linear infinite"></div>';
      if (getComputedStyle(chartEl).position === 'static') {
        chartEl.style.position = 'relative';
      }
      chartEl.appendChild(spinner);
    }

    info._fetchPromise = fetch(info._url)
      .then(function(response) {
        if (!response.ok) throw new Error('Failed to load cross-tab data: ' + response.status);
        return response.json();
      })
      .then(function(data) {
        info.data = data;
        delete info._lazy;
        delete info._fetchPromise;
        // Remove spinner
        if (spinner && spinner.parentNode) {
          spinner.parentNode.removeChild(spinner);
        }
        return info;
      })
      .catch(function(err) {
        console.error('dashboardr: Failed to load cross-tab data for ' + chartId + ':', err);
        delete info._fetchPromise;
        if (spinner && spinner.parentNode) {
          spinner.parentNode.removeChild(spinner);
        }
        return info;
      });

    return info._fetchPromise;
  }

  // =================================================================
  // Filter Application Engine
  // =================================================================
  // The core of the filtering system. applyAllFilters() is called
  // whenever ANY input changes. It:
  //   1. Collects current values from inputState
  //   2. For each registered chart: filters its cross-tab data
  //   3. Updates Highcharts series/categories via the Highcharts API
  //   4. Dispatches events so show_when.js can re-evaluate
  // =================================================================

  /**
   * Apply all filters together
   */
  function applyAllFilters() {
    const entries = getChartEntries() || [];
    const hasTables = chartRegistry && (
      (chartRegistry.getTables && chartRegistry.getTables().length > 0) ||
      (chartRegistry.getDTs && chartRegistry.getDTs().length > 0) ||
      (chartRegistry.getReactables && chartRegistry.getReactables().length > 0)
    );
    if (entries.length === 0 && !hasTables) {
      return setTimeout(applyAllFilters, 200);
    }

    // Collect all active filters with their metadata
    const filters = {};
    const sliderFilters = {};
    const switchFilters = {};
    const textFilters = {};
    const numberFilters = {};
    const dateFilters = {};
    const daterangeFilters = {};
    const periodFilters = {};  // Special handling for period presets

    Object.keys(inputState).forEach(id => {
      const state = inputState[id];
      if (state.inputType === 'slider') {
        sliderFilters[state.filterVar] = {
          value: state.value,
          min: state.min,
          max: state.max,
          step: state.step || 1,
          labels: state.labels
        };
      } else if (state.inputType === 'switch') {
        switchFilters[state.filterVar] = state.value;
      } else if (state.inputType === 'text') {
        if (state.value && state.value.trim()) {
          textFilters[state.filterVar] = state.value.trim().toLowerCase();
        }
      } else if (state.inputType === 'number') {
        const rawValue = Array.isArray(state.selected) ? state.selected[0] : '';
        if (rawValue !== '' && rawValue !== null && rawValue !== undefined) {
          numberFilters[state.filterVar] = state.value;
        }
      } else if (state.inputType === 'date') {
        if (state.value && state.value.trim()) {
          dateFilters[state.filterVar] = state.value.trim();
        }
      } else if (state.inputType === 'daterange') {
        if ((state.start && state.start.trim()) || (state.end && state.end.trim())) {
          daterangeFilters[state.filterVar] = {
            start: state.start ? state.start.trim() : '',
            end: state.end ? state.end.trim() : ''
          };
        }
      } else if (state.filterVar === 'period') {
        // Handle period presets (maps to year ranges)
        periodFilters[state.filterVar] = state.selected;
      } else {
        // Select, checkbox, radio, button_group all use selected array
        filters[state.filterVar] = state.selected;
      }
    });
    debugLog('apply-all-filters', {
      filters: filters,
      sliderFilters: sliderFilters,
      switchFilters: switchFilters,
      textFilters: textFilters,
      numberFilters: numberFilters,
      dateFilters: dateFilters,
      daterangeFilters: daterangeFilters,
      periodFilters: periodFilters,
      chartEntries: entries.map(function(e) {
        return { id: e.id, backend: e.backend, x: e.x, filterVars: e.filterVars };
      }),
      crossTabKeys: window.dashboardrCrossTab ? Object.keys(window.dashboardrCrossTab) : []
    });

    // Collect switch overrides for cross-tab rebuilds
    const switchOverrides = {};
    Object.keys(inputState).forEach(id => {
      const state = inputState[id];
      if (state.inputType === 'switch' && state.toggleSeries && state.filterVar) {
        if (!switchOverrides[state.filterVar]) {
          switchOverrides[state.filterVar] = [];
        }
        switchOverrides[state.filterVar].push({
          seriesName: state.toggleSeries,
          visible: !!state.value,
          override: !!state.override
        });
      }
    });

    // Rebuild charts from cross-tab data (all backends that support it)
    const crossTabHandled = new Set();
    const lazyPromises = [];
    if (window.dashboardrCrossTab) {
      entries.forEach(entry => {
        if (!entry || !entry.id) return;
        const crossTabInfo = window.dashboardrCrossTab[entry.id];
        if (!crossTabInfo) return;

        if (crossTabInfo._lazy && !crossTabInfo.data) {
          // Lazy entry: fetch data first, then rebuild
          crossTabHandled.add(entry.id); // Mark as handled to prevent fallback
          const promise = _ensureCrossTabData(entry.id, crossTabInfo).then(function(loaded) {
            if (loaded && loaded.data) {
              rebuildFromCrossTab(
                entry, loaded, filters, sliderFilters,
                textFilters, numberFilters, switchOverrides,
                dateFilters, daterangeFilters
              );
              // Note: lazy charts are revealed by the bulk reveal at end of applyAllFilters
            }
          });
          lazyPromises.push(promise);
        } else {
          // Already loaded: synchronous rebuild
          const result = rebuildFromCrossTab(
            entry,
            crossTabInfo,
            filters,
            sliderFilters,
            textFilters,
            numberFilters,
            switchOverrides,
            dateFilters,
            daterangeFilters
          );
          if (result) crossTabHandled.add(entry.id);
        }
      });
    }

    const highchartEntries = entries.filter(e => e.backend === 'highcharter' && !crossTabHandled.has(e.id));
    const charts = highchartEntries.map(e => {
      const chart = chartRegistry && chartRegistry.resolveHighchart ? chartRegistry.resolveHighchart(e) : null;
      return { entry: e, chart };
    }).filter(x => x.chart);

    charts.forEach(({ chart, entry }) => {
      if (!chart || !chart.series) return;
      debugLog('highcharter-entry', {
        id: entry && entry.id,
        backend: entry && entry.backend,
        x: entry && entry.x,
        filterVars: entry && entry.filterVars,
        seriesCount: chart && chart.series ? chart.series.length : 0
      });
      
      // Store original categories if not already stored
      if (!chart._originalCategories && chart.xAxis && chart.xAxis[0] && chart.xAxis[0].categories) {
        var cats = chart.xAxis[0].categories;
        chart._originalCategories = Array.isArray(cats) ? cats.slice() : null;
      }
      
      // Get original x-axis categories (ensure it's always an array or null)
      const rawCats = chart._originalCategories ||
        (chart.xAxis && chart.xAxis[0] && chart.xAxis[0].categories ? chart.xAxis[0].categories : null);
      const originalCategories = Array.isArray(rawCats) ? rawCats : null;
      
      // Also check for numeric x-axis (no categories, but has point.x values)
      const firstNumericSeries = (chart.series || []).find(s =>
        s &&
        Array.isArray(s.data) &&
        s.data.length > 0 &&
        s.data[0] &&
        typeof s.data[0].x === 'number'
      );
      const hasNumericXAxis = !originalCategories && !!firstNumericSeries;
      
      // Determine which filters apply to series names vs categories
      const seriesNames = (chart.series || [])
        .filter(s => s && typeof s === 'object')
        .map(s => s.name);
      
      // Convert categories to strings for comparison (they might be numbers)
      const categoryStrings = originalCategories ? originalCategories.map(c => String(c)) : [];
      
      // Calculate which categories should be visible
      let visibleCategoryIndices = originalCategories ? originalCategories.map((_, i) => i) : [];
      
      if (originalCategories) {
        // Apply period preset filters first (converts to year ranges)
        Object.keys(periodFilters).forEach(filterVar => {
          const selected = periodFilters[filterVar];
          if (selected && selected.length > 0) {
            const periodValue = selected[0];  // Radio returns array with one value
            
            if (periodValue && !periodValue.includes('All')) {
              // Parse period preset and filter years
              visibleCategoryIndices = visibleCategoryIndices.filter(idx => {
                const catNum = parseFloat(originalCategories[idx]);
                if (isNaN(catNum)) return true;
                
                if (periodValue.includes('Pre-COVID') || periodValue.includes('2015-2019')) {
                  return catNum >= 2015 && catNum <= 2019;
                } else if (periodValue.includes('Post-COVID') || periodValue.includes('2020')) {
                  return catNum >= 2020;
                }
                return true;
              });
            }
          }
        });
        
        // Apply discrete category filters to determine visible categories
        Object.keys(filters).forEach(filterVar => {
          const selectedValues = filters[filterVar];
          if (selectedValues && selectedValues.length > 0) {
            const selectedStrings = selectedValues.map(v => String(v));
            const isCategoryFilter = selectedStrings.some(v => categoryStrings.includes(v)) ||
                                     categoryStrings.some(c => selectedStrings.includes(c));
            
            if (isCategoryFilter) {
              visibleCategoryIndices = visibleCategoryIndices.filter(idx => {
                const category = String(originalCategories[idx]);
                return selectedStrings.includes(category);
              });
            }
          }
        });
        
        // Apply slider filters to determine visible categories
        Object.keys(sliderFilters).forEach(filterVar => {
          if (entry && entry.x && String(filterVar) !== String(entry.x)) {
            return;
          }
          const sliderInfo = sliderFilters[filterVar];
          
          // If slider has labels, use label-based filtering
          if (sliderInfo.labels && sliderInfo.labels.length > 0) {
            // Get the label at current slider position
            const labelIdx = Math.round((sliderInfo.value - sliderInfo.min) / (sliderInfo.step || 1));
            const startLabel = sliderInfo.labels[labelIdx];
            
            if (startLabel) {
              // Find the index of this label in the original categories
              const startCategoryIdx = originalCategories.findIndex(cat => String(cat) === String(startLabel));
              
              if (startCategoryIdx >= 0) {
                // Keep only categories at or after this index
                visibleCategoryIndices = visibleCategoryIndices.filter(idx => idx >= startCategoryIdx);
              }
            }
          } else {
            // Fallback: try numeric comparison
            visibleCategoryIndices = visibleCategoryIndices.filter(idx => {
              const catNum = parseFloat(originalCategories[idx]);
              if (!isNaN(catNum)) {
                return catNum >= sliderInfo.value;
              }
              return true;
            });
          }
        });
      }
      
      // Get new categories list
      const newCategories = visibleCategoryIndices.map(idx => originalCategories[idx]);
      
      // Handle special switch filters (legend toggle)
      Object.keys(inputState).forEach(id => {
        const state = inputState[id];
        if (state.inputType !== 'switch') return;
        
        if (state.filterVar === 'show_legend') {
          chart.legend.update({ enabled: state.value }, false);
        }
      });
      
      // Handle chart type changes
      Object.keys(filters).forEach(filterVar => {
        if (filterVar === 'chart_type') {
          const chartType = filters[filterVar][0];
          if (chartType) {
            const typeMap = {
              'Line': 'line',
              'Area': 'area', 
              'Column': 'column'
            };
            const hcType = typeMap[chartType] || 'line';
            (chart.series || []).forEach(series => {
              if (!series || typeof series !== 'object') return;
              series.update({ type: hcType }, false);
            });
          }
        }
      });
      
      // Handle metric switching FIRST - rebuild series data from embedded data
      // This must happen before other filtering to set up the base data
      let metricSwitched = false;
      if (filters['metric'] && window.dashboardrMetricData) {
        const selectedMetric = filters['metric'][0];
        if (selectedMetric) {
          const allData = window.dashboardrMetricData;
          
          // Detect time variable - use configured value or auto-detect
          const timeVar = window.dashboardrTimeVar || 
                          (allData[0].year !== undefined ? 'year' : 
                          allData[0].decade !== undefined ? 'decade' : 
                          allData[0].time !== undefined ? 'time' : 
                          allData[0].date !== undefined ? 'date' : null);
          
          // Use chart's x-axis categories if available, otherwise extract from data
          const timeValues = originalCategories || 
            (timeVar ? [...new Set(allData.map(d => d[timeVar]))].sort() : []);
          
          (chart.series || []).forEach(series => {
            if (!series || typeof series !== 'object') return;
            const countryName = series.name;
            const countryData = allData.filter(d => 
              d.country === countryName && d.metric === selectedMetric
            );
            
            if (countryData.length > 0) {
              const newData = timeValues.map(timeVal => {
                const point = countryData.find(d => 
                  timeVar ? d[timeVar] === timeVal : false
                );
                return point ? point.value : null;
              });
              series.setData(newData, false);
              
              // Update the original data store for this series
              originalSeriesData.set(series, {
                data: JSON.parse(JSON.stringify(newData)),
                name: series.name
              });
            }
          });
          
          // Update chart title dynamically based on selected metric
          chart.setTitle(
            { text: selectedMetric + ' by Country' }, 
            { text: 'Trends over time' }, 
            false
          );
          chart.yAxis[0].setTitle({ text: selectedMetric }, false);
          
          metricSwitched = true;
        }
      }
      
      // Build sets for switch-controlled series
      const switchHiddenSeries = new Set();  // Series to HIDE (switch is OFF)
      const switchShownSeries = new Set();   // Series to SHOW with override (switch is ON + override=true)
      Object.keys(inputState).forEach(id => {
        const state = inputState[id];
        if (state.inputType === 'switch' && state.toggleSeries) {
          if (!state.value) {
            // Switch is OFF - hide this series
            switchHiddenSeries.add(state.toggleSeries);
          } else if (state.override) {
            // Switch is ON + override=true - show this series regardless of other filters
            switchShownSeries.add(state.toggleSeries);
          }
        }
      });
      
      (chart.series || []).forEach(series => {
        if (!series || typeof series !== 'object') return;
        const seriesName = series.name;
        const original = originalSeriesData.get(series);
        
        // Check if hidden by switch toggle (switch OFF)
        if (switchHiddenSeries.has(seriesName)) {
          series.setVisible(false, false);
          series.update({ showInLegend: false }, false);
          return;
        }
        
        // Check if shown by switch with override (switch ON + override=true)
        if (switchShownSeries.has(seriesName)) {
          series.setVisible(true, false);
          series.update({ showInLegend: true }, false);
          // Continue to filter data points, but series stays visible
        } else {
          // Check series-level visibility (e.g., country filter from selectize/checkbox)
          let showSeries = true;
          
          // Apply text search filter to series names
          Object.keys(textFilters).forEach(filterVar => {
            const searchText = textFilters[filterVar];
            // Check if this filter applies to series names
            if (seriesNames.some(n => n.toLowerCase().includes(searchText))) {
              if (!seriesName.toLowerCase().includes(searchText)) {
                showSeries = false;
              }
            }
          });
          
          Object.keys(filters).forEach(filterVar => {
            const selectedValues = filters[filterVar];
            if (selectedValues && selectedValues.length > 0) {
              // Check if this filter applies to series names
              const isSeriesFilter = selectedValues.some(v => seriesNames.includes(v)) || 
                                     seriesNames.some(n => selectedValues.includes(n));
              if (isSeriesFilter) {
                if (!selectedValues.includes(seriesName)) {
                  showSeries = false;
                }
              }
            }
          });
          
          // If series should be hidden entirely
          if (!showSeries) {
            series.setVisible(false, false);
            series.update({ showInLegend: false }, false);
            return;
          }
          
          // Series should be visible - show in legend too
          series.setVisible(true, false);
          series.update({ showInLegend: true }, false);
        }
        
        // Filter data to only include visible categories
        if (original && originalCategories) {
          const filteredData = visibleCategoryIndices.map(idx => {
            const point = original.data[idx];
            return point !== undefined ? JSON.parse(JSON.stringify(point)) : null;
          });
          
          series.setData(filteredData, false, false, false);
        } else if (original && hasNumericXAxis) {
          // Handle charts with numeric x-axis (no categories)
          let filteredData = JSON.parse(JSON.stringify(original.data));
          Object.keys(sliderFilters).forEach(filterVar => {
            if (entry && entry.x && String(filterVar) !== String(entry.x)) {
              return;
            }
            const sliderInfo = sliderFilters[filterVar];
            filteredData = filteredData.filter(point => {
              if (point === null) return false;
              const xVal = typeof point === 'object' ? point.x : null;
              if (xVal !== null && xVal < sliderInfo.value) {
                return false;
              }
              return true;
            });
          });
          series.setData(filteredData, false, false, false);
        }
      });
      
      // Update x-axis categories to only show visible ones
      if (originalCategories && newCategories.length > 0) {
        chart.xAxis[0].setCategories(newCategories, false);
      }
      
      chart.redraw();
    });

    // Apply filters to Plotly charts
    const plotlyEntries = entries.filter(e => e.backend === 'plotly' && !crossTabHandled.has(e.id));
    plotlyEntries.forEach(entry => {
      applyPlotlyFilters(entry, filters, sliderFilters, textFilters, numberFilters, periodFilters);
    });

    // Apply filters to ECharts charts
    const echartsEntries = entries.filter(e => e.backend === 'echarts4r' && !crossTabHandled.has(e.id));
    echartsEntries.forEach(entry => {
      applyEchartsFilters(entry, filters, sliderFilters, textFilters, numberFilters, periodFilters);
    });

    // Apply filters to tables and widgets
    applyTableFilters(filters, sliderFilters, textFilters, numberFilters, periodFilters);

    // Update any charts that have dynamic title templates
    updateDynamicTitles();

    // Reveal all deferred charts by fading out the loading overlay.
    // deferred_charts.js creates a white overlay on top while the chart renders underneath.
    document.querySelectorAll('.dashboardr-deferred-pending-filters').forEach(function(el) {
      el.classList.remove('dashboardr-deferred-pending-filters');
      // Fade out the overlay to smoothly reveal the chart underneath
      var overlay = el.querySelector('.dashboardr-deferred-overlay');
      if (overlay) {
        overlay.style.opacity = '0';
        // Remove overlay from DOM after transition completes
        setTimeout(function() {
          if (overlay.parentNode) overlay.parentNode.removeChild(overlay);
        }, 400);
      }
      // Reflow charts now that they're visible with correct data
      var container = el.querySelector('[id$="_container"]');
      if (container && container._hcChart) {
        try { container._hcChart.reflow(); } catch(e) {}
      }
    });

    // Dispatch event for URL params and accessibility modules
    try {
      document.dispatchEvent(new CustomEvent('dashboardr:filter-changed', {
        detail: { inputState: inputState }
      }));
    } catch (e) {
      // CustomEvent not supported in very old browsers
    }

    // Also dispatch a standard change event so show_when.js re-evaluates
    // (show_when.js listens for 'change' events on the document)
    try {
      document.dispatchEvent(new Event('change', { bubbles: true }));
    } catch (e) {
      // Fallback for old browsers
    }
  }

  function computeVisibleCategories(allCategories, filters, sliderFilters, periodFilters, xVarName) {
    if (!allCategories || allCategories.length === 0) return null;
    let visible = allCategories.slice();
    const categoryStrings = visible.map(c => String(c));

    // Period presets (numeric categories)
    Object.keys(periodFilters).forEach(filterVar => {
      const selected = periodFilters[filterVar];
      if (selected && selected.length > 0) {
        const periodValue = selected[0];
        if (periodValue && !periodValue.includes('All')) {
          visible = visible.filter(cat => {
            const catNum = parseFloat(cat);
            if (isNaN(catNum)) return true;
            if (periodValue.includes('Pre-COVID') || periodValue.includes('2015-2019')) {
              return catNum >= 2015 && catNum <= 2019;
            } else if (periodValue.includes('Post-COVID') || periodValue.includes('2020')) {
              return catNum >= 2020;
            }
            return true;
          });
        }
      }
    });

    // Discrete filters
    Object.keys(filters).forEach(filterVar => {
      const selectedValues = filters[filterVar];
      if (selectedValues && selectedValues.length > 0) {
        const selectedStrings = selectedValues.map(v => String(v));
        const isCategoryFilter = selectedStrings.some(v => categoryStrings.includes(v)) ||
                                 categoryStrings.some(c => selectedStrings.includes(c));
        if (isCategoryFilter) {
          visible = visible.filter(cat => selectedStrings.includes(String(cat)));
        }
      }
    });

    // Slider filters
    Object.keys(sliderFilters).forEach(filterVar => {
      if (xVarName && String(filterVar) !== String(xVarName)) {
        return;
      }
      const sliderInfo = sliderFilters[filterVar];
      if (sliderInfo.labels && sliderInfo.labels.length > 0) {
        const labelIdx = Math.round((sliderInfo.value - sliderInfo.min) / (sliderInfo.step || 1));
        const startLabel = sliderInfo.labels[labelIdx];
        if (startLabel) {
          const startIdx = visible.findIndex(cat => String(cat) === String(startLabel));
          if (startIdx >= 0) {
            visible = visible.filter((_, idx) => idx >= startIdx);
          }
        }
      } else {
        visible = visible.filter(cat => {
          const catNum = parseFloat(cat);
          if (!isNaN(catNum)) {
            return catNum >= sliderInfo.value;
          }
          return true;
        });
      }
    });

    return visible;
  }

  function shouldShowSeries(seriesName, filters, textFilters, seriesNames) {
    // Text search
    for (const filterVar in textFilters) {
      const searchText = textFilters[filterVar];
      if (seriesNames.some(n => n.toLowerCase().includes(searchText))) {
        if (!seriesName.toLowerCase().includes(searchText)) {
          return false;
        }
      }
    }
    // Discrete filters against series names
    for (const filterVar in filters) {
      const selectedValues = filters[filterVar];
      if (selectedValues && selectedValues.length > 0) {
        const isSeriesFilter = selectedValues.some(v => seriesNames.includes(v)) ||
                               seriesNames.some(n => selectedValues.includes(n));
        if (isSeriesFilter && !selectedValues.includes(seriesName)) {
          return false;
        }
      }
    }
    return true;
  }

  function normalizeSeriesName(name) {
    if (name === undefined || name === null) return null;
    const text = String(name).trim();
    return text.length > 0 ? text : null;
  }

  function uniqueNonEmptyNames(names) {
    const seen = new Set();
    const out = [];
    (Array.isArray(names) ? names : []).forEach(name => {
      const normalized = normalizeSeriesName(name);
      if (!normalized || seen.has(normalized)) return;
      seen.add(normalized);
      out.push(normalized);
    });
    return out;
  }

  function syncEchartsLegend(option, names) {
    const legendNames = uniqueNonEmptyNames(names);
    const selected = {};
    legendNames.forEach(name => { selected[name] = true; });
    if (Array.isArray(option.legend)) {
      option.legend = option.legend.map(legend => {
        const lg = legend && typeof legend === 'object' ? legend : {};
        lg.data = legendNames;
        lg.selected = selected;
        return lg;
      });
    } else if (option.legend && typeof option.legend === 'object') {
      option.legend.data = legendNames;
      option.legend.selected = selected;
    } else {
      option.legend = { data: legendNames, selected: selected };
    }
  }

  function _toFiniteNumber(value) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }

  function _quantileSorted(sortedValues, p) {
    const n = sortedValues.length;
    if (!n) return null;
    if (n === 1) return sortedValues[0];
    const h = (n - 1) * p + 1;
    const hf = Math.floor(h);
    const lower = sortedValues[Math.max(0, hf - 1)];
    const upper = sortedValues[Math.min(n - 1, hf)];
    return lower + (h - hf) * (upper - lower);
  }

  function _computeBoxStats(values) {
    const sorted = (Array.isArray(values) ? values : [])
      .map(_toFiniteNumber)
      .filter(v => v !== null)
      .sort((a, b) => a - b);
    if (!sorted.length) return null;

    const q1 = _quantileSorted(sorted, 0.25);
    const median = _quantileSorted(sorted, 0.5);
    const q3 = _quantileSorted(sorted, 0.75);
    const iqr = (q3 - q1);
    const lowerFence = q1 - 1.5 * iqr;
    const upperFence = q3 + 1.5 * iqr;
    const nonOutliers = sorted.filter(v => v >= lowerFence && v <= upperFence);
    const low = nonOutliers.length ? nonOutliers[0] : q1;
    const high = nonOutliers.length ? nonOutliers[nonOutliers.length - 1] : q3;
    const outliers = sorted.filter(v => v < lowerFence || v > upperFence);

    return { low, q1, median, q3, high, outliers };
  }

  function applyPlotlyFilters(entry, filters, sliderFilters, textFilters, numberFilters, periodFilters) {
    if (!entry || !entry.el || typeof Plotly === 'undefined') return;
    if (!entry.original || !entry.original.data) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.plotly) {
        chartRegistry.adapters.plotly.storeOriginal(entry);
      }
    }
    const original = entry.original && entry.original.data ? entry.original : { data: entry.el.data || [], layout: entry.el.layout || {} };
    const data = original.data || [];
    if (data.length === 0) return;

    const seriesNames = data.map(t => t.name).filter(n => n !== undefined && n !== null);
    let allCategories = null;
    const allCategoryValues = [];
    data.forEach(trace => {
      if (trace && Array.isArray(trace.x) && trace.x.length) {
        trace.x.forEach(v => allCategoryValues.push(v));
      }
    });
    if (allCategoryValues.length) {
      const seen = new Set();
      allCategories = [];
      allCategoryValues.forEach(v => {
        const key = String(v);
        if (!seen.has(key)) {
          seen.add(key);
          allCategories.push(v);
        }
      });
    }
    const visibleCategories = computeVisibleCategories(
      allCategories,
      filters,
      sliderFilters,
      periodFilters,
      entry && entry.x ? entry.x : null
    );
    const visibleSet = visibleCategories ? new Set(visibleCategories.map(c => String(c))) : null;

    // Switch-controlled series
    const switchHiddenSeries = new Set();
    const switchShownSeries = new Set();
    Object.keys(inputState).forEach(id => {
      const state = inputState[id];
      if (state.inputType === 'switch' && state.toggleSeries) {
        if (!state.value) switchHiddenSeries.add(state.toggleSeries);
        else if (state.override) switchShownSeries.add(state.toggleSeries);
      }
    });

    const newData = data.map(trace => {
      const t = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(trace) : JSON.parse(JSON.stringify(trace));
      const name = t.name || '';
      let show = shouldShowSeries(name, filters, textFilters, seriesNames);
      if (switchHiddenSeries.has(name)) show = false;
      if (switchShownSeries.has(name)) show = true;
      if (!show) t.visible = 'legendonly';

      if (visibleSet && t.x && t.y) {
        const newX = [];
        const newY = [];
        for (let i = 0; i < t.x.length; i++) {
          const xVal = String(t.x[i]);
          if (visibleSet.has(xVal)) {
            newX.push(t.x[i]);
            newY.push(t.y[i]);
          }
        }
        t.x = newX;
        t.y = newY;
      }
      return t;
    });

    Plotly.react(entry.el, newData, original.layout || entry.el.layout || {});
  }

  function applyEchartsFilters(entry, filters, sliderFilters, textFilters, numberFilters, periodFilters) {
    if (!entry || !entry.el || typeof echarts === 'undefined') return;
    if (!entry.original || !entry.original.option) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.echarts4r) {
        chartRegistry.adapters.echarts4r.storeOriginal(entry);
      }
    }
    const inst = echarts.getInstanceByDom(entry.el);
    if (!inst) return;
    const original = entry.original && entry.original.option ? entry.original.option : inst.getOption();
    if (!original) return;

    const option = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(original) : JSON.parse(JSON.stringify(original));
    const xAxis = option.xAxis && option.xAxis.length ? option.xAxis[0] : null;
    const allCategories = xAxis && xAxis.data ? xAxis.data.slice() : null;
    const visibleCategories = computeVisibleCategories(
      allCategories,
      filters,
      sliderFilters,
      periodFilters,
      entry && entry.x ? entry.x : null
    );
    const visibleSet = visibleCategories ? new Set(visibleCategories.map(c => String(c))) : null;

    const optionSeries = (option.series || [])
      .filter(s => s && typeof s === 'object')
      .map(series => {
        const name = normalizeSeriesName(series.name);
        if (!name) return null;
        series.name = name;
        return series;
      })
      .filter(Boolean);
    const seriesNames = optionSeries.map(s => s.name);
    const switchHiddenSeries = new Set();
    const switchShownSeries = new Set();
    Object.keys(inputState).forEach(id => {
      const state = inputState[id];
      if (state.inputType === 'switch' && state.toggleSeries) {
        const seriesName = normalizeSeriesName(state.toggleSeries);
        if (!seriesName) return;
        if (!state.value) switchHiddenSeries.add(seriesName);
        else if (state.override) switchShownSeries.add(seriesName);
      }
    });

    option.series = optionSeries.map(series => {
      const s = series;
      const name = s.name || '';
      let show = shouldShowSeries(name, filters, textFilters, seriesNames);
      if (switchHiddenSeries.has(name)) show = false;
      if (switchShownSeries.has(name)) show = true;
      if (!show) return null;
      if (visibleSet && Array.isArray(s.data) && allCategories) {
        const newData = [];
        const newCats = [];
        for (let i = 0; i < allCategories.length; i++) {
          if (visibleSet.has(String(allCategories[i]))) {
            newCats.push(allCategories[i]);
            newData.push(s.data[i]);
          }
        }
        if (xAxis) xAxis.data = newCats;
        s.data = newData;
      }
      return s;
    }).filter(Boolean);

    syncEchartsLegend(option, option.series.map(s => s && s.name));

    inst.setOption(option, true);
  }

  function filterRowsByInputs(data, filterVars, filters, sliderFilters, textFilters, numberFilters, periodFilters) {
    if (!Array.isArray(data)) return [];
    if (data.length === 0) return data;
    let rows = data.slice();
    const allLabels = ['all', 'alle', 'tous', 'todo', 'tutti', 'すべて', '全部'];

    (filterVars || []).forEach(filterVar => {
      const selectedValues = filters[filterVar];
      if (selectedValues && selectedValues.length > 0) {
        const hasAll = selectedValues.some(v => allLabels.includes(String(v).toLowerCase()));
        if (!hasAll) {
          rows = rows.filter(row => selectedValues.includes(String(row[filterVar])));
        }
      }
      const sliderInfo = sliderFilters[filterVar];
      if (sliderInfo) {
        if (sliderInfo.labels && sliderInfo.labels.length > 0) {
          const selectedIndex = resolveSliderLabelIndex(sliderInfo);
          const allowedLabels = sliderInfo.labels.slice(selectedIndex);
          rows = rows.filter(row => allowedLabels.includes(String(row[filterVar])));
        } else {
          rows = rows.filter(row => {
            const rowValue = Number(row[filterVar]);
            return !isNaN(rowValue) && rowValue >= sliderInfo.value;
          });
        }
      }
      const text = textFilters[filterVar];
      if (text) {
        rows = rows.filter(row => String(row[filterVar]).toLowerCase().includes(text));
      }
      const num = numberFilters[filterVar];
      if (num !== undefined && num !== null && num !== '') {
        rows = rows.filter(row => String(row[filterVar]) === String(num));
      }
    });

    return rows;
  }

  function applyTableFilters(filters, sliderFilters, textFilters, numberFilters, periodFilters) {
    if (!chartRegistry) return;

    // Basic HTML tables
    chartRegistry.getTables().forEach(tbl => {
      const filtered = filterRowsByInputs(tbl.data, tbl.filterVars || [], filters, sliderFilters, textFilters, numberFilters, periodFilters);
      const tableEl = document.querySelector(`[data-dashboardr-table-id='${tbl.id}']`);
      if (!tableEl) return;
      const tbody = tableEl.querySelector('tbody');
      if (!tbody) return;
      tbody.innerHTML = '';
      filtered.forEach(row => {
        const tr = document.createElement('tr');
        tbl.columns.forEach(col => {
          const td = document.createElement('td');
          td.textContent = row[col] !== undefined ? row[col] : '';
          tr.appendChild(td);
        });
        tbody.appendChild(tr);
      });
    });

    // DT widgets
    chartRegistry.getDTs().forEach(dt => {
      if (!dt.el || !dt.data || typeof $ === 'undefined' || !$.fn || !$.fn.dataTable) return;

      const root = $(dt.el);
      const tableNode = root.is('table') ? root[0] : root.find('table').first()[0];
      if (!tableNode || !$.fn.dataTable.isDataTable(tableNode)) return;

      const filtered = filterRowsByInputs(dt.data, dt.filterVars || [], filters, sliderFilters, textFilters, numberFilters, periodFilters);
      const cols = Array.isArray(dt.data) && dt.data.length ? Object.keys(dt.data[0]) : [];
      const rows = Array.isArray(filtered) ? filtered.map(r => cols.map(c => r[c])) : [];
      try {
        const instance = $(tableNode).DataTable();
        instance.clear();
        instance.rows.add(rows);
        instance.draw(false);
      } catch (e) { /* ignore */ }
    });

    // Reactable widgets
    chartRegistry.getReactables().forEach(rt => {
      if (!rt.el || !rt.data || typeof Reactable === 'undefined') return;
      const filtered = filterRowsByInputs(rt.data, rt.filterVars || [], filters, sliderFilters, textFilters, numberFilters, periodFilters);
      try {
        Reactable.setData(rt.el, filtered);
      } catch (e) { /* ignore */ }
    });
  }

  /**
   * Replace {var} placeholders in chart titles with current input values.
   * Looks up values by both input_id (name) and filter_var so users can
   * reference either in their title template.
   */
  function updateDynamicTitles() {
    if (!window.dashboardrCrossTab) return;
    var hasHighcharts = (typeof Highcharts !== 'undefined');

    // Build a combined lookup: input_id → value  AND  filter_var → value
    var lookup = {};

    var setLookup = function(key, value) {
      if (!key) return;
      if (value === undefined || value === null) return;
      var text = String(value).trim();
      if (!text) return;
      lookup[key] = text;
    };

    // Primary source: normalized dashboardr input state (covers all input types)
    Object.keys(inputState).forEach(function(inputId) {
      var state = inputState[inputId] || {};
      var filterVar = state.filterVar;
      var value = null;

      if (state.inputType === 'slider') {
        if (Array.isArray(state.labels) && state.labels.length > 0) {
          var idx = resolveSliderLabelIndex(state);
          value = state.labels[idx] !== undefined ? state.labels[idx] : state.value;
        } else {
          value = state.value;
        }
      } else if (state.inputType === 'switch') {
        value = state.value ? 'true' : 'false';
      } else if (state.inputType === 'daterange') {
        var start = state.start || '';
        var end = state.end || '';
        if (start || end) value = start + ' to ' + end;
      } else if (Array.isArray(state.selected)) {
        if (state.selected.length === 1) {
          value = state.selected[0];
        } else if (state.selected.length > 1) {
          value = state.selected.join(', ');
        }
      } else if (Object.prototype.hasOwnProperty.call(state, 'value')) {
        value = state.value;
      }

      setLookup(inputId, value);
      setLookup(filterVar, value);
    });

    // From select elements
    document.querySelectorAll('select').forEach(function(el) {
      var id = el.id;
      var fv = el.getAttribute('data-filter-var');
      var val = el.value;
      setLookup(id, val);
      setLookup(fv, val);
    });

    // From checked radio buttons
    document.querySelectorAll('input[type="radio"]:checked').forEach(function(el) {
      var id = el.name || el.id;
      var val = el.value;
      setLookup(id, val);
      // Also resolve filter_var from the parent radio group container
      var group = el.closest('[data-filter-var]');
      if (group) {
        var fv = group.getAttribute('data-filter-var');
        setLookup(fv, val);
      }
    });

    // Iterate over all cross-tab configs looking for titleTemplate
    var chartIds = Object.keys(window.dashboardrCrossTab);
    for (var i = 0; i < chartIds.length; i++) {
      var info = window.dashboardrCrossTab[chartIds[i]];
      if (!info.config || !info.config.titleTemplate) continue;

      // Build an extended lookup that includes titleLookups (derived values)
      var extLookup = Object.assign({}, lookup);
      if (info.config.titleLookups) {
        var tl = info.config.titleLookups;
        Object.keys(tl).forEach(function(placeholderName) {
          var mapping = tl[placeholderName];
          if (!mapping || !mapping.values) return;
          // Auto-detect: check every current input value against the mapping keys
          var resolved = null;
          Object.keys(lookup).forEach(function(inputId) {
            var inputVal = lookup[inputId];
            if (inputVal && mapping.values[inputVal] !== undefined) {
              resolved = mapping.values[inputVal];
            }
          });
          if (resolved !== null) {
            extLookup[placeholderName] = resolved;
          }
        });
      }

      var title = info.config.titleTemplate.replace(/\{(\w+)\}/g, function(match, varName) {
        return extLookup[varName] !== undefined ? extLookup[varName] : match;
      });

      // Find the Highcharts chart by its chart.id option (set via hc_chart(id = ...))
      if (hasHighcharts) {
        for (var j = 0; j < Highcharts.charts.length; j++) {
          var c = Highcharts.charts[j];
          if (!c) continue;
          var cid = c.options && c.options.chart && c.options.chart.id;
          if (cid === chartIds[i]) {
            c.setTitle({ text: title });
            break;
          }
        }
      }

      // Update other backends if registered
      if (chartRegistry && chartRegistry.getCharts) {
        var entries = chartRegistry.getCharts();
        var entry = entries.find(function(e) { return e.id === chartIds[i]; });
        if (entry && entry.backend === 'plotly' && typeof Plotly !== 'undefined' && entry.el) {
          try { Plotly.relayout(entry.el, { 'title.text': title }); } catch (e) { /* ignore */ }
        }
        if (entry && entry.backend === 'echarts4r' && typeof echarts !== 'undefined' && entry.el) {
          try {
            var inst = echarts.getInstanceByDom(entry.el);
            if (inst) inst.setOption({ title: { text: title } }, false);
          } catch (e) { /* ignore */ }
        }
      }
    }
  }

  function reapplyFilters() {
    applyAllFilters();
  }

  function selectAll(inputId) {
    const input = document.getElementById(inputId);
    if (!input) return;
    if (choicesInstances[inputId]) {
      const allValues = Array.from(input.querySelectorAll('option')).map(o => o.value);
      choicesInstances[inputId].setChoiceByValue(allValues);
    } else {
      Array.from(input.options).forEach(o => o.selected = true);
    }
    input.dispatchEvent(new Event('change'));
  }

  function clearAll(inputId) {
    const input = document.getElementById(inputId);
    if (!input) return;
    if (choicesInstances[inputId]) {
      choicesInstances[inputId].removeActiveItems();
    } else {
      Array.from(input.options).forEach(o => o.selected = false);
    }
    input.dispatchEvent(new Event('change'));
  }
  
  // =================================================================
  // Utility Functions: Reset, Select All, Clear All
  // =================================================================

  /**
   * Reset filters to their default values
   */
  function resetFilters(button) {
    const targetsAttr = button.dataset.targets;
    const targets = targetsAttr === 'all' ? Object.keys(defaultValues) : 
                    targetsAttr.split(',').map(t => t.trim());
    
    targets.forEach(inputId => {
      const defaults = defaultValues[inputId];
      const state = inputState[inputId];
      if (!defaults || !state) return;
      
      const element = document.getElementById(inputId);
      if (!element) return;
      
      if (state.inputType === 'select') {
        // Reset select to default values
        if (choicesInstances[inputId]) {
          choicesInstances[inputId].removeActiveItems();
          if (defaults.selected && defaults.selected.length > 0) {
            choicesInstances[inputId].setChoiceByValue(defaults.selected);
          }
        } else if (element.tagName === 'SELECT') {
          Array.from(element.options).forEach(opt => {
            opt.selected = defaults.selected.includes(opt.value);
          });
        }
        inputState[inputId].selected = defaults.selected.slice();
      } else if (state.inputType === 'checkbox') {
        const checkboxes = element.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(cb => {
          cb.checked = defaults.selected.includes(cb.value);
        });
        inputState[inputId].selected = defaults.selected.slice();
      } else if (state.inputType === 'radio') {
        const radios = element.querySelectorAll('input[type="radio"]');
        radios.forEach(radio => {
          radio.checked = defaults.selected.includes(radio.value);
        });
        inputState[inputId].selected = defaults.selected.slice();
      } else if (state.inputType === 'switch') {
        element.checked = defaults.value;
        inputState[inputId].value = defaults.value;
        inputState[inputId].selected = defaults.value ? ['true'] : ['false'];
      } else if (state.inputType === 'slider') {
        element.value = defaults.value;
        inputState[inputId].value = defaults.value;
        inputState[inputId].selected = [String(defaults.value)];
        updateSliderTrack(element);
        updateSliderDisplay(inputId, element, state.labels, defaults.value, state.min, state.step);
      } else if (state.inputType === 'text' || state.inputType === 'number') {
        element.value = defaults.value;
        inputState[inputId].value = defaults.value;
        inputState[inputId].selected = [String(defaults.value)];
      } else if (state.inputType === 'button_group') {
        const buttons = element.querySelectorAll('.dashboardr-button-option');
        buttons.forEach(btn => {
          btn.classList.toggle('active', defaults.selected.includes(btn.dataset.value));
        });
        inputState[inputId].selected = defaults.selected.slice();
      }
    });
    
    applyAllFilters();
  }

  /**
   * Rebuild chart from cross-tab data based on current filters
   * This enables true client-side data filtering by re-aggregating from pre-computed cross-tab
   * 
   * @param {Object} entry - Chart registry entry
   * @param {Object} crossTabInfo - Object with data array and config
   * @param {Object} filters - Current filter selections (filterVar -> selected values)
   * @param {Object} sliderFilters - Current slider filter states (filterVar -> {value, min, max, step, labels})
   * @param {Object} textFilters - Current text filters (filterVar -> lowercase text)
   * @param {Object} numberFilters - Current number filters (filterVar -> numeric value)
   * @param {Object} switchOverrides - Switch-controlled series per filterVar ({filterVar -> [{seriesName, visible, override}]})
   * @returns {boolean} True if chart was rebuilt, false if cross-tab doesn't apply
   */
  function rebuildFromCrossTab(entry, crossTabInfo, filters, sliderFilters, textFilters, numberFilters, switchOverrides, dateFilters, daterangeFilters) {
    if (!crossTabInfo || !crossTabInfo.data || !crossTabInfo.config) {
      return false;
    }
    
    const { data, config } = crossTabInfo;
    let filterVars = config.filterVars;
    if (typeof filterVars === 'string') filterVars = [filterVars];
    if (!Array.isArray(filterVars)) filterVars = [];

    // ---- Shared Step 1: Filter the cross-tab data based on filter selections ----
    let filteredData = data.slice();

    // Common "All" labels that mean "don't filter" (case-insensitive)
    const allLabels = ['all', 'alle', 'tous', 'todo', 'tutti', 'すべて', '全部'];

    for (const filterVar of filterVars) {
      // Collect switch-overridden series names for this filterVar
      // These series should always be included in the data when their switch is ON
      const overrideSeriesNames = new Set();
      if (switchOverrides && switchOverrides[filterVar]) {
        switchOverrides[filterVar].forEach(sw => {
          if (sw.visible && sw.override) {
            overrideSeriesNames.add(sw.seriesName);
          }
        });
      }
      // Determine which column holds the series/group name for override matching
      const groupCol = config.groupVar || config.stackVar;
      
      // First check regular filters (select, checkbox, radio)
      const selectedValues = filters[filterVar];
      if (selectedValues && selectedValues.length > 0) {
        const hasAllOption = selectedValues.some(v => 
          allLabels.includes(String(v).toLowerCase())
        );
        if (hasAllOption) {
          continue; // Don't filter on this variable
        }
        
        filteredData = filteredData.filter(row => {
          const rowValue = String(row[filterVar]);
          // Include if value is selected OR if it's an override series that's toggled on
          if (selectedValues.includes(rowValue)) return true;
          if (overrideSeriesNames.size > 0 && groupCol) {
            const groupValue = String(row[groupCol]);
            if (overrideSeriesNames.has(groupValue)) return true;
          }
          return false;
        });
        continue;
      }
      
      // Then check slider filters
      const sliderInfo = sliderFilters && sliderFilters[filterVar];
      if (sliderInfo) {
        const sliderValue = sliderInfo.value;
        if (sliderInfo.labels && sliderInfo.labels.length > 0) {
          // Slider with labels: include values from the selected position onwards
          // Use slider min/step metadata when available to resolve label index.
          const selectedIndex = resolveSliderLabelIndex(sliderInfo);
          const allowedLabels = sliderInfo.labels.slice(selectedIndex);
          filteredData = filteredData.filter(row => {
            const rowValue = String(row[filterVar]);
            return allowedLabels.includes(rowValue);
          });
        } else {
          // Numeric slider: filter rows where value >= slider value
          filteredData = filteredData.filter(row => {
            const rowValue = Number(row[filterVar]);
            return !isNaN(rowValue) && rowValue >= sliderValue;
          });
        }
      }

      // Then text filters (partial match, case-insensitive)
      const textValue = textFilters && textFilters[filterVar];
      if (textValue) {
        filteredData = filteredData.filter(row =>
          String(row[filterVar]).toLowerCase().includes(textValue)
        );
      }

      // Then number filters (exact match)
      const numberValue = numberFilters && numberFilters[filterVar];
      if (numberValue !== undefined && numberValue !== null && numberValue !== '') {
        filteredData = filteredData.filter(row =>
          String(row[filterVar]) === String(numberValue)
        );
      }

      // Date filter (exact match on parsed date)
      var dateValue = dateFilters && dateFilters[filterVar];
      if (dateValue) {
        filteredData = filteredData.filter(function(row) {
          var parsed = _parseDateLike(String(row[filterVar]));
          return parsed === dateValue;
        });
      }

      // Date range filter (start <= date <= end)
      var drInfo = daterangeFilters && daterangeFilters[filterVar];
      if (drInfo) {
        filteredData = filteredData.filter(function(row) {
          var parsed = _parseDateLike(String(row[filterVar]));
          if (!parsed) return false;
          if (drInfo.start && parsed < drInfo.start) return false;
          if (drInfo.end && parsed > drInfo.end) return false;
          return true;
        });
      }
    }
    
    // ---- Branch by backend + chart type ----
    const backend = entry && entry.backend ? entry.backend : 'highcharter';
    if (backend === 'highcharter') {
      const chart = chartRegistry && chartRegistry.resolveHighchart ? chartRegistry.resolveHighchart(entry) : null;
      if (!chart) return false;
      let ok = false;
      if (config.chartType === 'timeline') {
        ok = _rebuildTimelineSeries(chart, filteredData, config);
      } else if (config.chartType === 'bar') {
        ok = _rebuildBarSeries(chart, filteredData, config);
      } else if (config.chartType === 'pie') {
        ok = _rebuildPieSeries(chart, filteredData, config);
      } else if (config.chartType === 'scatter') {
        ok = _rebuildScatterSeries(chart, filteredData, config);
      } else if (config.chartType === 'boxplot') {
        ok = _rebuildBoxplotSeries(chart, filteredData, config);
      } else {
        ok = _rebuildStackedBarSeries(chart, filteredData, config);
      }
      if (ok && switchOverrides) {
        Object.keys(switchOverrides).forEach(filterVar => {
          switchOverrides[filterVar].forEach(sw => {
            (chart.series || []).forEach(series => {
              if (!series || typeof series !== 'object') return;
              if (series.name === sw.seriesName) {
                if (!sw.visible) {
                  series.setVisible(false, false);
                  series.update({ showInLegend: false }, false);
                } else {
                  series.setVisible(true, false);
                  series.update({ showInLegend: true }, false);
                }
              }
            });
          });
        });
        chart.redraw();
      }
      return ok;
    }
    if (backend === 'plotly') {
      if (config.chartType === 'timeline') {
        return _rebuildTimelinePlotly(entry, filteredData, config, switchOverrides);
      }
      if (config.chartType === 'bar') {
        return _rebuildBarPlotly(entry, filteredData, config, switchOverrides);
      }
      if (config.chartType === 'pie') {
        return _rebuildPiePlotly(entry, filteredData, config);
      }
      if (config.chartType === 'scatter') {
        return _rebuildScatterPlotly(entry, filteredData, config);
      }
      if (config.chartType === 'boxplot') {
        return _rebuildBoxplotPlotly(entry, filteredData, config);
      }
      return _rebuildStackedBarPlotly(entry, filteredData, config, switchOverrides);
    }
    if (backend === 'echarts4r') {
      if (config.chartType === 'timeline') {
        return _rebuildTimelineEcharts(entry, filteredData, config, switchOverrides);
      }
      if (config.chartType === 'bar') {
        return _rebuildBarEcharts(entry, filteredData, config, switchOverrides);
      }
      if (config.chartType === 'pie') {
        return _rebuildPieEcharts(entry, filteredData, config);
      }
      if (config.chartType === 'scatter') {
        return _rebuildScatterEcharts(entry, filteredData, config);
      }
      if (config.chartType === 'boxplot') {
        return _rebuildBoxplotEcharts(entry, filteredData, config);
      }
      return _rebuildStackedBarEcharts(entry, filteredData, config, switchOverrides);
    }
    return false;
  }

  function _rebuildBarPlotly(entry, filteredData, config, switchOverrides) {
    if (!entry || !entry.el || typeof Plotly === 'undefined') return false;
    if (!entry.original || !entry.original.data) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.plotly) {
        chartRegistry.adapters.plotly.storeOriginal(entry);
      }
    }
    const original = entry.original && entry.original.data ? entry.original : { data: entry.el.data || [], layout: entry.el.layout || {} };
    const data = original.data || [];
    const xVar = config.xVar;
    let groupVar = config.groupVar;
    if (groupVar && typeof groupVar === 'object' && !Array.isArray(groupVar) && Object.keys(groupVar).length === 0) {
      groupVar = null;
    }
    const xOrder = config.xOrder;
    const groupOrder = config.groupOrder;
    const isHorizontal = data.some(t => t && t.orientation === 'h');

    const switchHidden = new Set();
    const switchShown = new Set();
    if (switchOverrides) {
      Object.keys(switchOverrides).forEach(filterVar => {
        switchOverrides[filterVar].forEach(sw => {
          const seriesName = normalizeSeriesName(sw.seriesName);
          if (!seriesName) return;
          if (!sw.visible) switchHidden.add(seriesName);
          else if (sw.override) switchShown.add(seriesName);
        });
      });
    }

    let traces = [];

    if (groupVar) {
      const summed = {};
      filteredData.forEach(row => {
        const xVal = String(row[xVar]);
        const rawGroup = row[groupVar];
        const gVal = normalizeSeriesName(rawGroup);
        if (!gVal) return;
        const key = xVal + '|||' + gVal;
        if (!summed[key]) summed[key] = { xVal, gVal, n: 0 };
        summed[key].n += row.n;
      });

      const byX = {};
      Object.values(summed).forEach(item => {
        if (!byX[item.xVal]) byX[item.xVal] = {};
        byX[item.xVal][item.gVal] = item.n;
      });

      const activeXValues = new Set(Object.keys(byX));
      const orderedX = xOrder && xOrder.length > 0
        ? xOrder.filter(xv => activeXValues.has(xv))
        : Object.keys(byX);
      const activeGroups = uniqueNonEmptyNames(Object.values(summed).map(s => s.gVal));
      const orderedGroupsRaw = groupOrder && groupOrder.length > 0
        ? groupOrder.filter(g => activeGroups.includes(g))
        : activeGroups;
      const orderedGroups = uniqueNonEmptyNames(orderedGroupsRaw);
      const traceOrder = uniqueNonEmptyNames(data.map(t => t && t.name));
      const seriesOrder = traceOrder.length
        ? traceOrder.filter(name => orderedGroups.includes(name))
        : orderedGroups;
      const allGroups = uniqueNonEmptyNames([...seriesOrder, ...orderedGroups, ...Array.from(switchShown)]);

      traces = allGroups.map(groupName => {
        const orig = data.find(t => normalizeSeriesName(t && t.name) === groupName);
        const trace = orig ? (chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(orig) : JSON.parse(JSON.stringify(orig))) : {};
        trace.type = trace.type || 'bar';
        trace.name = groupName;

        if (orderedGroups.includes(groupName)) {
          const values = orderedX.map(xVal => (byX[xVal] && byX[xVal][groupName]) ? byX[xVal][groupName] : 0);
          if (isHorizontal) {
            trace.y = orderedX;
            trace.x = values;
            trace.orientation = 'h';
          } else {
            trace.x = orderedX;
            trace.y = values;
          }
          trace.visible = true;
          trace.showlegend = true;
        } else {
          if (isHorizontal) {
            trace.y = orderedX;
            trace.x = orderedX.map(() => 0);
            trace.orientation = 'h';
          } else {
            trace.x = orderedX;
            trace.y = orderedX.map(() => 0);
          }
          trace.visible = 'legendonly';
        }

        if (switchHidden.has(groupName)) trace.visible = 'legendonly';
        if (switchShown.has(groupName)) trace.visible = true;
        return trace;
      });

      const layoutGrouped = original.layout || entry.el.layout || {};
      if (isHorizontal) {
        layoutGrouped.yaxis = layoutGrouped.yaxis || {};
        layoutGrouped.yaxis.categoryorder = 'array';
        layoutGrouped.yaxis.categoryarray = orderedX;
      } else {
        layoutGrouped.xaxis = layoutGrouped.xaxis || {};
        layoutGrouped.xaxis.categoryorder = 'array';
        layoutGrouped.xaxis.categoryarray = orderedX;
      }
      layoutGrouped.barmode = layoutGrouped.barmode || 'group';
      Plotly.react(entry.el, traces, layoutGrouped);
      return true;
    }

    // Simple (ungrouped) bar
    const counts = {};
    filteredData.forEach(row => {
      const xVal = String(row[xVar]);
      if (!counts[xVal]) counts[xVal] = 0;
      counts[xVal] += row.n;
    });

    const activeX = new Set(Object.keys(counts));
    const orderedXSimple = xOrder && xOrder.length > 0
      ? xOrder.filter(xv => activeX.has(xv))
      : Object.keys(counts);
    const seriesValues = orderedXSimple.map(xVal => counts[xVal] || 0);
    const origSimple = data[0] || {};
    const traceSimple = chartRegistry && chartRegistry.deepClone
      ? chartRegistry.deepClone(origSimple)
      : JSON.parse(JSON.stringify(origSimple));
    traceSimple.type = traceSimple.type || 'bar';
    traceSimple.visible = true;
    if (isHorizontal) {
      traceSimple.y = orderedXSimple;
      traceSimple.x = seriesValues;
      traceSimple.orientation = 'h';
    } else {
      traceSimple.x = orderedXSimple;
      traceSimple.y = seriesValues;
    }

    const layoutSimple = original.layout || entry.el.layout || {};
    if (isHorizontal) {
      layoutSimple.yaxis = layoutSimple.yaxis || {};
      layoutSimple.yaxis.categoryorder = 'array';
      layoutSimple.yaxis.categoryarray = orderedXSimple;
    } else {
      layoutSimple.xaxis = layoutSimple.xaxis || {};
      layoutSimple.xaxis.categoryorder = 'array';
      layoutSimple.xaxis.categoryarray = orderedXSimple;
    }
    Plotly.react(entry.el, [traceSimple], layoutSimple);
    return true;
  }

  function _rebuildPiePlotly(entry, filteredData, config) {
    if (!entry || !entry.el || typeof Plotly === 'undefined') return false;
    if (!entry.original || !entry.original.data) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.plotly) {
        chartRegistry.adapters.plotly.storeOriginal(entry);
      }
    }
    const original = entry.original && entry.original.data ? entry.original : { data: entry.el.data || [], layout: entry.el.layout || {} };
    const data = original.data || [];
    const xVar = config.xVar;
    if (!xVar) return false;

    const counts = {};
    filteredData.forEach(row => {
      const label = String(row[xVar]);
      if (!counts[label]) counts[label] = 0;
      counts[label] += Number(row.n) || 0;
    });

    const activeLabels = new Set(Object.keys(counts));
    const labels = Array.isArray(config.xOrder) && config.xOrder.length > 0
      ? config.xOrder.filter(lbl => activeLabels.has(lbl))
      : Object.keys(counts);
    const values = labels.map(lbl => counts[lbl] || 0);

    const trace = data[0]
      ? (chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(data[0]) : JSON.parse(JSON.stringify(data[0])))
      : {};
    trace.type = 'pie';
    trace.labels = labels;
    trace.values = values;
    trace.visible = true;
    if (config.colorMap && typeof config.colorMap === 'object') {
      trace.marker = trace.marker || {};
      trace.marker.colors = labels.map(lbl => config.colorMap[lbl] || null).filter(v => v !== null);
    }

    const layout = original.layout || entry.el.layout || {};
    Plotly.react(entry.el, [trace], layout);
    return true;
  }

  function _rebuildScatterPlotly(entry, filteredData, config) {
    if (!entry || !entry.el || typeof Plotly === 'undefined') return false;
    if (!entry.original || !entry.original.data) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.plotly) {
        chartRegistry.adapters.plotly.storeOriginal(entry);
      }
    }
    const original = entry.original && entry.original.data ? entry.original : { data: entry.el.data || [], layout: entry.el.layout || {} };
    const data = original.data || [];

    const xVar = config.xVar;
    const yVar = config.yVar;
    const groupVar = config.groupVar;
    const sizeVar = config.sizeVar;
    if (!xVar || !yVar) return false;

    const rows = filteredData.filter(row => _toFiniteNumber(row[xVar]) !== null && _toFiniteNumber(row[yVar]) !== null);
    let traces = [];

    if (groupVar) {
      const activeGroups = uniqueNonEmptyNames(rows.map(row => row[groupVar]));
      const orderedGroups = Array.isArray(config.groupOrder) && config.groupOrder.length > 0
        ? uniqueNonEmptyNames(config.groupOrder).filter(g => activeGroups.includes(g))
        : activeGroups;
      const traceOrder = uniqueNonEmptyNames(data.map(t => t && t.name));
      const groups = traceOrder.length
        ? uniqueNonEmptyNames([...traceOrder.filter(g => orderedGroups.includes(g)), ...orderedGroups])
        : orderedGroups;

      traces = groups.map(groupName => {
        const orig = data.find(t => normalizeSeriesName(t && t.name) === groupName);
        const trace = orig ? (chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(orig) : JSON.parse(JSON.stringify(orig))) : {};
        const groupRows = rows.filter(row => normalizeSeriesName(row[groupVar]) === groupName);
        trace.type = 'scatter';
        trace.mode = trace.mode || 'markers';
        trace.name = groupName;
        trace.x = groupRows.map(row => Number(row[xVar]));
        trace.y = groupRows.map(row => Number(row[yVar]));
        trace.marker = trace.marker || {};
        if (sizeVar) {
          trace.marker.size = groupRows.map(row => {
            const val = _toFiniteNumber(row[sizeVar]);
            return val !== null ? val : (config.pointSize || 4);
          });
        } else if (!trace.marker.size) {
          trace.marker.size = config.pointSize || 4;
        }
        if (config.alpha != null && trace.marker.opacity == null) {
          trace.marker.opacity = config.alpha;
        }
        if (config.colorMap && config.colorMap[groupName]) {
          trace.marker.color = config.colorMap[groupName];
        }
        trace.visible = true;
        return trace;
      });
    } else {
      const orig = data[0] || {};
      const trace = chartRegistry && chartRegistry.deepClone
        ? chartRegistry.deepClone(orig)
        : JSON.parse(JSON.stringify(orig));
      trace.type = 'scatter';
      trace.mode = trace.mode || 'markers';
      trace.x = rows.map(row => Number(row[xVar]));
      trace.y = rows.map(row => Number(row[yVar]));
      trace.marker = trace.marker || {};
      if (sizeVar) {
        trace.marker.size = rows.map(row => {
          const val = _toFiniteNumber(row[sizeVar]);
          return val !== null ? val : (config.pointSize || 4);
        });
      } else if (!trace.marker.size) {
        trace.marker.size = config.pointSize || 4;
      }
      if (config.alpha != null && trace.marker.opacity == null) {
        trace.marker.opacity = config.alpha;
      }
      traces = [trace];
    }

    const layout = original.layout || entry.el.layout || {};
    Plotly.react(entry.el, traces, layout);
    return true;
  }

  function _rebuildBoxplotPlotly(entry, filteredData, config) {
    if (!entry || !entry.el || typeof Plotly === 'undefined') return false;
    if (!entry.original || !entry.original.data) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.plotly) {
        chartRegistry.adapters.plotly.storeOriginal(entry);
      }
    }
    const original = entry.original && entry.original.data ? entry.original : { data: entry.el.data || [], layout: entry.el.layout || {} };
    const data = original.data || [];
    const xVar = config.xVar;
    const yVar = config.yVar;
    if (!xVar || !yVar) return false;

    const grouped = {};
    filteredData.forEach(row => {
      const group = String(row[xVar]);
      const y = _toFiniteNumber(row[yVar]);
      if (y === null) return;
      if (!grouped[group]) grouped[group] = [];
      grouped[group].push(y);
    });

    const activeGroups = Object.keys(grouped);
    const groups = Array.isArray(config.xOrder) && config.xOrder.length > 0
      ? config.xOrder.filter(g => activeGroups.includes(g))
      : activeGroups;
    const horizontal = !!config.horizontal;
    const showOutliers = config.showOutliers !== false;

    const traces = groups.map(group => {
      const orig = data.find(t => normalizeSeriesName(t && t.name) === normalizeSeriesName(group));
      const trace = orig ? (chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(orig) : JSON.parse(JSON.stringify(orig))) : {};
      const values = grouped[group] || [];
      trace.type = 'box';
      trace.name = group;
      trace.boxpoints = showOutliers ? 'outliers' : false;
      if (horizontal) {
        trace.orientation = 'h';
        trace.x = values;
        trace.y = Array(values.length).fill(group);
      } else {
        trace.orientation = 'v';
        trace.x = Array(values.length).fill(group);
        trace.y = values;
      }
      if (config.colorMap && config.colorMap[group]) {
        trace.marker = trace.marker || {};
        trace.line = trace.line || {};
        trace.marker.color = config.colorMap[group];
        trace.line.color = config.colorMap[group];
      }
      return trace;
    });

    const layout = original.layout || entry.el.layout || {};
    if (horizontal) {
      layout.yaxis = layout.yaxis || {};
      layout.yaxis.type = 'category';
      layout.yaxis.categoryorder = 'array';
      layout.yaxis.categoryarray = groups;
    } else {
      layout.xaxis = layout.xaxis || {};
      layout.xaxis.type = 'category';
      layout.xaxis.categoryorder = 'array';
      layout.xaxis.categoryarray = groups;
    }
    Plotly.react(entry.el, traces, layout);
    return true;
  }

  function _rebuildStackedBarPlotly(entry, filteredData, config, switchOverrides) {
    if (!entry || !entry.el || typeof Plotly === 'undefined') return false;
    if (!entry.original || !entry.original.data) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.plotly) {
        chartRegistry.adapters.plotly.storeOriginal(entry);
      }
    }
    const original = entry.original && entry.original.data ? entry.original : { data: entry.el.data || [], layout: entry.el.layout || {} };
    const data = original.data || [];

    const { xVar, stackVar, stackedType, stackOrder, xOrder, colorMap } = config;
    const seriesVar = stackVar || config.groupVar;
    var labelDec = (config.labelDecimals != null) ? config.labelDecimals : (stackedType === 'percent' ? 1 : 0);
    var labelMinPct = 5;
    const summed = {};
    filteredData.forEach(row => {
      const xVal = String(row[xVar]);
      const rawSeries = row[seriesVar];
      const stackVal = normalizeSeriesName(rawSeries);
      if (!stackVal) return;
      const key = xVal + '|||' + stackVal;
      if (!summed[key]) summed[key] = { xVal, stackVal, n: 0 };
      summed[key].n += row.n;
    });
    const byX = {};
    Object.values(summed).forEach(item => {
      if (!byX[item.xVal]) byX[item.xVal] = {};
      byX[item.xVal][item.stackVal] = item.n;
    });
    const xTotals = {};
    Object.keys(byX).forEach(xVal => {
      xTotals[xVal] = Object.values(byX[xVal]).reduce((sum, n) => sum + n, 0);
    });
    const isPercent = stackedType === 'percent';
    const activeXValues = new Set(Object.keys(byX));
    const orderedX = xOrder && xOrder.length > 0 ? xOrder.filter(xv => activeXValues.has(xv)) : Object.keys(byX);
    const activeStackValues = new Set(Object.values(summed).map(s => s.stackVal));
    const orderedStackRaw = stackOrder && stackOrder.length > 0
      ? stackOrder.filter(sv => activeStackValues.has(sv))
      : [...activeStackValues];
    const orderedStack = uniqueNonEmptyNames(orderedStackRaw);

    const switchHidden = new Set();
    const switchShown = new Set();
    if (switchOverrides) {
      Object.keys(switchOverrides).forEach(filterVar => {
        switchOverrides[filterVar].forEach(sw => {
          const seriesName = normalizeSeriesName(sw.seriesName);
          if (!seriesName) return;
          if (!sw.visible) switchHidden.add(seriesName);
          else if (sw.override) switchShown.add(seriesName);
        });
      });
    }
    const traceOrder = uniqueNonEmptyNames(data.map(t => t && t.name));
    const seriesOrder = traceOrder.length
      ? traceOrder.filter(name => orderedStack.includes(name))
      : orderedStack;
    const allSeries = uniqueNonEmptyNames([...seriesOrder, ...orderedStack, ...Array.from(switchShown)]);
    const isHorizontal = data.some(t => t && t.orientation === 'h');

    const newData = allSeries.map(name => {
      const orig = data.find(t => t.name === name);
      const trace = orig ? (chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(orig) : JSON.parse(JSON.stringify(orig))) : {};
      trace.type = trace.type || 'bar';
      trace.name = name;
      if (orderedStack.includes(name)) {
        var factor = Math.pow(10, labelDec);
        const values = orderedX.map(xVal => {
          const count = (byX[xVal] && byX[xVal][name]) ? byX[xVal][name] : 0;
          if (isPercent && xTotals[xVal] > 0) {
            return Math.round(((count / xTotals[xVal]) * 100) * factor) / factor;
          }
          return count;
        });
        // Generate text labels, hiding small segments
        const labels = values.map((v, i) => {
          var pct = xTotals[orderedX[i]] > 0 ? (v / (isPercent ? 100 : xTotals[orderedX[i]])) * 100 : 0;
          if (isPercent) pct = v;
          if (pct < labelMinPct) return '';
          return v.toFixed(labelDec) + (isPercent ? '%' : '');
        });
        if (isHorizontal) {
          trace.y = orderedX;
          trace.x = values;
          trace.orientation = 'h';
        } else {
          trace.x = orderedX;
          trace.y = values;
        }
        trace.text = labels;
        trace.textposition = 'inside';
        trace.visible = true;
        trace.showlegend = true;
        if (colorMap && colorMap[name]) {
          trace.marker = trace.marker || {};
          trace.marker.color = colorMap[name];
        }
      } else {
        if (isHorizontal) {
          trace.y = orderedX;
          trace.x = orderedX.map(() => 0);
          trace.orientation = 'h';
        } else {
          trace.x = orderedX;
          trace.y = orderedX.map(() => 0);
        }
        trace.visible = 'legendonly';
      }
      if (switchHidden.has(name)) trace.visible = 'legendonly';
      if (switchShown.has(name)) trace.visible = true;
      return trace;
    });

    const layout = original.layout || entry.el.layout || {};
    if (isHorizontal) {
      layout.yaxis = layout.yaxis || {};
      layout.yaxis.categoryorder = 'array';
      layout.yaxis.categoryarray = orderedX;
    } else {
      layout.xaxis = layout.xaxis || {};
      layout.xaxis.categoryorder = 'array';
      layout.xaxis.categoryarray = orderedX;
    }
    Plotly.react(entry.el, newData, layout);
    return true;
  }

  function _rebuildTimelinePlotly(entry, filteredData, config, switchOverrides) {
    if (!entry || !entry.el || typeof Plotly === 'undefined') return false;
    if (!entry.original || !entry.original.data) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.plotly) {
        chartRegistry.adapters.plotly.storeOriginal(entry);
      }
    }
    const original = entry.original && entry.original.data ? entry.original : { data: entry.el.data || [], layout: entry.el.layout || {} };
    const data = original.data || [];

    const timeVar = config.timeVar;
    const groupVar = config.groupVar;
    const valueCol = 'value';

    const timeValues = Array.from(new Set(filteredData.map(r => r[timeVar]))).map(v => v);
    const numericTime = timeValues.every(v => v !== null && v !== '' && !isNaN(Number(v)));
    if (numericTime) timeValues.sort((a, b) => Number(a) - Number(b));

    const activeGroups = groupVar
      ? uniqueNonEmptyNames(filteredData.map(r => r[groupVar]))
      : [];
    let groupValues = groupVar
      ? (Array.isArray(config.groupOrder) && config.groupOrder.length
          ? uniqueNonEmptyNames(config.groupOrder).filter(g => activeGroups.includes(g))
          : activeGroups)
      : [String(config.yVar || 'value')];

    const switchHidden = new Set();
    const switchShown = new Set();
    if (switchOverrides) {
      Object.keys(switchOverrides).forEach(filterVar => {
        switchOverrides[filterVar].forEach(sw => {
          const seriesName = normalizeSeriesName(sw.seriesName);
          if (!seriesName) return;
          if (!sw.visible) switchHidden.add(seriesName);
          else if (sw.override) switchShown.add(seriesName);
        });
      });
    }
    if (groupVar && switchShown.size > 0) {
      groupValues = uniqueNonEmptyNames([...groupValues, ...Array.from(switchShown)]);
    }

    const traces = [];
    groupValues.forEach(group => {
      const orig = data.find(t => t.name === String(group));
      const trace = orig ? (chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(orig) : JSON.parse(JSON.stringify(orig))) : {};
      trace.name = String(group);
      const rows = groupVar ? filteredData.filter(r => String(r[groupVar]) === String(group)) : filteredData;
      const byTime = {};
      rows.forEach(r => { byTime[String(r[timeVar])] = r[valueCol]; });
      trace.x = timeValues;
      trace.y = timeValues.map(t => {
        const v = byTime[String(t)];
        return v !== undefined ? v : null;
      });
      if (switchHidden.has(trace.name)) trace.visible = 'legendonly';
      if (switchShown.has(trace.name)) trace.visible = true;
      traces.push(trace);
    });

    const layout = original.layout || entry.el.layout || {};
    layout.xaxis = layout.xaxis || {};
    layout.xaxis.categoryorder = 'array';
    layout.xaxis.categoryarray = timeValues;
    Plotly.react(entry.el, traces, layout);
    return true;
  }

  function _rebuildStackedBarEcharts(entry, filteredData, config, switchOverrides) {
    if (!entry || !entry.el || typeof echarts === 'undefined') return false;
    const inst = echarts.getInstanceByDom(entry.el);
    if (!inst) return false;
    if (!entry.original || !entry.original.option) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.echarts4r) {
        chartRegistry.adapters.echarts4r.storeOriginal(entry);
      }
    }
    const original = entry.original && entry.original.option ? entry.original.option : inst.getOption();
    if (!original) return false;

    const { xVar, stackVar, stackedType, stackOrder, xOrder, colorMap } = config;
    const seriesVar = stackVar || config.groupVar;
    var labelDec = (config.labelDecimals != null) ? config.labelDecimals : (stackedType === 'percent' ? 1 : 0);
    var labelMinPct = 5; // hide labels on segments < 5% of their stack
    const summed = {};
    filteredData.forEach(row => {
      const xVal = String(row[xVar]);
      const rawSeries = row[seriesVar];
      const stackVal = normalizeSeriesName(rawSeries);
      if (!stackVal) return;
      const key = xVal + '|||' + stackVal;
      if (!summed[key]) summed[key] = { xVal, stackVal, n: 0 };
      summed[key].n += row.n;
    });
    const byX = {};
    Object.values(summed).forEach(item => {
      if (!byX[item.xVal]) byX[item.xVal] = {};
      byX[item.xVal][item.stackVal] = item.n;
    });
    const xTotals = {};
    Object.keys(byX).forEach(xVal => {
      xTotals[xVal] = Object.values(byX[xVal]).reduce((sum, n) => sum + n, 0);
    });
    const isPercent = stackedType === 'percent';
    const activeXValues = new Set(Object.keys(byX));
    const orderedX = xOrder && xOrder.length > 0 ? xOrder.filter(xv => activeXValues.has(xv)) : Object.keys(byX);
    const activeStackValues = new Set(Object.values(summed).map(s => s.stackVal));
    const orderedStackRaw = stackOrder && stackOrder.length > 0
      ? stackOrder.filter(sv => activeStackValues.has(sv))
      : [...activeStackValues];
    const orderedStack = uniqueNonEmptyNames(orderedStackRaw);

    const switchHidden = new Set();
    const switchShown = new Set();
    if (switchOverrides) {
      Object.keys(switchOverrides).forEach(filterVar => {
        switchOverrides[filterVar].forEach(sw => {
          const seriesName = normalizeSeriesName(sw.seriesName);
          if (!seriesName) return;
          if (!sw.visible) switchHidden.add(seriesName);
          else if (sw.override) switchShown.add(seriesName);
        });
      });
    }

    const option = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(original) : JSON.parse(JSON.stringify(original));

    // Rebuilt series use explicit arrays; avoid stale dataset/encode mappings from htmlwidgets.
    if (option.dataset) delete option.dataset;

    const xAxisCfg = Array.isArray(option.xAxis)
      ? (option.xAxis[0] = option.xAxis[0] || {})
      : (option.xAxis = option.xAxis || {});
    const yAxisCfg = Array.isArray(option.yAxis)
      ? (option.yAxis[0] = option.yAxis[0] || {})
      : (option.yAxis = option.yAxis || {});

    const originalXAxis = Array.isArray(original.xAxis) ? (original.xAxis[0] || {}) : (original.xAxis || {});
    const originalYAxis = Array.isArray(original.yAxis) ? (original.yAxis[0] || {}) : (original.yAxis || {});
    const isHorizontal = String(originalYAxis.type || '').toLowerCase() === 'category' ||
      (String(originalXAxis.type || '').toLowerCase() === 'value' &&
       String(originalYAxis.type || '').toLowerCase() === 'category');

    if (isHorizontal) {
      yAxisCfg.type = 'category';
      yAxisCfg.data = orderedX;
      xAxisCfg.type = 'value';
      xAxisCfg.data = null;
      if (isPercent) {
        xAxisCfg.min = 0;
        xAxisCfg.max = 100;
      } else {
        if (xAxisCfg.max === 100) delete xAxisCfg.max;
      }
    } else {
      xAxisCfg.type = 'category';
      xAxisCfg.data = orderedX;
      yAxisCfg.type = 'value';
      yAxisCfg.data = null;
      if (isPercent) {
        yAxisCfg.min = 0;
        yAxisCfg.max = 100;
      } else {
        if (yAxisCfg.max === 100) delete yAxisCfg.max;
      }
    }

    const baseSeries = (option.series || [])
      .filter(s => s && typeof s === 'object')
      .map(series => {
        const name = normalizeSeriesName(series.name);
        if (!name) return null;
        series.name = name;
        return series;
      })
      .filter(Boolean);
    const originalSeries = (original.series || [])
      .filter(s => s && typeof s === 'object')
      .map(series => {
        const name = normalizeSeriesName(series.name);
        if (!name) return null;
        series.name = name;
        return series;
      })
      .filter(Boolean);
    const series = baseSeries.map(s => s.name);
    const seriesOrder = series.length
      ? series.filter(name => orderedStack.includes(name))
      : orderedStack;
    const allSeries = uniqueNonEmptyNames([...seriesOrder, ...orderedStack, ...Array.from(switchShown)]);
    const visibleSeries = allSeries.filter(name => !switchHidden.has(name) || switchShown.has(name));

    option.series = visibleSeries.map(name => {
      const orig = originalSeries.find(s => s && s.name === name) || {};
      const s = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(orig) : JSON.parse(JSON.stringify(orig));
      s.name = name;
      s.type = s.type || 'bar';
      if (s.encode) delete s.encode;
      if (s.datasetIndex !== undefined) delete s.datasetIndex;
      if (orderedStack.includes(name)) {
        var factor = Math.pow(10, labelDec);
        const values = orderedX.map(xVal => {
          const count = (byX[xVal] && byX[xVal][name]) ? byX[xVal][name] : 0;
          if (isPercent && xTotals[xVal] > 0) {
            return Math.round(((count / xTotals[xVal]) * 100) * factor) / factor;
          }
          return count;
        });
        if (isHorizontal) {
          s.data = orderedX.map((xVal, idx) => [values[idx], xVal]);
        } else {
          s.data = values;
        }
        s.show = true;
        if (colorMap && colorMap[name]) {
          s.itemStyle = s.itemStyle || {};
          s.itemStyle.color = colorMap[name];
        }
        // Update label formatter to round and hide small segments
        s.label = s.label || {};
        s.label.show = true;
        s.label.position = isHorizontal ? 'insideRight' : 'inside';
        var valIdx = isHorizontal ? 0 : 1;
        s.label.formatter = new Function('params',
          'var v = Array.isArray(params.value) ? Number(params.value[' + valIdx + ']) : Number(params.value);' +
          'if (!isFinite(v) || v === 0 || v < ' + labelMinPct + ') return "";' +
          'return v.toFixed(' + labelDec + ')' + (isPercent ? ' + "%"' : '') + ';'
        );
      } else {
        if (isHorizontal) {
          s.data = orderedX.map(xVal => [0, xVal]);
        } else {
          s.data = orderedX.map(() => 0);
        }
      }
      return s;
    });
    syncEchartsLegend(option, visibleSeries);

    inst.setOption(option, true);
    return true;
  }

  function _rebuildTimelineEcharts(entry, filteredData, config, switchOverrides) {
    if (!entry || !entry.el || typeof echarts === 'undefined') return false;
    const inst = echarts.getInstanceByDom(entry.el);
    if (!inst) return false;
    if (!entry.original || !entry.original.option) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.echarts4r) {
        chartRegistry.adapters.echarts4r.storeOriginal(entry);
      }
    }
    const original = entry.original && entry.original.option ? entry.original.option : inst.getOption();
    if (!original) return false;

    const timeVar = config.timeVar;
    const groupVar = config.groupVar;
    const valueCol = 'value';

    const timeValues = Array.from(new Set(filteredData.map(r => r[timeVar]))).map(v => v);
    const numericTime = timeValues.every(v => v !== null && v !== '' && !isNaN(Number(v)));
    if (numericTime) timeValues.sort((a, b) => Number(a) - Number(b));

    const activeGroups = groupVar
      ? uniqueNonEmptyNames(filteredData.map(r => r[groupVar]))
      : [];
    let groupValues = groupVar
      ? (Array.isArray(config.groupOrder) && config.groupOrder.length
          ? uniqueNonEmptyNames(config.groupOrder).filter(g => activeGroups.includes(g))
          : activeGroups)
      : [String(config.yVar || 'value')];

    const switchHidden = new Set();
    const switchShown = new Set();
    if (switchOverrides) {
      Object.keys(switchOverrides).forEach(filterVar => {
        switchOverrides[filterVar].forEach(sw => {
          const seriesName = normalizeSeriesName(sw.seriesName);
          if (!seriesName) return;
          if (!sw.visible) switchHidden.add(seriesName);
          else if (sw.override) switchShown.add(seriesName);
        });
      });
    }
    if (groupVar && switchShown.size > 0) {
      groupValues = uniqueNonEmptyNames([...groupValues, ...Array.from(switchShown)]);
    }

    const option = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(original) : JSON.parse(JSON.stringify(original));
    if (option.xAxis && option.xAxis.length) option.xAxis[0].data = timeValues;

    const visibleGroupValues = groupValues.filter(name => !switchHidden.has(name) || switchShown.has(name));
    option.series = visibleGroupValues.map(group => {
      const orig = (original.series || []).find(s => s && s.name === String(group)) || {};
      const s = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(orig) : JSON.parse(JSON.stringify(orig));
      s.name = String(group);
      const rows = groupVar ? filteredData.filter(r => String(r[groupVar]) === String(group)) : filteredData;
      const byTime = {};
      rows.forEach(r => { byTime[String(r[timeVar])] = r[valueCol]; });
      s.data = timeValues.map(t => {
        const v = byTime[String(t)];
        return v !== undefined ? v : null;
      });
      return s;
    });
    syncEchartsLegend(option, visibleGroupValues);

    inst.setOption(option, true);
    return true;
  }

  function _rebuildBarEcharts(entry, filteredData, config, switchOverrides) {
    if (!entry || !entry.el || typeof echarts === 'undefined') return false;
    const inst = echarts.getInstanceByDom(entry.el);
    if (!inst) return false;
    if (!entry.original || !entry.original.option) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.echarts4r) {
        chartRegistry.adapters.echarts4r.storeOriginal(entry);
      }
    }
    const original = entry.original && entry.original.option ? entry.original.option : inst.getOption();
    if (!original) return false;

    const option = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(original) : JSON.parse(JSON.stringify(original));
    if (option.dataset) delete option.dataset;

    const xVar = config.xVar;
    let groupVar = config.groupVar;
    if (groupVar && typeof groupVar === 'object' && !Array.isArray(groupVar) && Object.keys(groupVar).length === 0) {
      groupVar = null;
    }
    const xOrder = config.xOrder;
    const groupOrder = config.groupOrder;

    const xAxisCfg = Array.isArray(option.xAxis)
      ? (option.xAxis[0] = option.xAxis[0] || {})
      : (option.xAxis = option.xAxis || {});
    const yAxisCfg = Array.isArray(option.yAxis)
      ? (option.yAxis[0] = option.yAxis[0] || {})
      : (option.yAxis = option.yAxis || {});
    const originalXAxis = Array.isArray(original.xAxis) ? (original.xAxis[0] || {}) : (original.xAxis || {});
    const originalYAxis = Array.isArray(original.yAxis) ? (original.yAxis[0] || {}) : (original.yAxis || {});
    const isHorizontal = String(originalYAxis.type || '').toLowerCase() === 'category' ||
      (String(originalXAxis.type || '').toLowerCase() === 'value' &&
       String(originalYAxis.type || '').toLowerCase() === 'category');

    const switchHidden = new Set();
    const switchShown = new Set();
    if (switchOverrides) {
      Object.keys(switchOverrides).forEach(filterVar => {
        switchOverrides[filterVar].forEach(sw => {
          const seriesName = normalizeSeriesName(sw.seriesName);
          if (!seriesName) return;
          if (!sw.visible) switchHidden.add(seriesName);
          else if (sw.override) switchShown.add(seriesName);
        });
      });
    }

    if (groupVar) {
      const summed = {};
      filteredData.forEach(row => {
        const xVal = String(row[xVar]);
        const rawGroup = row[groupVar];
        const gVal = normalizeSeriesName(rawGroup);
        if (!gVal) return;
        const key = xVal + '|||' + gVal;
        if (!summed[key]) summed[key] = { xVal, gVal, n: 0 };
        summed[key].n += row.n;
      });

      const byX = {};
      Object.values(summed).forEach(item => {
        if (!byX[item.xVal]) byX[item.xVal] = {};
        byX[item.xVal][item.gVal] = item.n;
      });

      const activeXValues = new Set(Object.keys(byX));
      const orderedX = xOrder && xOrder.length > 0
        ? xOrder.filter(xv => activeXValues.has(xv))
        : Object.keys(byX);
      const activeGroups = uniqueNonEmptyNames(Object.values(summed).map(s => s.gVal));
      const orderedGroupsRaw = groupOrder && groupOrder.length > 0
        ? groupOrder.filter(g => activeGroups.includes(g))
        : activeGroups;
      const orderedGroups = uniqueNonEmptyNames(orderedGroupsRaw);

      const baseSeries = (option.series || [])
        .filter(s => s && typeof s === 'object')
        .map(series => {
          const name = normalizeSeriesName(series.name);
          if (!name) return null;
          series.name = name;
          return series;
        })
        .filter(Boolean);
      const originalSeries = (original.series || [])
        .filter(s => s && typeof s === 'object')
        .map(series => {
          const name = normalizeSeriesName(series.name);
          if (!name) return null;
          series.name = name;
          return series;
        })
        .filter(Boolean);
      const seriesOrder = uniqueNonEmptyNames(baseSeries.map(s => s.name))
        .filter(name => orderedGroups.includes(name));
      const allGroups = uniqueNonEmptyNames([...seriesOrder, ...orderedGroups, ...Array.from(switchShown)]);
      const visibleGroups = allGroups.filter(name => !switchHidden.has(name) || switchShown.has(name));

      if (isHorizontal) {
        yAxisCfg.type = 'category';
        yAxisCfg.data = orderedX;
        xAxisCfg.type = 'value';
        xAxisCfg.data = null;
      } else {
        xAxisCfg.type = 'category';
        xAxisCfg.data = orderedX;
        yAxisCfg.type = 'value';
        yAxisCfg.data = null;
      }

      option.series = visibleGroups.map(groupName => {
        const orig = originalSeries.find(s => s && s.name === groupName) || {};
        const s = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(orig) : JSON.parse(JSON.stringify(orig));
        s.name = groupName;
        s.type = s.type || 'bar';
        if (s.encode) delete s.encode;
        if (s.datasetIndex !== undefined) delete s.datasetIndex;
        const values = orderedX.map(xVal => (byX[xVal] && byX[xVal][groupName]) ? byX[xVal][groupName] : 0);
        if (isHorizontal) {
          s.data = orderedX.map((xVal, idx) => [values[idx], xVal]);
        } else {
          s.data = values;
        }
        s.show = true;
        return s;
      });
      syncEchartsLegend(option, visibleGroups);
      inst.setOption(option, true);
      return true;
    }

    // Simple (ungrouped) bar
    const counts = {};
    filteredData.forEach(row => {
      const xVal = String(row[xVar]);
      if (!counts[xVal]) counts[xVal] = 0;
      counts[xVal] += row.n;
    });
    const activeX = new Set(Object.keys(counts));
    const orderedXSimple = xOrder && xOrder.length > 0
      ? xOrder.filter(xv => activeX.has(xv))
      : Object.keys(counts);
    const valuesSimple = orderedXSimple.map(xVal => counts[xVal] || 0);

    if (isHorizontal) {
      yAxisCfg.type = 'category';
      yAxisCfg.data = orderedXSimple;
      xAxisCfg.type = 'value';
      xAxisCfg.data = null;
    } else {
      xAxisCfg.type = 'category';
      xAxisCfg.data = orderedXSimple;
      yAxisCfg.type = 'value';
      yAxisCfg.data = null;
    }

    const origSeriesSimple = ((original.series || []).find(s => s && typeof s === 'object')) || {};
    const simpleSeries = chartRegistry && chartRegistry.deepClone
      ? chartRegistry.deepClone(origSeriesSimple)
      : JSON.parse(JSON.stringify(origSeriesSimple));
    simpleSeries.type = simpleSeries.type || 'bar';
    if (simpleSeries.encode) delete simpleSeries.encode;
    if (simpleSeries.datasetIndex !== undefined) delete simpleSeries.datasetIndex;
    if (isHorizontal) {
      simpleSeries.data = orderedXSimple.map((xVal, idx) => [valuesSimple[idx], xVal]);
    } else {
      simpleSeries.data = valuesSimple;
    }
    option.series = [simpleSeries];
    syncEchartsLegend(option, []);
    inst.setOption(option, true);
    return true;
  }

  function _rebuildPieEcharts(entry, filteredData, config) {
    if (!entry || !entry.el || typeof echarts === 'undefined') return false;
    const inst = echarts.getInstanceByDom(entry.el);
    if (!inst) return false;
    if (!entry.original || !entry.original.option) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.echarts4r) {
        chartRegistry.adapters.echarts4r.storeOriginal(entry);
      }
    }
    const original = entry.original && entry.original.option ? entry.original.option : inst.getOption();
    if (!original) return false;

    const option = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(original) : JSON.parse(JSON.stringify(original));
    const xVar = config.xVar;
    if (!xVar) return false;

    const counts = {};
    filteredData.forEach(row => {
      const label = String(row[xVar]);
      if (!counts[label]) counts[label] = 0;
      counts[label] += Number(row.n) || 0;
    });

    const activeLabels = new Set(Object.keys(counts));
    const labels = Array.isArray(config.xOrder) && config.xOrder.length > 0
      ? config.xOrder.filter(lbl => activeLabels.has(lbl))
      : Object.keys(counts);

    const seriesData = labels.map(label => {
      const item = { name: label, value: counts[label] || 0 };
      if (config.colorMap && config.colorMap[label]) {
        item.itemStyle = { color: config.colorMap[label] };
      }
      return item;
    });

    if (!option.series || !option.series.length) option.series = [{}];
    const series = option.series[0];
    series.type = 'pie';
    series.data = seriesData;
    series.name = series.name || xVar;
    if (series.encode) delete series.encode;
    if (series.datasetIndex !== undefined) delete series.datasetIndex;
    if (option.dataset) delete option.dataset;
    syncEchartsLegend(option, labels);
    inst.setOption(option, true);
    return true;
  }

  function _rebuildScatterEcharts(entry, filteredData, config) {
    if (!entry || !entry.el || typeof echarts === 'undefined') return false;
    const inst = echarts.getInstanceByDom(entry.el);
    if (!inst) return false;
    if (!entry.original || !entry.original.option) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.echarts4r) {
        chartRegistry.adapters.echarts4r.storeOriginal(entry);
      }
    }
    const original = entry.original && entry.original.option ? entry.original.option : inst.getOption();
    if (!original) return false;

    const option = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(original) : JSON.parse(JSON.stringify(original));
    if (option.dataset) delete option.dataset;

    const xVar = config.xVar;
    const yVar = config.yVar;
    const groupVar = config.groupVar;
    const sizeVar = config.sizeVar;
    if (!xVar || !yVar) return false;

    const rows = filteredData.filter(row => _toFiniteNumber(row[xVar]) !== null && _toFiniteNumber(row[yVar]) !== null);
    let groups;
    if (groupVar) {
      const active = uniqueNonEmptyNames(rows.map(row => row[groupVar]));
      groups = Array.isArray(config.groupOrder) && config.groupOrder.length > 0
        ? uniqueNonEmptyNames(config.groupOrder).filter(g => active.includes(g))
        : active;
    } else {
      groups = ['__all__'];
    }

    option.series = groups.map(groupName => {
      const orig = (original.series || []).find(s => normalizeSeriesName(s && s.name) === normalizeSeriesName(groupName)) || {};
      const s = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(orig) : JSON.parse(JSON.stringify(orig));
      const groupRows = groupVar ? rows.filter(row => normalizeSeriesName(row[groupVar]) === groupName) : rows;
      s.type = 'scatter';
      s.name = groupVar ? groupName : (s.name || 'Values');
      if (s.encode) delete s.encode;
      if (s.datasetIndex !== undefined) delete s.datasetIndex;
      s.data = groupRows.map(row => {
        const x = Number(row[xVar]);
        const y = Number(row[yVar]);
        if (sizeVar) {
          const sz = _toFiniteNumber(row[sizeVar]);
          return [x, y, sz !== null ? sz : (config.pointSize || 4)];
        }
        return [x, y];
      });
      s.symbolSize = sizeVar
        ? function(params) {
            const val = Array.isArray(params.value) ? Number(params.value[2]) : Number(params.value);
            return Number.isFinite(val) ? val : (config.pointSize || 4);
          }
        : (s.symbolSize || config.pointSize || 4);
      if (config.colorMap && config.colorMap[groupName]) {
        s.itemStyle = s.itemStyle || {};
        s.itemStyle.color = config.colorMap[groupName];
      }
      return s;
    });
    syncEchartsLegend(option, groupVar ? groups : []);
    inst.setOption(option, true);
    return true;
  }

  function _rebuildBoxplotEcharts(entry, filteredData, config) {
    if (!entry || !entry.el || typeof echarts === 'undefined') return false;
    const inst = echarts.getInstanceByDom(entry.el);
    if (!inst) return false;
    if (!entry.original || !entry.original.option) {
      if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters.echarts4r) {
        chartRegistry.adapters.echarts4r.storeOriginal(entry);
      }
    }
    const original = entry.original && entry.original.option ? entry.original.option : inst.getOption();
    if (!original) return false;

    const option = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(original) : JSON.parse(JSON.stringify(original));
    if (option.dataset) delete option.dataset;

    const xVar = config.xVar;
    const yVar = config.yVar;
    if (!xVar || !yVar) return false;

    const grouped = {};
    filteredData.forEach(row => {
      const group = String(row[xVar]);
      const value = _toFiniteNumber(row[yVar]);
      if (value === null) return;
      if (!grouped[group]) grouped[group] = [];
      grouped[group].push(value);
    });

    const activeGroups = Object.keys(grouped);
    const groups = Array.isArray(config.xOrder) && config.xOrder.length > 0
      ? config.xOrder.filter(g => activeGroups.includes(g))
      : activeGroups;

    const boxData = groups.map(group => {
      const stats = _computeBoxStats(grouped[group]);
      return stats ? {
        name: group,
        value: [stats.low, stats.q1, stats.median, stats.q3, stats.high]
      } : null;
    }).filter(Boolean);

    const outlierRows = [];
    if (config.showOutliers !== false) {
      groups.forEach(group => {
        const stats = _computeBoxStats(grouped[group]);
        if (!stats || !stats.outliers || !stats.outliers.length) return;
        stats.outliers.forEach(outlier => {
          outlierRows.push([group, outlier]);
        });
      });
    }

    const xAxisCfg = Array.isArray(option.xAxis)
      ? (option.xAxis[0] = option.xAxis[0] || {})
      : (option.xAxis = option.xAxis || {});
    const yAxisCfg = Array.isArray(option.yAxis)
      ? (option.yAxis[0] = option.yAxis[0] || {})
      : (option.yAxis = option.yAxis || {});
    const horizontal = !!config.horizontal;
    if (horizontal) {
      yAxisCfg.type = 'category';
      yAxisCfg.data = groups;
      xAxisCfg.type = 'value';
      xAxisCfg.data = null;
    } else {
      xAxisCfg.type = 'category';
      xAxisCfg.data = groups;
      yAxisCfg.type = 'value';
      yAxisCfg.data = null;
    }

    const baseSeries = (option.series || []).filter(s => s && typeof s === 'object');
    const boxSeriesOrig = baseSeries.find(s => String(s.type || '').toLowerCase() === 'boxplot') || baseSeries[0] || {};
    const boxSeries = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(boxSeriesOrig) : JSON.parse(JSON.stringify(boxSeriesOrig));
    boxSeries.type = 'boxplot';
    boxSeries.name = boxSeries.name || (yVar || 'Values');
    boxSeries.data = boxData.map(item => item.value);
    if (boxSeries.encode) delete boxSeries.encode;
    if (boxSeries.datasetIndex !== undefined) delete boxSeries.datasetIndex;

    const seriesList = [boxSeries];
    if (outlierRows.length > 0) {
      const outlierOrig = baseSeries.find(s => String(s.type || '').toLowerCase() === 'scatter') || {};
      const outlierSeries = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(outlierOrig) : JSON.parse(JSON.stringify(outlierOrig));
      outlierSeries.type = 'scatter';
      outlierSeries.name = outlierSeries.name || 'Outliers';
      outlierSeries.data = horizontal
        ? outlierRows.map(item => [item[1], item[0]])
        : outlierRows;
      if (outlierSeries.encode) delete outlierSeries.encode;
      if (outlierSeries.datasetIndex !== undefined) delete outlierSeries.datasetIndex;
      seriesList.push(outlierSeries);
    }
    option.series = seriesList;
    syncEchartsLegend(option, seriesList.map(s => s && s.name));
    inst.setOption(option, true);
    return true;
  }

  function _rebuildPieSeries(chart, filteredData, config) {
    const xVar = config.xVar;
    if (!xVar) return false;

    const counts = {};
    filteredData.forEach(row => {
      const label = String(row[xVar]);
      if (!counts[label]) counts[label] = 0;
      counts[label] += Number(row.n) || 0;
    });

    const activeLabels = new Set(Object.keys(counts));
    const labels = Array.isArray(config.xOrder) && config.xOrder.length > 0
      ? config.xOrder.filter(lbl => activeLabels.has(lbl))
      : Object.keys(counts);

    const seriesData = labels.map(label => {
      const point = { name: label, y: counts[label] || 0 };
      if (config.colorMap && config.colorMap[label]) point.color = config.colorMap[label];
      return point;
    });

    const pieSeries = (chart.series || []).find(s => s && String(s.type || '').toLowerCase() === 'pie');
    if (!pieSeries) return false;
    pieSeries.setData(seriesData, false);
    pieSeries.setVisible(true, false);
    pieSeries.update({ showInLegend: true }, false);
    chart.redraw();
    return true;
  }

  function _rebuildScatterSeries(chart, filteredData, config) {
    const xVar = config.xVar;
    const yVar = config.yVar;
    const groupVar = config.groupVar;
    if (!xVar || !yVar) return false;

    const rows = filteredData.filter(row => _toFiniteNumber(row[xVar]) !== null && _toFiniteNumber(row[yVar]) !== null);
    let groups;
    if (groupVar) {
      const active = uniqueNonEmptyNames(rows.map(row => row[groupVar]));
      groups = Array.isArray(config.groupOrder) && config.groupOrder.length > 0
        ? uniqueNonEmptyNames(config.groupOrder).filter(g => active.includes(g))
        : active;
    } else {
      groups = ['__all__'];
    }

    const seriesNamesHandled = new Set();
    const scatterSeries = (chart.series || []).filter(s => s && String(s.type || '').toLowerCase() === 'scatter');

    groups.forEach(groupName => {
      const seriesName = groupVar
        ? groupName
        : ((scatterSeries[0] && scatterSeries[0].name) || String(config.yVar || 'Value'));
      const groupRows = groupVar ? rows.filter(row => normalizeSeriesName(row[groupVar]) === groupName) : rows;
      const points = groupRows.map(row => [Number(row[xVar]), Number(row[yVar])]);
      let series = (chart.series || []).find(s => s && s.name === seriesName && String(s.type || '').toLowerCase() === 'scatter');
      if (series) {
        series.setData(points, false);
        series.setVisible(true, false);
        series.update({ showInLegend: !!groupVar }, false);
      } else {
        chart.addSeries({
          type: 'scatter',
          name: seriesName,
          data: points,
          marker: {
            radius: config.pointSize || 4,
            fillOpacity: config.alpha != null ? config.alpha : 0.7
          },
          showInLegend: !!groupVar
        }, false);
      }
      seriesNamesHandled.add(seriesName);
    });

    scatterSeries.forEach(series => {
      if (!series || typeof series !== 'object') return;
      if (!seriesNamesHandled.has(series.name)) {
        series.setData([], false);
        series.setVisible(false, false);
        series.update({ showInLegend: false }, false);
      }
    });

    chart.redraw();
    return true;
  }

  function _rebuildBoxplotSeries(chart, filteredData, config) {
    const xVar = config.xVar;
    const yVar = config.yVar;
    if (!xVar || !yVar) return false;

    const grouped = {};
    filteredData.forEach(row => {
      const group = String(row[xVar]);
      const value = _toFiniteNumber(row[yVar]);
      if (value === null) return;
      if (!grouped[group]) grouped[group] = [];
      grouped[group].push(value);
    });

    const activeGroups = Object.keys(grouped);
    const groups = Array.isArray(config.xOrder) && config.xOrder.length > 0
      ? config.xOrder.filter(g => activeGroups.includes(g))
      : activeGroups;

    if (chart.xAxis && chart.xAxis[0] && typeof chart.xAxis[0].setCategories === 'function') {
      chart.xAxis[0].setCategories(groups, false);
    }

    const boxSeries = (chart.series || []).find(s => s && String(s.type || '').toLowerCase() === 'boxplot');
    if (!boxSeries) return false;

    const boxData = groups.map(group => {
      const stats = _computeBoxStats(grouped[group]);
      if (!stats) return null;
      if (config.colorMap && config.colorMap[group]) {
        return {
          low: stats.low,
          q1: stats.q1,
          median: stats.median,
          q3: stats.q3,
          high: stats.high,
          color: config.colorMap[group]
        };
      }
      return [stats.low, stats.q1, stats.median, stats.q3, stats.high];
    }).filter(Boolean);
    boxSeries.setData(boxData, false);
    boxSeries.setVisible(true, false);
    boxSeries.update({ showInLegend: false }, false);

    const showOutliers = config.showOutliers !== false;
    const outlierPoints = [];
    if (showOutliers) {
      groups.forEach((group, idx) => {
        const stats = _computeBoxStats(grouped[group]);
        if (!stats || !stats.outliers || !stats.outliers.length) return;
        stats.outliers.forEach(outlier => {
          outlierPoints.push({ x: idx, y: outlier });
        });
      });
    }

    let outlierSeries = (chart.series || []).find(s => s && String(s.type || '').toLowerCase() === 'scatter');
    if (showOutliers && outlierPoints.length > 0) {
      if (!outlierSeries) {
        chart.addSeries({
          type: 'scatter',
          name: 'Outliers',
          data: outlierPoints,
          showInLegend: false,
          marker: {
            fillColor: 'white',
            lineWidth: 1,
            lineColor: 'black',
            symbol: 'circle'
          }
        }, false);
      } else {
        outlierSeries.setData(outlierPoints, false);
        outlierSeries.setVisible(true, false);
        outlierSeries.update({ showInLegend: false }, false);
      }
    } else if (outlierSeries) {
      outlierSeries.setData([], false);
      outlierSeries.setVisible(false, false);
      outlierSeries.update({ showInLegend: false }, false);
    }

    chart.redraw();
    return true;
  }

  /**
   * Rebuild a simple bar chart's series from filtered cross-tab data.
   */
  function _rebuildBarSeries(chart, filteredData, config) {
    var xVar = config.xVar;
    var groupVar = config.groupVar;
    // Guard against R NULL serialized as {} (empty object) which is truthy in JS
    if (groupVar && typeof groupVar === 'object' && !Array.isArray(groupVar) && Object.keys(groupVar).length === 0) groupVar = null;
    var xOrder = config.xOrder;
    var groupOrder = config.groupOrder;
    var labelDec = (config.labelDecimals != null) ? config.labelDecimals : 0;
    var barType = config.barType || 'count';
    var isPercent = (barType === 'percent');

    if (groupVar) {
      // Grouped bar chart: sum by xVar + groupVar
      var summed = {};
      filteredData.forEach(function(row) {
        var xVal = String(row[xVar]);
        var gVal = String(row[groupVar]);
        var key = xVal + '|||' + gVal;
        if (!summed[key]) summed[key] = { xVal: xVal, gVal: gVal, n: 0 };
        summed[key].n += row.n;
      });

      var byX = {};
      Object.values(summed).forEach(function(item) {
        if (!byX[item.xVal]) byX[item.xVal] = {};
        byX[item.xVal][item.gVal] = item.n;
      });

      // Calculate total for percentage mode
      var grandTotal = 0;
      if (isPercent) {
        Object.values(summed).forEach(function(item) { grandTotal += item.n; });
      }

      var activeXValues = new Set(Object.keys(byX));
      var orderedX = xOrder && xOrder.length > 0
        ? xOrder.filter(function(xv) { return activeXValues.has(xv); })
        : Object.keys(byX);

      var activeGroups = new Set(Object.values(summed).map(function(s) { return s.gVal; }));
      var orderedGroups = groupOrder && groupOrder.length > 0
        ? groupOrder.filter(function(g) { return activeGroups.has(g); })
        : Array.from(activeGroups);

      if (chart.xAxis && chart.xAxis[0]) {
        chart.xAxis[0].setCategories(orderedX, false);
      }

      orderedGroups.forEach(function(gVal) {
        var seriesData = orderedX.map(function(xVal) {
          var count = (byX[xVal] && byX[xVal][gVal]) ? byX[xVal][gVal] : 0;
          if (isPercent && grandTotal > 0) {
            return Math.round((count / grandTotal * 100) * 10) / 10;
          }
          return count;
        });
        var series = (chart.series || []).find(function(s) { return s && s.name === gVal; });
        if (series) {
          series.setData(seriesData, false);
          series.setVisible(true, false);
          series.update({ showInLegend: true }, false);
        }
      });

      // Hide series not in filtered data
      (chart.series || []).forEach(function(series) {
        if (!series || typeof series !== 'object') return;
        if (!activeGroups.has(series.name)) {
          series.setVisible(false, false);
          series.update({ showInLegend: false }, false);
        }
      });
    } else {
      // Simple bar chart: sum by xVar only
      var counts = {};
      var total = 0;
      filteredData.forEach(function(row) {
        var xVal = String(row[xVar]);
        if (!counts[xVal]) counts[xVal] = 0;
        counts[xVal] += row.n;
        total += row.n;
      });

      var activeX = new Set(Object.keys(counts));
      var orderedXSimple = xOrder && xOrder.length > 0
        ? xOrder.filter(function(xv) { return activeX.has(xv); })
        : Object.keys(counts);

      if (chart.xAxis && chart.xAxis[0]) {
        chart.xAxis[0].setCategories(orderedXSimple, false);
      }

      var seriesData = orderedXSimple.map(function(xVal) {
        var count = counts[xVal] || 0;
        if (isPercent && total > 0) {
          return Math.round((count / total * 100) * 10) / 10;
        }
        return count;
      });

      if (chart.series && chart.series[0]) {
        chart.series[0].setData(seriesData, false);
      }
    }

    // Update title if template
    if (config.titleTemplate) {
      var newTitle = config.titleTemplate;
      if (chart.setTitle) {
        chart.setTitle({ text: newTitle }, null, false);
      }
    }

    chart.redraw();

    // Force yAxis to start at 0 for bar charts (prevents floating bars)
    if (chart.yAxis && chart.yAxis[0]) {
      try {
        chart.yAxis[0].update({ min: 0, startOnTick: false }, true);
      } catch(e) {}
    }

    // Schedule a reflow to handle cases where chart was hidden during redraw
    requestAnimationFrame(function() {
      try { chart.reflow(); } catch(e) {}
    });

    return true;
  }

  /**
   * Rebuild a stacked-bar chart's series from filtered cross-tab data.
   */
  function _rebuildStackedBarSeries(chart, filteredData, config) {
    const { xVar, stackVar, stackedType, stackOrder, xOrder } = config;
    var labelDec = (config.labelDecimals != null) ? config.labelDecimals : (stackedType === 'percent' ? 1 : 0);
    var factor = Math.pow(10, labelDec);
    
    // Sum by x_var and stack_var (drop filter dimensions)
    const summed = {};
    filteredData.forEach(row => {
      const xVal = String(row[xVar]);
      const stackVal = String(row[stackVar]);
      const key = xVal + '|||' + stackVal;
      
      if (!summed[key]) {
        summed[key] = { xVal, stackVal, n: 0 };
      }
      summed[key].n += row.n;
    });
    
    // Organize by x_var for percentage calculation
    const byX = {};
    Object.values(summed).forEach(item => {
      if (!byX[item.xVal]) {
        byX[item.xVal] = {};
      }
      byX[item.xVal][item.stackVal] = item.n;
    });
    
    // Calculate totals per x for percentage mode
    const xTotals = {};
    Object.keys(byX).forEach(xVal => {
      xTotals[xVal] = Object.values(byX[xVal]).reduce((sum, n) => sum + n, 0);
    });
    
    const isPercent = stackedType === 'percent';
    
    // Determine which x values actually exist in the filtered data
    const activeXValues = new Set(Object.keys(byX));
    const orderedX = xOrder && xOrder.length > 0
      ? xOrder.filter(xv => activeXValues.has(xv))
      : Object.keys(byX);
    
    // Determine which stack values actually exist
    const activeStackValues = new Set(Object.values(summed).map(s => s.stackVal));
    const orderedStack = stackOrder && stackOrder.length > 0
      ? stackOrder.filter(sv => activeStackValues.has(sv))
      : [...activeStackValues];
    
    // Update chart categories (x-axis)
    if (chart.xAxis && chart.xAxis[0]) {
      chart.xAxis[0].setCategories(orderedX, false);
    }
    
    const activeSeriesNames = new Set(orderedStack);
    
    // Update active series with data
    orderedStack.forEach((stackVal) => {
      const seriesData = orderedX.map(xVal => {
        const count = (byX[xVal] && byX[xVal][stackVal]) ? byX[xVal][stackVal] : 0;
        if (isPercent && xTotals[xVal] > 0) {
          return Math.round(((count / xTotals[xVal]) * 100) * factor) / factor;
        }
        return count;
      });
      
      let series = (chart.series || []).find(s => s && s.name === stackVal);
      if (series) {
        var updateOpts = { showInLegend: true };
        if (config.colorMap && config.colorMap[stackVal]) {
          updateOpts.color = config.colorMap[stackVal];
        }
        series.setData(seriesData, false);
        series.setVisible(true, false);
        series.update(updateOpts, false);
      }
    });
    
    // Hide series that are NOT in the filtered data
    (chart.series || []).forEach(series => {
      if (!series || typeof series !== 'object') return;
      if (!activeSeriesNames.has(series.name)) {
        series.setData(orderedX.map(() => 0), false);
        series.setVisible(false, false);
        series.update({ showInLegend: false }, false);
      }
    });
    
    chart.redraw();
    return true;
  }

  /**
   * Rebuild a timeline (line) chart's series from filtered cross-tab data.
   */
  function _rebuildTimelineSeries(chart, filteredData, config) {
    const { timeVar, groupVar, yVar } = config;
    var aggMethod = config.agg || 'mean'; // 'sum' or 'mean'

    if (filteredData.length === 0) {
      // No data after filtering — hide all series
      chart.series.slice().forEach(function(s) {
        s.setData([], false);
        s.setVisible(false, false);
        s.update({ showInLegend: false }, false);
      });
      chart.redraw();
      return true;
    }

    // Aggregate value per time + group, using yVar or fallback to 'value'
    var aggBuckets = {};
    filteredData.forEach(function(row) {
      var tVal = String(row[timeVar]);
      var gVal = groupVar ? String(row[groupVar]) : '__all__';
      var key = tVal + '|||' + gVal;

      if (!aggBuckets[key]) {
        aggBuckets[key] = { time: tVal, group: gVal, sum: 0, count: 0 };
      }
      // Use yVar column if present, fall back to 'value' column, then to 1 for count-based
      var rawVal = yVar && row[yVar] !== undefined ? row[yVar] : (row.value !== undefined ? row.value : 1);
      aggBuckets[key].sum += (typeof rawVal === 'number' ? rawVal : Number(rawVal) || 0);
      aggBuckets[key].count += 1;
    });

    // Build per-group series data
    var byGroup = {};
    Object.values(aggBuckets).forEach(function(item) {
      if (!byGroup[item.group]) byGroup[item.group] = [];
      var val;
      if (aggMethod === 'sum') {
        val = item.sum;
      } else {
        val = item.count > 0 ? item.sum / item.count : 0;
      }
      byGroup[item.group].push({ time: item.time, value: val });
    });

    // Detect if time axis is numeric (years) or categorical (strings)
    var sampleTime = Object.values(aggBuckets)[0].time;
    var isNumericTime = !isNaN(Number(sampleTime));

    // Get unique time values, preserving config order if available
    var allTimes = [];
    var seenTimes = {};
    if (config.timeCategories && config.timeCategories.length > 0) {
      // Use R-side factor order (chronological)
      config.timeCategories.forEach(function(t) {
        var ts = String(t);
        if (!seenTimes[ts]) {
          // Only include times that exist in the data
          var exists = Object.values(aggBuckets).some(function(a) { return a.time === ts; });
          if (exists) { seenTimes[ts] = true; allTimes.push(ts); }
        }
      });
    } else {
      Object.values(aggBuckets).forEach(function(a) {
        if (!seenTimes[a.time]) { seenTimes[a.time] = true; allTimes.push(a.time); }
      });
      if (isNumericTime) {
        allTimes.sort(function(a, b) { return Number(a) - Number(b); });
      } else {
        allTimes.sort();
      }
    }

    var activeGroups = new Set(Object.keys(byGroup));

    // Respect group_order from config if provided
    var orderedGroups;
    var cfgGroupOrder = config.groupOrder;
    if (cfgGroupOrder && typeof cfgGroupOrder === 'string') cfgGroupOrder = [cfgGroupOrder];
    if (Array.isArray(cfgGroupOrder) && cfgGroupOrder.length > 0) {
      orderedGroups = cfgGroupOrder.filter(function(g) { return activeGroups.has(g); });
    } else {
      orderedGroups = Array.from(activeGroups);
    }

    // Update x-axis categories if categorical
    if (!isNumericTime && chart.xAxis && chart.xAxis[0]) {
      chart.xAxis[0].setCategories(allTimes, false);
    }

    // Build a set of series names we've handled
    var handledSeries = new Set();

    // Update or add each group's series
    orderedGroups.forEach(function(groupName, groupIndex) {
      var dataPoints = byGroup[groupName];
      // Build a time -> value lookup
      var lookup = {};
      dataPoints.forEach(function(pt) { lookup[pt.time] = pt.value; });

      var seriesName = (groupName === '__all__') ? (yVar || 'Value') : groupName;
      handledSeries.add(seriesName);

      var newData;
      if (isNumericTime) {
        newData = allTimes.map(function(t) {
          return [Number(t), lookup[t] !== undefined ? lookup[t] : null];
        });
      } else {
        newData = allTimes.map(function(t) {
          return lookup[t] !== undefined ? lookup[t] : null;
        });
      }

      var series = (chart.series || []).find(function(s) { return s && s.name === seriesName; });

      if (series) {
        // Update existing series
        var updateOpts = { showInLegend: true };
        if (config.colorMap && config.colorMap[groupName]) {
          updateOpts.color = config.colorMap[groupName];
        }
        series.setData(newData, false);
        series.setVisible(true, false);
        series.update(updateOpts, false);
      } else {
        // Add new series (chart may start empty for cross-tab charts)
        var addOpts = {
          name: seriesName,
          data: newData,
          visible: true,
          showInLegend: true
        };
        if (config.colorMap && config.colorMap[groupName]) {
          addOpts.color = config.colorMap[groupName];
        }
        // Determine series type from chart type config or chart defaults
        var chartType = chart.options && chart.options.chart ? chart.options.chart.type : null;
        if (chartType) {
          addOpts.type = chartType;
        }
        chart.addSeries(addOpts, false);
      }
    });

    // Hide series that are NOT in the filtered data
    chart.series.slice().forEach(function(series) {
      if (!series || typeof series !== 'object') return;
      if (!handledSeries.has(series.name)) {
        series.setData([], false);
        series.setVisible(false, false);
        series.update({ showInLegend: false }, false);
      }
    });

    chart.redraw();
    return true;
  }

  // =================================================================
  // Bootstrap: Initialisation & Event Listeners
  // =================================================================

  // Track initialization state
  let initialized = false;
  let filtersApplied = false;
  
  function safeInit() {
    if (initialized) return;
    initialized = true;
    initDashboardrInputs();
  }
  
  function waitForChartsAndApply() {
    if (filtersApplied) return;
    const entries = getChartEntries() || [];
    const hasTables = chartRegistry && (
      (chartRegistry.getTables && chartRegistry.getTables().length > 0) ||
      (chartRegistry.getDTs && chartRegistry.getDTs().length > 0) ||
      (chartRegistry.getReactables && chartRegistry.getReactables().length > 0)
    );
    if (entries.length > 0 || hasTables) {
      filtersApplied = true;
      storeOriginalData();
      applyAllFilters();
      return;
    }
    setTimeout(waitForChartsAndApply, 200);
  }
  
  // Initialize once DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      safeInit();
      waitForChartsAndApply();
    });
  } else {
    safeInit();
    waitForChartsAndApply();
  }

  // Re-apply on tab switch (for lazy-loaded tabs)
  document.addEventListener('click', e => {
    if (e.target.matches('[role="tab"], .nav-link, .panel-tab')) {
      setTimeout(() => {
        // Only re-apply filters, don't re-initialize
        storeOriginalData();
        applyAllFilters();
      }, 300);
    }
  });

  // =================================================================
  // Public API
  // =================================================================

  window.dashboardrInputs = {
    init: initDashboardrInputs,
    applyFilters: applyAllFilters,
    reapply: reapplyFilters,
    selectAll,
    clearAll,
    resetFilters,
    state: inputState,
    defaults: defaultValues,
    choices: choicesInstances
  };

  window.dashboardrInputDebug = {
    enabled: isDebugEnabled,
    events: debugState.events,
    getState: function() {
      try { return JSON.parse(JSON.stringify(inputState)); } catch (e) { return null; }
    },
    getDefaults: function() {
      try { return JSON.parse(JSON.stringify(defaultValues)); } catch (e) { return null; }
    },
    getCharts: function() {
      return getChartEntries().map(function(e) {
        return { id: e.id, backend: e.backend, x: e.x, filterVars: e.filterVars };
      });
    },
    applyFilters: applyAllFilters
  };

})();
