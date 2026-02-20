/**
 * Chart Registry & Backend Adapters
 * ==================================
 *
 * Central registry for all interactive elements (charts, tables) rendered
 * on a dashboardr page.  The registry serves two purposes:
 *
 *   1. **Lookup** — `input_filter.js` queries the registry to find
 *      charts/tables that need updating when a filter changes.
 *   2. **State preservation** — each entry stores a deep-cloned copy
 *      of its original data (`entry.original`) so filters can be
 *      "reset" back to the unfiltered state.
 *
 * Supported backends:
 *   - **highcharter** (Highcharts)  — primary; full filter support
 *   - **plotly**                    — original-state storage only
 *   - **echarts4r** (ECharts)       — original-state storage only
 *   - **ggiraph**                   — static (no client-side filtering)
 *
 * Registration happens automatically via inline `<script>` tags that
 * dashboardr injects next to each rendered widget (see page_generation.R
 * and viz_generation.R).
 *
 * Public API (attached to `window`):
 *   dashboardrChartRegistry.registerChart(entry)
 *   dashboardrChartRegistry.registerTable(entry)
 *   dashboardrChartRegistry.registerDT(entry)
 *   dashboardrChartRegistry.registerReactable(entry)
 *   dashboardrChartRegistry.getCharts()      -> Array<entry>
 *   dashboardrChartRegistry.getTables()      -> Array<entry>
 *   dashboardrChartRegistry.getDTs()         -> Array<entry>
 *   dashboardrChartRegistry.getReactables()  -> Array<entry>
 *   dashboardrChartRegistry.resolveHighchart(entry) -> Highcharts.Chart|null
 *   dashboardrChartRegistry.deepClone(obj)   -> Object|null
 *   dashboardrChartRegistry.adapters         -> backend-specific helpers
 *
 * Convenience aliases (legacy):
 *   window.dashboardrRegisterChart(entry)
 *   window.dashboardrRegisterTable(entry)
 *   window.dashboardrRegisterDT(entry)
 *   window.dashboardrRegisterReactable(entry)
 */
(function() {
  'use strict';

  // -----------------------------------------------------------------
  // Internal registry — keyed by element id
  // -----------------------------------------------------------------
  const registry = {
    charts: {},
    tables: {},
    dts: {},
    reactables: {}
  };

  /** JSON round-trip clone; returns null if the object is not serialisable. */
  function deepClone(obj) {
    try { return JSON.parse(JSON.stringify(obj)); } catch (e) { return null; }
  }

  // -----------------------------------------------------------------
  // Registration functions
  // -----------------------------------------------------------------

  /**
   * Register a chart (Highcharts, Plotly, ECharts, or ggiraph).
   * @param {Object} entry
   * @param {string} entry.id         - Unique DOM id of the chart container.
   * @param {string} entry.backend    - One of "highcharter", "plotly", "echarts4r", "ggiraph".
   * @param {Element} [entry.el]      - The DOM element.
   * @param {Object}  [entry.x]       - The htmlwidget `x` config object.
   * @param {string[]} [entry.filterVars] - Column names this chart responds to.
   * @param {Object}  [entry.original] - Deep-cloned original series data.
   */
  function registerChart(entry) {
    if (!entry || !entry.id || !entry.backend) return;
    const normalized = {
      id: entry.id,
      backend: entry.backend,
      el: entry.el || null,
      x: entry.x || null,
      filterVars: entry.filterVars || null,
      original: entry.original || null,
      chart: null
    };
    registry.charts[entry.id] = normalized;
  }

  /**
   * Register a plain HTML table for cross-tab filtering.
   * @param {Object} entry
   * @param {string}   entry.id       - Table container id.
   * @param {Object[]} entry.data     - Row-oriented data array.
   * @param {Object[]} entry.columns  - Column definitions.
   * @param {string[]} [entry.filterVars] - Column names to filter on.
   */
  function registerTable(entry) {
    if (!entry || !entry.id) return;
    registry.tables[entry.id] = {
      id: entry.id,
      data: entry.data || [],
      columns: entry.columns || [],
      filterVars: entry.filterVars || null
    };
  }

  /**
   * Register a DT (DataTables) widget.
   * @param {Object} entry
   */
  function registerDT(entry) {
    if (!entry || !entry.id) return;
    registry.dts[entry.id] = {
      id: entry.id,
      el: entry.el || null,
      data: entry.data || null,
      filterVars: entry.filterVars || null
    };
  }

  /**
   * Register a reactable widget.
   * @param {Object} entry
   */
  function registerReactable(entry) {
    if (!entry || !entry.id) return;
    registry.reactables[entry.id] = {
      id: entry.id,
      el: entry.el || null,
      data: entry.data || null,
      filterVars: entry.filterVars || null
    };
  }

  // -----------------------------------------------------------------
  // Accessors
  // -----------------------------------------------------------------

  function getCharts() { return Object.values(registry.charts); }
  function getTables() { return Object.values(registry.tables); }
  function getDTs() { return Object.values(registry.dts); }
  function getReactables() { return Object.values(registry.reactables); }

  // -----------------------------------------------------------------
  // Highcharts resolution
  // -----------------------------------------------------------------

  /**
   * Lazily resolve a Highcharts.Chart instance from an entry.
   *
   * Highcharts doesn't expose a direct id→chart lookup, so we search
   * `Highcharts.charts` by DOM element or by the chart-level `id`
   * option.  The result is cached on `entry.chart`.
   *
   * @param {Object} entry - A registered chart entry.
   * @returns {Highcharts.Chart|null}
   */
  function resolveHighchart(entry) {
    if (entry.chart) return entry.chart;
    if (typeof Highcharts === 'undefined' || !entry.el) return null;
    const charts = Highcharts.charts.filter(c => c);
    let found = charts.find(c => c.renderTo === entry.el);
    if (!found && entry.id) {
      found = charts.find(c => c.options && c.options.chart && c.options.chart.id === entry.id);
    }
    entry.chart = found || null;
    return entry.chart;
  }

  // -----------------------------------------------------------------
  // Backend adapters — store/restore original data per backend
  // -----------------------------------------------------------------

  const adapters = {
    /** Highcharts: clone series data + x-axis categories */
    highcharter: {
      resolve: resolveHighchart,
      storeOriginal: function(entry) {
        const chart = resolveHighchart(entry);
        if (!chart || entry.original) return;
        const series = (chart.series || [])
          .filter(s => s && typeof s === 'object')
          .map(s => ({
          name: s.name,
          data: deepClone(s.options.data || [])
        }));
        const categories = chart.xAxis && chart.xAxis[0] && chart.xAxis[0].categories
          ? deepClone(chart.xAxis[0].categories)
          : null;
        entry.original = { series, categories };
      }
    },
    /** Plotly: clone data traces + layout */
    plotly: {
      storeOriginal: function(entry) {
        if (!entry.el || entry.original) return;
        const data = entry.el.data ? deepClone(entry.el.data) : null;
        const layout = entry.el.layout ? deepClone(entry.el.layout) : null;
        entry.original = { data, layout };
      }
    },
    /** ECharts: clone the full option object */
    echarts4r: {
      storeOriginal: function(entry) {
        if (!entry.el || entry.original) return;
        if (typeof echarts === 'undefined') return;
        const inst = echarts.getInstanceByDom(entry.el);
        if (!inst) return;
        const option = inst.getOption ? deepClone(inst.getOption()) : null;
        entry.original = { option };
      }
    },
    /** ggiraph: static SVG — no client-side data to preserve */
    ggiraph: {
      storeOriginal: function() { /* no-op */ }
    }
  };

  // -----------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------

  window.dashboardrChartRegistry = {
    registerChart,
    registerTable,
    registerDT,
    registerReactable,
    getCharts,
    getTables,
    getDTs,
    getReactables,
    resolveHighchart,
    deepClone,
    adapters
  };

  // Legacy convenience aliases (used by older inline registration scripts)
  window.dashboardrRegisterChart = registerChart;
  window.dashboardrRegisterTable = registerTable;
  window.dashboardrRegisterDT = registerDT;
  window.dashboardrRegisterReactable = registerReactable;
})();
