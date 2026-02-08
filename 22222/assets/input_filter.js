/**
 * Interactive Input Filter System for dashboardr
 *
 * Provides client-side filtering of Highcharts visualizations
 * using various input types.
 * 
 * Supports:
 * - Select dropdowns (single/multiple) via Choices.js
 * - Checkboxes (multiple selection)
 * - Radio buttons (single selection)
 * - Switches/toggles (boolean with optional series toggle)
 * - Sliders (numeric range with optional custom labels)
 * - Text search (partial match filtering)
 * - Number inputs (precise numeric filtering)
 * - Button groups (segmented controls)
 * - Series-based filtering (e.g., by country/group)
 * - Category/point-based filtering (e.g., by decade/time period)
 */

(function() {
  'use strict';

  // Global state
  window.dashboardrChoicesInstances = window.dashboardrChoicesInstances || {};
  const choicesInstances = window.dashboardrChoicesInstances;
  const inputState = {};
  const defaultValues = {};  // Store default values for reset
  
  // Store original data for restoration
  const originalSeriesData = new WeakMap();
  const chartRegistry = window.dashboardrChartRegistry || null;

  function getChartEntries() {
    if (chartRegistry && typeof chartRegistry.getCharts === 'function') {
      return chartRegistry.getCharts();
    }
    return [];
  }

  function initDashboardrInputs() {
    const hasChoices = typeof Choices !== 'undefined';
    
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
          applyAllFilters();
        });
      });
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
          if (!originalSeriesData.has(series)) {
            const data = series.options.data ? JSON.parse(JSON.stringify(series.options.data)) : [];
            originalSeriesData.set(series, { data: data, name: series.name });
          }
        });
      } else if (chartRegistry && chartRegistry.adapters && chartRegistry.adapters[entry.backend]) {
        chartRegistry.adapters[entry.backend].storeOriginal(entry);
      }
    });
  }

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
        numberFilters[state.filterVar] = state.value;
      } else if (state.filterVar === 'period') {
        // Handle period presets (maps to year ranges)
        periodFilters[state.filterVar] = state.selected;
      } else {
        // Select, checkbox, radio, button_group all use selected array
        filters[state.filterVar] = state.selected;
      }
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
    if (window.dashboardrCrossTab) {
      entries.forEach(entry => {
        if (!entry || !entry.id) return;
        const crossTabInfo = window.dashboardrCrossTab[entry.id];
        if (crossTabInfo) {
          const result = rebuildFromCrossTab(entry, crossTabInfo, filters, sliderFilters, switchOverrides);
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
      
      // Store original categories if not already stored
      if (!chart._originalCategories && chart.xAxis && chart.xAxis[0] && chart.xAxis[0].categories) {
        chart._originalCategories = chart.xAxis[0].categories.slice();
      }
      
      // Get original x-axis categories
      const originalCategories = chart._originalCategories || 
        (chart.xAxis && chart.xAxis[0] && chart.xAxis[0].categories ? chart.xAxis[0].categories : null);
      
      // Also check for numeric x-axis (no categories, but has point.x values)
      const hasNumericXAxis = !originalCategories && chart.series.length > 0 && 
        chart.series[0].data && chart.series[0].data.length > 0 &&
        chart.series[0].data[0] && typeof chart.series[0].data[0].x === 'number';
      
      // Determine which filters apply to series names vs categories
      const seriesNames = chart.series.map(s => s.name);
      
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
            chart.series.forEach(series => {
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
          
          chart.series.forEach(series => {
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
      
      chart.series.forEach(series => {
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
  }

  function computeVisibleCategories(allCategories, filters, sliderFilters, periodFilters) {
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
    for (let i = 0; i < data.length; i++) {
      if (data[i].x && data[i].x.length) {
        allCategories = data[i].x.slice();
        break;
      }
    }
    const visibleCategories = computeVisibleCategories(allCategories, filters, sliderFilters, periodFilters);
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
    const visibleCategories = computeVisibleCategories(allCategories, filters, sliderFilters, periodFilters);
    const visibleSet = visibleCategories ? new Set(visibleCategories.map(c => String(c))) : null;

    const seriesNames = (option.series || []).map(s => s.name).filter(n => n !== undefined && n !== null);
    const switchHiddenSeries = new Set();
    const switchShownSeries = new Set();
    Object.keys(inputState).forEach(id => {
      const state = inputState[id];
      if (state.inputType === 'switch' && state.toggleSeries) {
        if (!state.value) switchHiddenSeries.add(state.toggleSeries);
        else if (state.override) switchShownSeries.add(state.toggleSeries);
      }
    });

    option.series = (option.series || []).map(series => {
      const s = series;
      const name = s.name || '';
      let show = shouldShowSeries(name, filters, textFilters, seriesNames);
      if (switchHiddenSeries.has(name)) show = false;
      if (switchShownSeries.has(name)) show = true;
      if (!show) s.show = false;
      if (visibleSet && Array.isArray(s.data) && allCategories) {
        const newData = [];
        const newCats = [];
        for (let i = 0; i < allCategories.length; i++) {
          if (visibleSet.has(String(allCategories[i]))) {
            newCats.push(allCategories[i]);
            newData.push(s.data[i]);
          }
        }
        if (xAxis && newCats.length > 0) xAxis.data = newCats;
        s.data = newData;
      }
      return s;
    });

    inst.setOption(option, true);
  }

  function filterRowsByInputs(data, filterVars, filters, sliderFilters, textFilters, numberFilters, periodFilters) {
    if (!data || data.length === 0) return data;
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
          const selectedIndex = Math.round(sliderInfo.value) - 1;
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
      if (!dt.el || !dt.data || typeof $ === 'undefined') return;
      const filtered = filterRowsByInputs(dt.data, dt.filterVars || [], filters, sliderFilters, textFilters, numberFilters, periodFilters);
      const cols = dt.data.length ? Object.keys(dt.data[0]) : [];
      const rows = filtered.map(r => cols.map(c => r[c]));
      try {
        const instance = $(dt.el).DataTable();
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

    // From select elements
    document.querySelectorAll('select').forEach(function(el) {
      var id = el.id;
      var fv = el.getAttribute('data-filter-var');
      var val = el.value;
      if (id && val) lookup[id] = val;
      if (fv && val) lookup[fv] = val;
    });

    // From checked radio buttons
    document.querySelectorAll('input[type="radio"]:checked').forEach(function(el) {
      var id = el.name || el.id;
      var val = el.value;
      if (id && val) lookup[id] = val;
      // Also resolve filter_var from the parent radio group container
      var group = el.closest('[data-filter-var]');
      if (group) {
        var fv = group.getAttribute('data-filter-var');
        if (fv && val) lookup[fv] = val;
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
   * @param {Object} switchOverrides - Switch-controlled series per filterVar ({filterVar -> [{seriesName, visible, override}]})
   * @returns {boolean} True if chart was rebuilt, false if cross-tab doesn't apply
   */
  function rebuildFromCrossTab(entry, crossTabInfo, filters, sliderFilters, switchOverrides) {
    if (!crossTabInfo || !crossTabInfo.data || !crossTabInfo.config) {
      return false;
    }
    
    const { data, config } = crossTabInfo;
    const { filterVars } = config;
    
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
          // sliderValue is 1-based index into labels array
          const selectedIndex = Math.round(sliderValue) - 1;
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
    }
    
    // ---- Branch by backend + chart type ----
    const backend = entry && entry.backend ? entry.backend : 'highcharter';
    if (backend === 'highcharter') {
      const chart = chartRegistry && chartRegistry.resolveHighchart ? chartRegistry.resolveHighchart(entry) : null;
      if (!chart) return false;
      const ok = (config.chartType === 'timeline')
        ? _rebuildTimelineSeries(chart, filteredData, config)
        : _rebuildStackedBarSeries(chart, filteredData, config);
      if (ok && switchOverrides) {
        Object.keys(switchOverrides).forEach(filterVar => {
          switchOverrides[filterVar].forEach(sw => {
            chart.series.forEach(series => {
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
      return (config.chartType === 'timeline')
        ? _rebuildTimelinePlotly(entry, filteredData, config, switchOverrides)
        : _rebuildStackedBarPlotly(entry, filteredData, config, switchOverrides);
    }
    if (backend === 'echarts4r') {
      return (config.chartType === 'timeline')
        ? _rebuildTimelineEcharts(entry, filteredData, config, switchOverrides)
        : _rebuildStackedBarEcharts(entry, filteredData, config, switchOverrides);
    }
    return false;
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
    const summed = {};
    filteredData.forEach(row => {
      const xVal = String(row[xVar]);
      const stackVal = String(row[stackVar]);
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
    const orderedStack = stackOrder && stackOrder.length > 0 ? stackOrder.filter(sv => activeStackValues.has(sv)) : [...activeStackValues];

    const traceOrder = data.map(t => t.name).filter(n => n !== undefined && n !== null);
    const seriesOrder = traceOrder.length ? traceOrder : orderedStack;
    const allSeries = Array.from(new Set([...seriesOrder, ...orderedStack]));

    const switchHidden = new Set();
    const switchShown = new Set();
    if (switchOverrides) {
      Object.keys(switchOverrides).forEach(filterVar => {
        switchOverrides[filterVar].forEach(sw => {
          if (!sw.visible) switchHidden.add(sw.seriesName);
          else if (sw.override) switchShown.add(sw.seriesName);
        });
      });
    }

    const newData = allSeries.map(name => {
      const orig = data.find(t => t.name === name);
      const trace = orig ? (chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(orig) : JSON.parse(JSON.stringify(orig))) : {};
      trace.type = trace.type || 'bar';
      trace.name = name;
      trace.x = orderedX;
      if (orderedStack.includes(name)) {
        trace.y = orderedX.map(xVal => {
          const count = (byX[xVal] && byX[xVal][name]) ? byX[xVal][name] : 0;
          if (isPercent && xTotals[xVal] > 0) return (count / xTotals[xVal]) * 100;
          return count;
        });
        trace.visible = true;
        trace.showlegend = true;
        if (colorMap && colorMap[name]) {
          trace.marker = trace.marker || {};
          trace.marker.color = colorMap[name];
        }
      } else {
        trace.y = orderedX.map(() => 0);
        trace.visible = 'legendonly';
      }
      if (switchHidden.has(name)) trace.visible = 'legendonly';
      if (switchShown.has(name)) trace.visible = true;
      return trace;
    });

    const layout = original.layout || entry.el.layout || {};
    layout.xaxis = layout.xaxis || {};
    layout.xaxis.categoryorder = 'array';
    layout.xaxis.categoryarray = orderedX;
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

    const groupValues = groupVar
      ? (config.groupOrder && config.groupOrder.length ? config.groupOrder : Array.from(new Set(filteredData.map(r => r[groupVar]))))
      : [config.yVar || 'value'];

    const switchHidden = new Set();
    const switchShown = new Set();
    if (switchOverrides) {
      Object.keys(switchOverrides).forEach(filterVar => {
        switchOverrides[filterVar].forEach(sw => {
          if (!sw.visible) switchHidden.add(sw.seriesName);
          else if (sw.override) switchShown.add(sw.seriesName);
        });
      });
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
    const summed = {};
    filteredData.forEach(row => {
      const xVal = String(row[xVar]);
      const stackVal = String(row[stackVar]);
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
    const orderedStack = stackOrder && stackOrder.length > 0 ? stackOrder.filter(sv => activeStackValues.has(sv)) : [...activeStackValues];

    const switchHidden = new Set();
    const switchShown = new Set();
    if (switchOverrides) {
      Object.keys(switchOverrides).forEach(filterVar => {
        switchOverrides[filterVar].forEach(sw => {
          if (!sw.visible) switchHidden.add(sw.seriesName);
          else if (sw.override) switchShown.add(sw.seriesName);
        });
      });
    }

    const option = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(original) : JSON.parse(JSON.stringify(original));
    if (option.xAxis && option.xAxis.length) option.xAxis[0].data = orderedX;

    const series = (option.series || []).map(s => s.name);
    const seriesOrder = series.length ? series : orderedStack;
    const allSeries = Array.from(new Set([...seriesOrder, ...orderedStack]));

    option.series = allSeries.map(name => {
      const orig = (original.series || []).find(s => s.name === name) || {};
      const s = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(orig) : JSON.parse(JSON.stringify(orig));
      s.name = name;
      s.type = s.type || 'bar';
      if (orderedStack.includes(name)) {
        s.data = orderedX.map(xVal => {
          const count = (byX[xVal] && byX[xVal][name]) ? byX[xVal][name] : 0;
          if (isPercent && xTotals[xVal] > 0) return (count / xTotals[xVal]) * 100;
          return count;
        });
        s.show = true;
        if (colorMap && colorMap[name]) {
          s.itemStyle = s.itemStyle || {};
          s.itemStyle.color = colorMap[name];
        }
      } else {
        s.data = orderedX.map(() => 0);
        s.show = false;
      }
      if (switchHidden.has(name)) s.show = false;
      if (switchShown.has(name)) s.show = true;
      return s;
    });

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

    const groupValues = groupVar
      ? (config.groupOrder && config.groupOrder.length ? config.groupOrder : Array.from(new Set(filteredData.map(r => r[groupVar]))))
      : [config.yVar || 'value'];

    const switchHidden = new Set();
    const switchShown = new Set();
    if (switchOverrides) {
      Object.keys(switchOverrides).forEach(filterVar => {
        switchOverrides[filterVar].forEach(sw => {
          if (!sw.visible) switchHidden.add(sw.seriesName);
          else if (sw.override) switchShown.add(sw.seriesName);
        });
      });
    }

    const option = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(original) : JSON.parse(JSON.stringify(original));
    if (option.xAxis && option.xAxis.length) option.xAxis[0].data = timeValues;

    option.series = groupValues.map(group => {
      const orig = (original.series || []).find(s => s.name === String(group)) || {};
      const s = chartRegistry && chartRegistry.deepClone ? chartRegistry.deepClone(orig) : JSON.parse(JSON.stringify(orig));
      s.name = String(group);
      const rows = groupVar ? filteredData.filter(r => String(r[groupVar]) === String(group)) : filteredData;
      const byTime = {};
      rows.forEach(r => { byTime[String(r[timeVar])] = r[valueCol]; });
      s.data = timeValues.map(t => {
        const v = byTime[String(t)];
        return v !== undefined ? v : null;
      });
      if (switchHidden.has(s.name)) s.show = false;
      if (switchShown.has(s.name)) s.show = true;
      return s;
    });

    inst.setOption(option, true);
    return true;
  }

  /**
   * Rebuild a stacked-bar chart's series from filtered cross-tab data.
   */
  function _rebuildStackedBarSeries(chart, filteredData, config) {
    const { xVar, stackVar, stackedType, stackOrder, xOrder } = config;
    
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
          return (count / xTotals[xVal]) * 100;
        }
        return count;
      });
      
      let series = chart.series.find(s => s.name === stackVal);
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
    chart.series.forEach(series => {
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
    
    if (filteredData.length === 0) {
      // No data after filtering — hide all series
      chart.series.forEach(function(s) {
        s.setData([], false);
        s.setVisible(false, false);
        s.update({ showInLegend: false }, false);
      });
      chart.redraw();
      return true;
    }
    
    // Aggregate: average value per time + group
    const agg = {};
    filteredData.forEach(function(row) {
      const tVal = String(row[timeVar]);
      var gVal = groupVar ? String(row[groupVar]) : '__all__';
      var key = tVal + '|||' + gVal;
      
      if (!agg[key]) {
        agg[key] = { time: tVal, group: gVal, sum: 0, count: 0 };
      }
      agg[key].sum += (row.value !== undefined ? row.value : 0);
      agg[key].count += 1;
    });
    
    // Build per-group series data
    var byGroup = {};
    Object.values(agg).forEach(function(item) {
      if (!byGroup[item.group]) byGroup[item.group] = [];
      byGroup[item.group].push({
        time: item.time,
        value: item.count > 0 ? item.sum / item.count : 0
      });
    });
    
    // Detect if time axis is numeric (years) or categorical (strings)
    var sampleTime = Object.values(agg)[0].time;
    var isNumericTime = !isNaN(Number(sampleTime));
    
    // Get sorted unique time values
    var allTimes = [...new Set(Object.values(agg).map(function(a) { return a.time; }))];
    if (isNumericTime) {
      allTimes.sort(function(a, b) { return Number(a) - Number(b); });
    } else {
      allTimes.sort();
    }
    
    var activeGroups = new Set(Object.keys(byGroup));
    
    // Respect group_order from config if provided
    var orderedGroups;
    if (config.groupOrder && config.groupOrder.length > 0) {
      orderedGroups = config.groupOrder.filter(function(g) { return activeGroups.has(g); });
    } else {
      orderedGroups = [...activeGroups];
    }
    
    // Update x-axis categories if categorical
    if (!isNumericTime && chart.xAxis && chart.xAxis[0]) {
      chart.xAxis[0].setCategories(allTimes, false);
    }
    
    // Update each group's series
    orderedGroups.forEach(function(groupName) {
      var dataPoints = byGroup[groupName];
      // Build a time -> value lookup
      var lookup = {};
      dataPoints.forEach(function(pt) { lookup[pt.time] = pt.value; });
      
      var seriesName = (groupName === '__all__') ? (yVar || 'Value') : groupName;
      var series = chart.series.find(function(s) { return s.name === seriesName; });
      
      if (series) {
        var newData;
        if (isNumericTime) {
          // Numeric time: data = [[x, y], ...]
          newData = allTimes.map(function(t) {
            return [Number(t), lookup[t] !== undefined ? lookup[t] : null];
          });
        } else {
          // Categorical: data = [y1, y2, ...]  matching categories order
          newData = allTimes.map(function(t) {
            return lookup[t] !== undefined ? lookup[t] : null;
          });
        }
        var updateOpts = { showInLegend: true };
        if (config.colorMap && config.colorMap[groupName]) {
          updateOpts.color = config.colorMap[groupName];
        }
        series.setData(newData, false);
        series.setVisible(true, false);
        series.update(updateOpts, false);
      }
    });
    
    // Hide series that are NOT in the filtered data
    chart.series.forEach(function(series) {
      var seriesGroup = series.name;
      if (!activeGroups.has(seriesGroup)) {
        series.setData([], false);
        series.setVisible(false, false);
        series.update({ showInLegend: false }, false);
      }
    });
    
    chart.redraw();
    return true;
  }

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

  // Export API
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

})();
