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
    if (typeof Highcharts === 'undefined') return;
    
    Highcharts.charts.filter(c => c).forEach(chart => {
      if (!chart || !chart.series) return;
      
      chart.series.forEach(series => {
        if (!originalSeriesData.has(series)) {
          // Deep clone the data
          const data = series.options.data ? 
            JSON.parse(JSON.stringify(series.options.data)) : [];
          originalSeriesData.set(series, {
            data: data,
            name: series.name
          });
        }
      });
    });
  }

  /**
   * Apply all filters together
   */
  function applyAllFilters() {
    if (typeof Highcharts === 'undefined') {
      return setTimeout(applyAllFilters, 200);
    }

    const charts = Highcharts.charts.filter(c => c);
    if (!charts || charts.length === 0) {
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

    charts.forEach(chart => {
      if (!chart || !chart.series) return;
      
      // Check if this chart has cross-tab data for client-side filtering
      const chartId = chart.options && chart.options.chart && chart.options.chart.id;
      if (chartId && window.dashboardrCrossTab && window.dashboardrCrossTab[chartId]) {
        const crossTabInfo = window.dashboardrCrossTab[chartId];
        // Collect switch overrides: series that should always be included in data
        // regardless of filter selections (when switch is ON and override is true)
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
        
        const result = rebuildFromCrossTab(chart, crossTabInfo, filters, sliderFilters, switchOverrides);
        if (result) {
          // Chart was rebuilt from cross-tab data.
          // Apply switch toggle series visibility on top of the rebuilt chart.
          Object.keys(inputState).forEach(id => {
            const state = inputState[id];
            if (state.inputType === 'switch' && state.toggleSeries) {
              chart.series.forEach(series => {
                if (series.name === state.toggleSeries) {
                  if (!state.value) {
                    series.setVisible(false, false);
                    series.update({ showInLegend: false }, false);
                  } else {
                    series.setVisible(true, false);
                    series.update({ showInLegend: true }, false);
                  }
                }
              });
            }
          });
          chart.redraw();
          return;
        }
      }
      
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

    // Update any charts that have dynamic title templates
    updateDynamicTitles();
  }

  /**
   * Replace {var} placeholders in chart titles with current input values.
   * Looks up values by both input_id (name) and filter_var so users can
   * reference either in their title template.
   */
  function updateDynamicTitles() {
    if (typeof Highcharts === 'undefined' || !window.dashboardrCrossTab) return;

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
   * @param {Highcharts.Chart} chart - The chart to update
   * @param {Object} crossTabInfo - Object with data array and config
   * @param {Object} filters - Current filter selections (filterVar -> selected values)
   * @param {Object} sliderFilters - Current slider filter states (filterVar -> {value, min, max, step, labels})
   * @param {Object} switchOverrides - Switch-controlled series per filterVar ({filterVar -> [{seriesName, visible, override}]})
   * @returns {boolean} True if chart was rebuilt, false if cross-tab doesn't apply
   */
  function rebuildFromCrossTab(chart, crossTabInfo, filters, sliderFilters, switchOverrides) {
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
    
    // ---- Branch by chart type ----
    if (config.chartType === 'timeline') {
      return _rebuildTimelineSeries(chart, filteredData, config);
    }
    
    // Default: stacked bar chart rebuild
    return _rebuildStackedBarSeries(chart, filteredData, config);
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
    
    if (typeof Highcharts !== 'undefined') {
      const charts = Highcharts.charts.filter(c => c);
      if (charts.length > 0) {
        filtersApplied = true;
        storeOriginalData();
        applyAllFilters();
        return;
      }
    }
    // Charts not ready, retry
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
        if (typeof Highcharts !== 'undefined') {
          storeOriginalData();
          applyAllFilters();
        }
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
