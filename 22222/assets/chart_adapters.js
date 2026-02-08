(function() {
  'use strict';

  const registry = {
    charts: {},
    tables: {},
    dts: {},
    reactables: {}
  };

  function deepClone(obj) {
    try { return JSON.parse(JSON.stringify(obj)); } catch (e) { return null; }
  }

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

  function registerTable(entry) {
    if (!entry || !entry.id) return;
    registry.tables[entry.id] = {
      id: entry.id,
      data: entry.data || [],
      columns: entry.columns || [],
      filterVars: entry.filterVars || null
    };
  }

  function registerDT(entry) {
    if (!entry || !entry.id) return;
    registry.dts[entry.id] = {
      id: entry.id,
      el: entry.el || null,
      data: entry.data || null,
      filterVars: entry.filterVars || null
    };
  }

  function registerReactable(entry) {
    if (!entry || !entry.id) return;
    registry.reactables[entry.id] = {
      id: entry.id,
      el: entry.el || null,
      data: entry.data || null,
      filterVars: entry.filterVars || null
    };
  }

  function getCharts() { return Object.values(registry.charts); }
  function getTables() { return Object.values(registry.tables); }
  function getDTs() { return Object.values(registry.dts); }
  function getReactables() { return Object.values(registry.reactables); }

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

  const adapters = {
    highcharter: {
      resolve: resolveHighchart,
      storeOriginal: function(entry) {
        const chart = resolveHighchart(entry);
        if (!chart || entry.original) return;
        const series = chart.series.map(s => ({
          name: s.name,
          data: deepClone(s.options.data || [])
        }));
        const categories = chart.xAxis && chart.xAxis[0] && chart.xAxis[0].categories
          ? deepClone(chart.xAxis[0].categories)
          : null;
        entry.original = { series, categories };
      }
    },
    plotly: {
      storeOriginal: function(entry) {
        if (!entry.el || entry.original) return;
        const data = entry.el.data ? deepClone(entry.el.data) : null;
        const layout = entry.el.layout ? deepClone(entry.el.layout) : null;
        entry.original = { data, layout };
      }
    },
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
    ggiraph: {
      storeOriginal: function() { /* no-op */ }
    }
  };

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

  window.dashboardrRegisterChart = registerChart;
  window.dashboardrRegisterTable = registerTable;
  window.dashboardrRegisterDT = registerDT;
  window.dashboardrRegisterReactable = registerReactable;
})();
