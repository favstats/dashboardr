/**
 * Deferred Charts Module for dashboardr
 *
 * Watches for show_when visibility changes and hydrates deferred chart
 * placeholders on demand. This dramatically reduces initial page size by
 * only rendering charts when they become visible.
 *
 * Flow:
 * 1. R generates placeholder divs with data-chart-url attributes
 * 2. show_when.js toggles visibility via dashboardr-sw-hidden class
 * 3. This module detects when a placeholder becomes visible
 * 4. Fetches chart options JSON and creates the chart
 * 5. Registers the chart with the chart registry for cross-tab filtering
 */
(function() {
  'use strict';

  // Cache for fetched chart options (URL -> parsed JSON)
  var optionsCache = {};

  // Set of chart IDs that have been hydrated
  var hydratedCharts = new Set();

  // Queue for hydration requests
  var hydrationQueue = [];
  var isProcessing = false;

  /**
   * Recursively walk an object and convert string values that look like
   * JavaScript functions into actual functions. This handles the serialization
   * gap: R's jsonlite writes JS functions as strings, and we need to eval them.
   */
  function reviveFunctions(obj) {
    if (obj === null || obj === undefined) return obj;
    if (typeof obj === 'string') {
      var trimmed = obj.trim();
      if (/^function\s*\(/.test(trimmed) || /^\(function/.test(trimmed)) {
        try { return new Function('return (' + trimmed + ')')(); } catch(e) { return obj; }
      }
      return obj;
    }
    if (Array.isArray(obj)) {
      for (var i = 0; i < obj.length; i++) obj[i] = reviveFunctions(obj[i]);
      return obj;
    }
    if (typeof obj === 'object') {
      for (var key in obj) {
        if (obj.hasOwnProperty(key)) obj[key] = reviveFunctions(obj[key]);
      }
    }
    return obj;
  }

  /**
   * Hydrate a single deferred chart placeholder
   */
  function hydrateChart(el) {
    var chartId = el.getAttribute('data-chart-id');
    if (!chartId || hydratedCharts.has(chartId)) return;

    var chartUrl = el.getAttribute('data-chart-url');
    var backend = el.getAttribute('data-chart-backend') || 'highcharter';
    var height = parseInt(el.getAttribute('data-chart-height') || '400', 10);

    if (!chartUrl) return;

    // Mark as hydrated immediately to prevent double-hydration
    hydratedCharts.add(chartId);

    // Check cache first
    if (optionsCache[chartUrl]) {
      _createChart(el, optionsCache[chartUrl], backend, chartId, height);
      return;
    }

    // Fetch chart options
    fetch(chartUrl)
      .then(function(response) {
        if (!response.ok) throw new Error('HTTP ' + response.status);
        return response.json();
      })
      .then(function(payload) {
        optionsCache[chartUrl] = payload;
        _createChart(el, payload, backend, chartId, height);
      })
      .catch(function(err) {
        console.error('dashboardr deferred: Failed to load chart ' + chartId + ':', err);
        hydratedCharts.delete(chartId);
        el.innerHTML = '<div style="color:#ef4444;padding:20px;text-align:center;">Failed to load chart</div>';
      });
  }

  /**
   * Create a chart from fetched options
   */
  function _createChart(el, payload, backend, chartId, height) {
    var options = reviveFunctions(payload.options);
    var crossTabId = payload.crossTabId;

    // --- Smooth crossfade approach ---
    // The placeholder already has a .dashboardr-deferred-overlay (white, absolute,
    // with spinner). We keep it in place, build the chart underneath, then
    // input_filter.js fades it out once filters are applied. Zero layout jumps.

    // Grab the existing overlay before clearing children
    var overlay = el.querySelector('.dashboardr-deferred-overlay');

    // Detach overlay temporarily so innerHTML='' doesn't destroy it
    if (overlay) overlay.parentNode.removeChild(overlay);

    // Clear remaining placeholder content
    el.innerHTML = '';
    el.classList.remove('dashboardr-deferred-chart');
    el.classList.add('dashboardr-deferred-hydrated');

    // Create chart container (renders behind the overlay)
    var container = document.createElement('div');
    container.id = chartId + '_container';
    container.style.width = '100%';
    container.style.height = height + 'px';
    container.style.minHeight = height + 'px';
    el.appendChild(container);

    // Re-attach the overlay on top — spinner keeps spinning while chart renders
    if (overlay) {
      el.appendChild(overlay);
    }

    // Mark as pending filter application
    el.classList.add('dashboardr-deferred-pending-filters');

    if (backend === 'highcharter') {
      _createHighchart(container, options, chartId, crossTabId, height);
    } else if (backend === 'echarts4r') {
      _createEchart(container, options, chartId, crossTabId, height);
    } else if (backend === 'plotly') {
      _createPlotly(container, options, chartId, crossTabId, height);
    }

    // Set up ResizeObserver for proper sizing
    if (typeof ResizeObserver !== 'undefined') {
      var resizeObserver = new ResizeObserver(function() {
        if (backend === 'highcharter' && container._hcChart) {
          try { container._hcChart.reflow(); } catch(e) {}
        }
      });
      resizeObserver.observe(el);
    }

    // Schedule a debounced applyAllFilters after all pending hydrations complete.
    // This ensures filters are applied once (not per-chart), preventing visible double-renders.
    _scheduleFilterApply();
  }

  var _filterApplyTimer = null;
  function _scheduleFilterApply() {
    if (_filterApplyTimer) clearTimeout(_filterApplyTimer);
    _filterApplyTimer = setTimeout(function() {
      _filterApplyTimer = null;
      if (window.dashboardrInputs && window.dashboardrInputs.applyFilters) {
        window.dashboardrInputs.applyFilters();
      }
    }, 300);
  }

  /**
   * Create a Highcharts chart
   */
  function _createHighchart(container, options, chartId, crossTabId, height) {
    if (typeof Highcharts === 'undefined') {
      console.error('dashboardr deferred: Highcharts not loaded');
      return;
    }

    // Ensure chart options have proper dimensions
    if (!options.chart) options.chart = {};
    options.chart.height = height;
    options.chart.id = chartId;

    // Ensure renderTo is set
    options.chart.renderTo = container;

    try {
      var chart = new Highcharts.Chart(options);
      container._hcChart = chart;

      // Register with chart registry for cross-tab filtering
      if (window.dashboardrRegisterChart) {
        var filterVars = null;
        // Get filter vars from cross-tab config if available
        if (crossTabId && window.dashboardrCrossTab && window.dashboardrCrossTab[crossTabId]) {
          var ctInfo = window.dashboardrCrossTab[crossTabId];
          filterVars = ctInfo.config ? ctInfo.config.filterVars : null;
        }
        window.dashboardrRegisterChart({
          id: crossTabId || chartId,
          backend: 'highcharter',
          el: container,
          filterVars: filterVars
        });
      }

      // Reflow after a short delay to ensure proper sizing
      setTimeout(function() {
        try {
          chart.reflow();
          // Force yAxis min=0 for bar/column charts to prevent floating bars
          var chartType = (options.chart && options.chart.type) || '';
          if ((chartType === 'bar' || chartType === 'column') && chart.yAxis && chart.yAxis[0]) {
            chart.yAxis[0].update({ min: 0, startOnTick: false }, true);
          }
        } catch(e) {}
      }, 100);
    } catch (e) {
      console.error('dashboardr deferred: Failed to create Highchart ' + chartId + ':', e);
    }
  }

  /**
   * Create an ECharts chart
   */
  function _createEchart(container, options, chartId, crossTabId, height) {
    if (typeof echarts === 'undefined') {
      console.error('dashboardr deferred: ECharts not loaded');
      return;
    }

    try {
      var chart = echarts.init(container);
      chart.setOption(options);
      container._echartsInstance = chart;

      // Register with chart registry
      if (window.dashboardrRegisterChart) {
        window.dashboardrRegisterChart({
          id: crossTabId || chartId,
          backend: 'echarts4r',
          el: container
        });
      }
    } catch (e) {
      console.error('dashboardr deferred: Failed to create EChart ' + chartId + ':', e);
    }
  }

  /**
   * Create a Plotly chart
   */
  function _createPlotly(container, options, chartId, crossTabId, height) {
    if (typeof Plotly === 'undefined') {
      console.error('dashboardr deferred: Plotly not loaded');
      return;
    }

    try {
      var layout = options.layout || {};
      layout.height = height;
      Plotly.newPlot(container, options.data || [], layout);

      // Register with chart registry
      if (window.dashboardrRegisterChart) {
        window.dashboardrRegisterChart({
          id: crossTabId || chartId,
          backend: 'plotly',
          el: container
        });
      }
    } catch (e) {
      console.error('dashboardr deferred: Failed to create Plotly chart ' + chartId + ':', e);
    }
  }

  /**
   * Check all deferred charts and hydrate visible ones
   */
  function checkAndHydrate() {
    var deferredEls = document.querySelectorAll('.dashboardr-deferred-chart');
    deferredEls.forEach(function(el) {
      if (hydratedCharts.has(el.getAttribute('data-chart-id'))) return;

      // Check if element is visible (not hidden by show_when)
      var isHidden = el.closest('.dashboardr-sw-hidden') !== null;
      if (isHidden) return;

      // Check if the element itself or any parent has display:none
      if (el.offsetParent === null && getComputedStyle(el).position !== 'fixed') return;

      hydrateChart(el);
    });
  }

  /**
   * MutationObserver: watch for show_when class changes
   */
  function initObserver() {
    var observer = new MutationObserver(function(mutations) {
      var shouldCheck = false;
      for (var i = 0; i < mutations.length; i++) {
        var mutation = mutations[i];
        if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
          var target = mutation.target;
          // Check if a show_when container just became visible
          if (target.classList && target.classList.contains('viz-show-when') &&
              !target.classList.contains('dashboardr-sw-hidden')) {
            shouldCheck = true;
            break;
          }
        }
        // Also watch for child additions (dynamic content)
        if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
          shouldCheck = true;
          break;
        }
      }

      if (shouldCheck) {
        // Debounce slightly to batch rapid changes
        clearTimeout(initObserver._debounce);
        initObserver._debounce = setTimeout(checkAndHydrate, 100);
      }
    });

    observer.observe(document.body, {
      attributes: true,
      attributeFilter: ['class'],
      subtree: true,
      childList: true
    });
  }

  // Also listen for the dashboardr change event (fired by input_filter.js)
  document.addEventListener('change', function() {
    setTimeout(checkAndHydrate, 200);
  });

  // Initialize when DOM is ready
  function init() {
    // Initial check for any already-visible deferred charts
    checkAndHydrate();
    // Start watching for visibility changes
    initObserver();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      // Give show_when.js time to set initial visibility
      setTimeout(init, 500);
    });
  } else {
    setTimeout(init, 500);
  }

  // Export for debugging
  window.dashboardrDeferredCharts = {
    hydrated: hydratedCharts,
    cache: optionsCache,
    checkAndHydrate: checkAndHydrate
  };

})();
