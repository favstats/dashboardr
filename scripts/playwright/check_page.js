async (page) => {
  const scenario = JSON.parse('__SCENARIO_JSON__');
  const startedAt = new Date().toISOString();
  const startMs = Date.now();
  const failures = [];
  const interactionResults = {};

  const requiredSelectors = Array.isArray(scenario.required_selectors)
    ? scenario.required_selectors
    : (scenario.required_selectors ? [scenario.required_selectors] : []);
  const requiredTexts = Array.isArray(scenario.required_texts)
    ? scenario.required_texts
    : (scenario.required_texts ? [scenario.required_texts] : []);
  const forbiddenTexts = Array.isArray(scenario.forbidden_texts)
    ? scenario.forbidden_texts
    : (scenario.forbidden_texts ? [scenario.forbidden_texts] : []);
  const interactionPlan = Array.isArray(scenario.interaction_plan)
    ? scenario.interaction_plan
    : (scenario.interaction_plan ? [scenario.interaction_plan] : []);
  const expectedBackends = Array.isArray(scenario.expect_chart_backend)
    ? scenario.expect_chart_backend
    : (scenario.expect_chart_backend ? [scenario.expect_chart_backend] : []);
  const dynamicTextSelectors = Array.isArray(scenario.dynamic_text_selectors)
    ? scenario.dynamic_text_selectors
    : (scenario.dynamic_text_selectors ? [scenario.dynamic_text_selectors] : []);
  const normalizeStringList = (value) => {
    if (Array.isArray(value)) {
      return value.map((x) => String(x || '').trim()).filter((x) => x.length > 0);
    }
    if (value === null || value === undefined) return [];
    const single = String(value).trim();
    return single.length > 0 ? [single] : [];
  };
  const dynamicBindingRules = (() => {
    const raw = Array.isArray(scenario.dynamic_binding_rules)
      ? scenario.dynamic_binding_rules
      : (scenario.dynamic_binding_rules ? [scenario.dynamic_binding_rules] : []);
    return raw
      .map((rule) => {
        if (!rule || typeof rule !== 'object') return null;
        const selector = String(rule.selector || '').trim();
        if (!selector) return null;
        const mode = String(rule.match_mode || 'any').toLowerCase() === 'all' ? 'all' : 'any';
        return {
          selector,
          vars: normalizeStringList(rule.vars || rule.filter_vars || rule.inputs || []),
          match_mode: mode,
          required: rule.required !== false,
          require_visible: rule.require_visible !== false
        };
      })
      .filter((x) => !!x);
  })();
  const fontExpectations = (() => {
    const raw = Array.isArray(scenario.font_expectations)
      ? scenario.font_expectations
      : (scenario.font_expectations ? [scenario.font_expectations] : []);
    return raw
      .map((rule) => {
        if (!rule) return null;
        if (typeof rule === 'string') {
          const selector = String(rule).trim();
          if (!selector) return null;
          return {
            selector,
            contains_any: [],
            not_contains_any: [],
            min_size_px: null,
            required: true
          };
        }
        if (typeof rule !== 'object') return null;
        const selector = String(rule.selector || '').trim();
        if (!selector) return null;
        const minSizeRaw = Number(rule.min_size_px);
        return {
          selector,
          contains_any: normalizeStringList(rule.contains_any || rule.contains || rule.expected_contains_any),
          not_contains_any: normalizeStringList(rule.not_contains_any || rule.forbid_contains_any),
          min_size_px: Number.isFinite(minSizeRaw) ? minSizeRaw : null,
          required: rule.required !== false
        };
      })
      .filter((x) => !!x);
  })();

  const fail = (msg) => {
    failures.push(String(msg));
  };

  const wait = async (ms) => {
    await page.waitForTimeout(ms);
  };

  const isTruthy = (value) => value === true || value === 'true';
  const minNonEmptyChartsExpectedRaw = Number(scenario.min_non_empty_charts_expected);
  const minNonEmptyChartsExpected = Number.isFinite(minNonEmptyChartsExpectedRaw)
    ? minNonEmptyChartsExpectedRaw
    : null;
  const maxLargeEmptyCardsRaw = Number(scenario.max_large_empty_cards);
  const maxLargeEmptyCards = Number.isFinite(maxLargeEmptyCardsRaw)
    ? maxLargeEmptyCardsRaw
    : null;
  const largeEmptyCardMinHeightRaw = Number(scenario.large_empty_card_min_height);
  const largeEmptyCardMinHeight = Number.isFinite(largeEmptyCardMinHeightRaw)
    ? largeEmptyCardMinHeightRaw
    : 180;
  const largeEmptyCardMinWidthRaw = Number(scenario.large_empty_card_min_width);
  const largeEmptyCardMinWidth = Number.isFinite(largeEmptyCardMinWidthRaw)
    ? largeEmptyCardMinWidthRaw
    : 260;
  const requireEducationBoxplotCategories = isTruthy(scenario.require_education_boxplot_categories);
  const preferredSliderVar = (typeof scenario.preferred_slider_var === 'string' && scenario.preferred_slider_var.length > 0)
    ? scenario.preferred_slider_var
    : null;
  const requireAllInputsAffectAllCharts = isTruthy(scenario.require_all_inputs_affect_all_charts);
  const requireAllChartsChangeOnFilter = requireAllInputsAffectAllCharts || isTruthy(scenario.require_all_charts_change_on_filter);
  const requireAllChartsChangeOnSlider = requireAllInputsAffectAllCharts || isTruthy(scenario.require_all_charts_change_on_slider);
  const requireAllInputVarsAffectAllCharts = requireAllInputsAffectAllCharts || isTruthy(scenario.require_all_input_vars_affect_all_charts);
  const requireShowWhenConsistency = isTruthy(scenario.require_show_when_consistency) || isTruthy(scenario.require_show_when_truth_table);
  const expectDynamicTitleEffect = isTruthy(scenario.expect_dynamic_title_effect);
  const requireDynamicTitlePlaceholdersResolved = isTruthy(scenario.require_dynamic_title_placeholders_resolved);
  const expectModalEffect = isTruthy(scenario.expect_modal_effect);
  const expectTooltipEffect = isTruthy(scenario.expect_tooltip_effect);
  const localFileUrl = (typeof scenario.local_file_url === 'string' && scenario.local_file_url.length > 0)
    ? scenario.local_file_url
    : '';
  const localFilePath = (typeof scenario.local_file_path === 'string' && scenario.local_file_path.length > 0)
    ? scenario.local_file_path
    : '';
  const captureSliderValueText = async () => {
    return await page.evaluate(() => {
      return Array.from(document.querySelectorAll('.dashboardr-slider-value'))
        .map((el) => (el.textContent || '').trim())
        .join('|');
    });
  };

  const captureSelectorDynamicText = async () => {
    if (!dynamicTextSelectors.length) return '';
    return await page.evaluate((selectors) => {
      const isVisible = (el) => {
        if (!el) return false;
        if (el.classList && el.classList.contains('dashboardr-sw-hidden')) return false;
        const st = window.getComputedStyle(el);
        if (!st || st.display === 'none' || st.visibility === 'hidden' || st.opacity === '0') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
      };

      const parts = [];
      (selectors || []).forEach((selector) => {
        const nodes = Array.from(document.querySelectorAll(String(selector)));
        if (!nodes.length) return;
        const visibleNodes = nodes.filter((node) => isVisible(node));
        visibleNodes.forEach((node) => {
          const txt = String(node.innerText || node.textContent || '').trim().replace(/\s+/g, ' ');
          if (txt) parts.push(`${selector}::${txt}`);
        });
      });
      return parts.join('|');
    }, dynamicTextSelectors);
  };

  const captureDynamicTextSnapshot = async () => {
    const sliderText = await captureSliderValueText();
    if (!dynamicTextSelectors.length) {
      return {
        mode: 'slider_values',
        text: sliderText,
        slider_text: sliderText,
        selectors_text: ''
      };
    }
    const selectorsText = await captureSelectorDynamicText();
    return {
      mode: 'selectors',
      text: selectorsText,
      slider_text: sliderText,
      selectors_text: selectorsText
    };
  };

  const buildDynamicTextResult = (beforeSnapshot, afterSnapshot) => {
    const beforeText = String((beforeSnapshot && beforeSnapshot.text) || '');
    const afterText = String((afterSnapshot && afterSnapshot.text) || '');
    return {
      mode: (beforeSnapshot && beforeSnapshot.mode) || (afterSnapshot && afterSnapshot.mode) || 'slider_values',
      before: beforeText,
      after: afterText,
      changed: beforeText !== afterText,
      before_slider_text: String((beforeSnapshot && beforeSnapshot.slider_text) || ''),
      after_slider_text: String((afterSnapshot && afterSnapshot.slider_text) || ''),
      before_selectors_text: String((beforeSnapshot && beforeSnapshot.selectors_text) || ''),
      after_selectors_text: String((afterSnapshot && afterSnapshot.selectors_text) || '')
    };
  };

  const captureDynamicTitleSnapshot = async () => {
    return await page.evaluate((expectedBackendsArg) => {
      const wanted = Array.isArray(expectedBackendsArg)
        ? expectedBackendsArg.map((x) => String(x || '').trim()).filter((x) => x.length > 0)
        : [];
      const wants = (backend) => wanted.length === 0 || wanted.includes(String(backend || ''));
      const rows = [];
      const addRow = (backend, id, title) => {
        if (!wants(backend)) return;
        const txt = String(title == null ? '' : title).replace(/\s+/g, ' ').trim();
        rows.push({
          backend: String(backend || ''),
          id: String(id || ''),
          title: txt
        });
      };

      if (typeof Highcharts !== 'undefined' && Array.isArray(Highcharts.charts)) {
        Highcharts.charts.filter((c) => !!c).forEach((chart, idx) => {
          const cid = (chart.options && chart.options.chart && chart.options.chart.id)
            || (chart.renderTo && chart.renderTo.id)
            || `highchart-${idx + 1}`;
          const title = (chart.title && chart.title.textStr) || '';
          addRow('highcharter', cid, title);
        });
      }

      const registry = window.dashboardrChartRegistry;
      const entries = registry && typeof registry.getCharts === 'function'
        ? registry.getCharts()
        : [];
      entries.forEach((entry, idx) => {
        const backend = String(entry && entry.backend || '');
        if (!backend || backend === 'highcharter') return;
        const id = String(entry && entry.id || `${backend}-${idx + 1}`);
        if (backend === 'plotly' && typeof Plotly !== 'undefined' && entry && entry.el) {
          const layout = entry.el.layout || entry.el._fullLayout || {};
          const title = (layout.title && (layout.title.text != null ? layout.title.text : layout.title))
            || '';
          addRow('plotly', id, title);
        } else if (backend === 'echarts4r' && typeof echarts !== 'undefined' && entry && entry.el) {
          const inst = echarts.getInstanceByDom(entry.el);
          if (!inst) return;
          const option = inst.getOption ? inst.getOption() : null;
          if (!option) return;
          const t = Array.isArray(option.title) ? option.title[0] : option.title;
          const title = t && typeof t === 'object' ? (t.text || '') : '';
          addRow('echarts4r', id, title);
        }
      });

      rows.sort((a, b) => {
        const ka = `${a.backend}:${a.id}`;
        const kb = `${b.backend}:${b.id}`;
        return ka.localeCompare(kb);
      });

      const placeholderPattern = /\{\w+\}/;
      const unresolved = rows.filter((row) => placeholderPattern.test(row.title));
      const text = rows.map((row) => `${row.backend}:${row.id}:${row.title}`).join('|');

      return {
        text,
        titles: rows,
        unresolved_placeholders: unresolved,
        has_placeholders: unresolved.length > 0
      };
    }, expectedBackends);
  };

  const buildDynamicTitleResult = (beforeSnapshot, afterSnapshot) => {
    const beforeText = String((beforeSnapshot && beforeSnapshot.text) || '');
    const afterText = String((afterSnapshot && afterSnapshot.text) || '');
    const unresolved = (afterSnapshot && Array.isArray(afterSnapshot.unresolved_placeholders))
      ? afterSnapshot.unresolved_placeholders
      : [];
    return {
      before: beforeText,
      after: afterText,
      changed: beforeText !== afterText,
      unresolved_placeholders: unresolved,
      after_has_placeholders: unresolved.length > 0
    };
  };

  const captureModalState = async () => {
    return await page.evaluate(() => {
      const isVisible = (el) => {
        if (!el) return false;
        const st = window.getComputedStyle(el);
        if (!st || st.display === 'none' || st.visibility === 'hidden' || st.opacity === '0') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
      };

      const customActive = Array.from(document.querySelectorAll('.modal-overlay.active')).filter(isVisible);
      const dashboardrActive = Array.from(document.querySelectorAll('#dashboardr-modal-overlay, .dashboardr-modal-overlay'))
        .filter(isVisible);
      const bootstrapActive = Array.from(document.querySelectorAll('.modal.show, .modal[aria-modal="true"]')).filter(isVisible);
      const active = dashboardrActive.length
        ? dashboardrActive
        : (customActive.length ? customActive : bootstrapActive);

      return {
        active_count: active.length,
        first_id: active[0] ? (active[0].id || null) : null,
        first_class: active[0] ? (active[0].className || null) : null
      };
    });
  };

  const captureTooltipSnapshot = async () => {
    return await page.evaluate(() => {
      const isVisible = (el) => {
        if (!el) return false;
        const st = window.getComputedStyle(el);
        if (!st || st.display === 'none' || st.visibility === 'hidden' || st.opacity === '0') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
      };
      const textOf = (el) => String(el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim();
      const rows = [];

      const selectors = [
        '.hoverlayer .hovertext',
        '.hoverlayer',
        '.highcharts-tooltip text',
        '.highcharts-label.highcharts-tooltip',
        '.echarts-tooltip',
        '#dashboardr-tooltip'
      ];
      selectors.forEach((sel) => {
        Array.from(document.querySelectorAll(sel))
          .filter(isVisible)
          .forEach((el) => {
            const txt = textOf(el);
            if (txt) rows.push(`${sel}:${txt}`);
          });
      });

      const joined = rows.join('|');
      return {
        text: joined,
        count: rows.length,
        has_undefined: /\bundefined\b/i.test(joined)
      };
    });
  };

  const assertForbiddenTextsAbsent = async (stage) => {
    for (const textNeedle of forbiddenTexts) {
      const found = await page.evaluate((needle) => {
        if (!document || !document.body) return false;
        const normalize = (value) => String(value || '')
          .replace(/\s+/g, ' ')
          .trim()
          .toLowerCase();
        const text = normalize(document.body.innerText || '');
        const target = normalize(needle);
        return text.includes(target);
      }, textNeedle);
      if (found) {
        fail(`Forbidden text found (${stage}): ${textNeedle}`);
      }
    }
  };

  const captureChartState = async () => {
    return await page.evaluate(() => {
      const isVisible = (el) => {
        if (!el) return false;
        const style = window.getComputedStyle(el);
        if (!style || style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') {
          return false;
        }
        const rect = el.getBoundingClientRect();
        return rect.width > 0 && rect.height > 0;
      };

      const normalizeValue = (value) => {
        if (value === null || value === undefined) return '';
        if (typeof value === 'number') {
          return Number.isFinite(value) ? value.toFixed(6) : String(value);
        }
        if (typeof value === 'string' || typeof value === 'boolean') {
          return String(value);
        }
        if (Array.isArray(value)) {
          return `[${value.map((x) => normalizeValue(x)).join(',')}]`;
        }
        if (typeof value === 'object') {
          if (Object.prototype.hasOwnProperty.call(value, 'value')) return normalizeValue(value.value);
          if (Object.prototype.hasOwnProperty.call(value, 'y')) return normalizeValue(value.y);
          if (Object.prototype.hasOwnProperty.call(value, 'x')) return normalizeValue(value.x);
          const keys = Object.keys(value).sort();
          return `{${keys.map((k) => `${k}:${normalizeValue(value[k])}`).join(',')}}`;
        }
        return String(value);
      };

      const hashString = (input) => {
        const str = String(input || '');
        let hash = 5381;
        for (let i = 0; i < str.length; i += 1) {
          hash = ((hash << 5) + hash) + str.charCodeAt(i);
          hash = hash >>> 0;
        }
        return hash.toString(16);
      };

      const summarizeArray = (arr) => {
        const data = Array.isArray(arr) ? arr : [];
        const normalized = data.map((x) => normalizeValue(x)).join('|');
        return `${data.length}:${hashString(normalized)}`;
      };

      const summarizeHighcharts = () => {
        const charts = (window.Highcharts && Array.isArray(window.Highcharts.charts))
          ? window.Highcharts.charts.filter((x) => !!x && !!x.series)
          : [];
        const chartSummaries = charts.map((chart, chartIndex) => {
          const chartKey = (chart.renderTo && chart.renderTo.id)
            ? chart.renderTo.id
            : `highchart-${chartIndex + 1}`;
          const seriesSummary = chart.series.map((s) => {
            const optionsData = Array.isArray(s && s.options && s.options.data) ? s.options.data : [];
            const pointsData = Array.isArray(s && s.points) ? s.points : [];
            const rawData = Array.isArray(s && s.data) ? s.data : [];

            const records = (pointsData.length ? pointsData : (rawData.length ? rawData : optionsData)).map((pt) => {
              if (Array.isArray(pt)) {
                return { x: pt[0], y: pt[1] };
              }
              if (pt && typeof pt === 'object') {
                const x = Object.prototype.hasOwnProperty.call(pt, 'x') ? pt.x : null;
                const y = Object.prototype.hasOwnProperty.call(pt, 'y')
                  ? pt.y
                  : (Object.prototype.hasOwnProperty.call(pt, 'value') ? pt.value : null);
                return { x, y };
              }
              return { x: null, y: pt };
            });

            const xs = Array.isArray(s && s.xData) && s.xData.length
              ? s.xData
              : records.map((r) => r.x);
            const ys = Array.isArray(s && s.yData) && s.yData.length
              ? s.yData
              : records.map((r) => r.y);
            const pointCount = Math.max(xs.length, ys.length, records.length);
            const visibility = (s && s.visible === false) || (s && s.options && s.options.visible === false)
              ? 'hidden'
              : 'shown';

            return {
              nonEmpty: pointCount > 0,
              signature: `${s.type || 'series'}:${s.name || 'series'}:${visibility}:${pointCount}:${summarizeArray(xs)}:${summarizeArray(ys)}`
            };
          });

          const hasData = seriesSummary.some((s) => s.nonEmpty);
          const seriesSignature = seriesSummary.map((s) => s.signature).join('|');
          return {
            key: chartKey,
            nonEmpty: hasData,
            signature: `${chartKey}=>${seriesSignature}`
          };
        });
        const signatures = chartSummaries.map((s) => s.signature);
        const nonEmptyCount = chartSummaries.filter((s) => s.nonEmpty).length;
        const visibleCount = charts.filter((chart) => chart.renderTo && isVisible(chart.renderTo)).length;
        return {
          count: charts.length,
          visible: visibleCount,
          non_empty: nonEmptyCount,
          entries: chartSummaries.map((s) => ({
            key: s.key,
            signature: s.signature,
            non_empty: !!s.nonEmpty
          })),
          signature: signatures.join('||')
        };
      };

      const summarizePlotly = () => {
        const divs = Array.from(document.querySelectorAll('.js-plotly-plot'));
        const divSummaries = divs.map((div, divIndex) => {
          const divKey = div.id || `plotly-${divIndex + 1}`;
          const traces = Array.isArray(div.data) ? div.data : [];
          const traceSummary = traces.map((trace) => {
            const xs = Array.isArray(trace.x) ? trace.x : [];
            const ys = Array.isArray(trace.y) ? trace.y : [];
            const zs = Array.isArray(trace.z) ? trace.z : [];
            const values = Array.isArray(trace.values) ? trace.values : [];
            const labels = Array.isArray(trace.labels) ? trace.labels : [];
            const q1 = Array.isArray(trace.q1) ? trace.q1 : [];
            const q3 = Array.isArray(trace.q3) ? trace.q3 : [];
            const median = Array.isArray(trace.median) ? trace.median : [];
            const lowerfence = Array.isArray(trace.lowerfence) ? trace.lowerfence : [];
            const upperfence = Array.isArray(trace.upperfence) ? trace.upperfence : [];
            const pointCount = Math.max(
              xs.length,
              ys.length,
              zs.length,
              values.length,
              labels.length,
              q1.length,
              q3.length,
              median.length,
              lowerfence.length,
              upperfence.length
            );
            const visibility = String((trace && trace.visible) || '').toLowerCase() === 'legendonly'
              ? 'hidden'
              : 'shown';
            return {
              nonEmpty: pointCount > 0,
              signature: `${trace.type || 'trace'}:${visibility}:${pointCount}:${summarizeArray(xs)}:${summarizeArray(ys)}:${summarizeArray(zs)}:${summarizeArray(values)}:${summarizeArray(labels)}:${summarizeArray(q1)}:${summarizeArray(q3)}:${summarizeArray(median)}`
            };
          });
          const hasData = traceSummary.some((t) => t.nonEmpty);
          const seriesSignature = traceSummary.map((t) => t.signature).join('|');
          return {
            key: divKey,
            nonEmpty: hasData,
            signature: `${divKey}=>${seriesSignature}`
          };
        });
        const signatures = divSummaries.map((d) => d.signature);
        const visibleCount = divs.filter(isVisible).length;
        const nonEmptyCount = divSummaries.filter((d) => d.nonEmpty).length;
        return {
          count: divs.length,
          visible: visibleCount,
          non_empty: nonEmptyCount,
          entries: divSummaries.map((d) => ({
            key: d.key,
            signature: d.signature,
            non_empty: !!d.nonEmpty
          })),
          signature: signatures.join('||')
        };
      };

      const summarizeEcharts = () => {
        const candidates = Array.from(document.querySelectorAll('.echarts4r, .echarts, .html-widget'));
        const instances = [];
        if (window.echarts && typeof window.echarts.getInstanceByDom === 'function') {
          candidates.forEach((el) => {
            const inst = window.echarts.getInstanceByDom(el);
            if (inst) instances.push({ inst, el });
          });
        }
        const instanceSummaries = instances.map(({ inst, el }, instanceIndex) => {
          const chartKey = el.id || `echarts-${instanceIndex + 1}`;
          const option = inst.getOption ? inst.getOption() : {};
          const optionHash = hashString(JSON.stringify(option || {}));
          const datasets = Array.isArray(option && option.dataset)
            ? option.dataset
            : (option && option.dataset ? [option.dataset] : []);
          const datasetSizes = datasets.map((ds) => {
            const src = ds && ds.source;
            if (!Array.isArray(src)) return 0;
            if (!src.length) return 0;
            return Math.max(0, src.length - 1);
          });
          const series = Array.isArray(option && option.series) ? option.series : [];
          const seriesSummary = series.map((x) => {
            const dataArr = Array.isArray(x && x.data) ? x.data : [];
            const datasetIndex = Number(x && x.datasetIndex);
            const datasetCount = Number.isFinite(datasetIndex) && datasetIndex >= 0 && datasetIndex < datasetSizes.length
              ? datasetSizes[datasetIndex]
              : (datasetSizes.length ? Math.max(...datasetSizes) : 0);
            const pointCount = dataArr.length > 0 ? dataArr.length : datasetCount;
            const visibility = x && x.show === false ? 'hidden' : 'shown';
            return {
              nonEmpty: pointCount > 0,
              signature: `${x.type || 'series'}:${visibility}:${pointCount}:${summarizeArray(dataArr)}`
            };
          });
          const hasData = seriesSummary.some((s) => s.nonEmpty);
          const seriesSignature = seriesSummary.map((s) => s.signature).join('|');
          return {
            key: chartKey,
            nonEmpty: hasData,
            signature: `${chartKey}=>${optionHash}:${seriesSignature}`
          };
        });
        const signatures = instanceSummaries.map((x) => x.signature);
        const visibleCount = instances.filter(({ el }) => isVisible(el)).length;
        const nonEmptyCount = instanceSummaries.filter((x) => x.nonEmpty).length;
        return {
          count: instances.length,
          visible: visibleCount,
          non_empty: nonEmptyCount,
          entries: instanceSummaries.map((x) => ({
            key: x.key,
            signature: x.signature,
            non_empty: !!x.nonEmpty
          })),
          signature: signatures.join('||')
        };
      };

      const summarizeGgiraph = () => {
        const roots = Array.from(document.querySelectorAll('.girafe, .ggiraph, svg.girafe-svg, .html-widget.girafe'));
        const entries = roots.map((root, rootIndex) => {
          const key = root.id || `girafe-${rootIndex + 1}`;
          const points = root.querySelectorAll('circle, path, rect').length;
          return {
            key,
            non_empty: points > 0,
            signature: `${key}=>${points}`
          };
        });
        const visibleCount = roots.filter(isVisible).length;
        const nonEmptyCount = roots.filter((root) => root.querySelectorAll('circle, path, rect').length > 0).length;
        return {
          count: roots.length,
          visible: visibleCount,
          non_empty: nonEmptyCount,
          entries,
          signature: entries.map((x) => x.signature).join('||')
        };
      };

      const summarizeLeaflet = () => {
        const nodes = Array.from(document.querySelectorAll('.leaflet-container'));
        const entries = nodes.map((node, nodeIndex) => {
          const key = node.id || `leaflet-${nodeIndex + 1}`;
          const layers = node.querySelectorAll('.leaflet-marker-icon, .leaflet-interactive').length;
          return {
            key,
            non_empty: layers > 0,
            signature: `${key}=>${layers}`
          };
        });
        const visibleCount = nodes.filter(isVisible).length;
        const nonEmptyCount = nodes.filter((node) => node.querySelectorAll('.leaflet-marker-icon, .leaflet-interactive').length > 0).length;
        return {
          count: nodes.length,
          visible: visibleCount,
          non_empty: nonEmptyCount,
          entries,
          signature: entries.map((x) => x.signature).join('||')
        };
      };

      const summarizeTables = () => {
        const tables = Array.from(document.querySelectorAll('table'));
        const tableSummaries = tables.map((table) => {
          const rowNodes = Array.from(table.querySelectorAll('tbody tr'))
            .filter((tr) => !tr.classList.contains('dataTables_empty'));
          const rowCount = rowNodes.length;
          const sampleText = rowNodes.slice(0, 5).map((tr) => {
            const cells = Array.from(tr.querySelectorAll('td, th')).map((c) => (c.textContent || '').trim());
            return cells.join('||');
          }).join('|');
          return {
            nonEmpty: rowCount > 0,
            signature: `${table.id || 'table'}:${rowCount}:${hashString(sampleText)}`
          };
        });
        return {
          count: tables.length,
          non_empty: tableSummaries.filter((t) => t.nonEmpty).length,
          signature: tableSummaries.map((t) => t.signature).join('||')
        };
      };

      const state = {
        highcharter: summarizeHighcharts(),
        plotly: summarizePlotly(),
        echarts4r: summarizeEcharts(),
        ggiraph: summarizeGgiraph(),
        leaflet: summarizeLeaflet(),
        tables: summarizeTables()
      };

      state.signature = [
        `hc:${state.highcharter.signature}`,
        `plotly:${state.plotly.signature}`,
        `echarts:${state.echarts4r.signature}`,
        `girafe:${state.ggiraph.signature}`,
        `leaflet:${state.leaflet.signature}`,
        `tables:${state.tables.signature}`
      ].join('||');

      return state;
    });
  };

  const signatureForExpected = (state) => {
    const tableSig = `tables:${(state && state.tables && state.tables.signature) ? state.tables.signature : ''}`;
    if (!expectedBackends.length || expectedBackends.includes('mixed')) {
      return state.signature;
    }
    const backendSig = expectedBackends.map((name) => {
      const key = String(name);
      const entry = state[key] || {};
      return `${key}:${entry.signature || ''}`;
    }).join('||');
    return `${backendSig}||${tableSig}`;
  };

  const assertExpectedBackendsVisible = (state) => {
    if (!expectedBackends.length) return;
    const known = ['highcharter', 'plotly', 'echarts4r', 'ggiraph', 'leaflet'];
    const normalized = expectedBackends.map((x) => String(x));

    if (normalized.includes('mixed')) {
      const any = known.some((k) => {
        const entry = state[k] || {};
        return (entry.count || 0) > 0 && (entry.visible || 0) > 0;
      });
      if (!any) fail('No visible chart/widget detected for mixed backend expectation.');
      return;
    }

    normalized.forEach((backend) => {
      const entry = state[backend] || {};
      if ((entry.count || 0) < 1) {
        fail(`Expected backend '${backend}' was not detected on page.`);
      } else if ((entry.visible || 0) < 1) {
        fail(`Expected backend '${backend}' has no visible chart/widget.`);
      }
    });
  };

  const countNonEmptyForExpected = (state) => {
    const known = ['highcharter', 'plotly', 'echarts4r', 'ggiraph', 'leaflet'];
    if (!expectedBackends.length || expectedBackends.includes('mixed')) {
      return known.reduce((acc, backend) => {
        const entry = state[backend] || {};
        return acc + Number(entry.non_empty || 0);
      }, 0);
    }
    return expectedBackends.reduce((acc, backend) => {
      const entry = state[String(backend)] || {};
      return acc + Number(entry.non_empty || 0);
    }, 0);
  };

  const resolveExpectedBackends = (state) => {
    const known = ['highcharter', 'plotly', 'echarts4r', 'ggiraph', 'leaflet'];
    if (expectedBackends.length && !expectedBackends.includes('mixed')) {
      return expectedBackends.map((x) => String(x));
    }
    return known.filter((backend) => Number(((state || {})[backend] || {}).count || 0) > 0);
  };

  const backendEntries = (state, backend) => {
    const list = ((state || {})[backend] || {}).entries;
    if (!Array.isArray(list)) return [];
    return list.map((x, idx) => ({
      key: String(x && x.key ? x.key : `${backend}-${idx + 1}`),
      signature: String(x && x.signature ? x.signature : '')
    }));
  };

  const compareBackendEntries = (beforeState, afterState, backend) => {
    const beforeEntries = backendEntries(beforeState, backend);
    const afterEntries = backendEntries(afterState, backend);
    const afterByKey = new Map(afterEntries.map((x) => [x.key, x.signature]));
    let compared = 0;
    let changed = 0;
    const unchanged = [];

    beforeEntries.forEach((entry, idx) => {
      const afterSig = afterByKey.has(entry.key)
        ? afterByKey.get(entry.key)
        : (afterEntries[idx] ? afterEntries[idx].signature : null);
      if (afterSig === null || afterSig === undefined) return;
      compared += 1;
      if (String(afterSig) !== String(entry.signature)) {
        changed += 1;
      } else {
        unchanged.push(entry.key);
      }
    });

    return {
      backend,
      total_before: beforeEntries.length,
      total_after: afterEntries.length,
      compared,
      changed,
      unchanged
    };
  };

  const compareExpectedBackendEntryChanges = (beforeState, afterState) => {
    const backends = resolveExpectedBackends(beforeState);
    const perBackend = backends.map((backend) => compareBackendEntries(beforeState, afterState, backend));
    const failed = perBackend.filter((x) => x.total_before > 0 && x.compared > 0 && x.changed < x.compared);
    const empty = perBackend.filter((x) => x.total_before > 0 && x.compared === 0);
    return {
      ok: failed.length === 0 && empty.length === 0,
      per_backend: perBackend,
      failed,
      empty
    };
  };

  const formatBackendChangeSummary = (comparison) => {
    const rows = Array.isArray(comparison && comparison.per_backend) ? comparison.per_backend : [];
    if (!rows.length) return 'no-backend-comparison';
    return rows.map((x) => `${x.backend}:${x.changed}/${x.compared}`).join(', ');
  };

  const performFilterInteraction = async () => {
    const dynamicTextBefore = await captureDynamicTextSnapshot();
    const dynamicTitleBefore = await captureDynamicTitleSnapshot();
    const before = await captureChartState();
    const preferredFilterVar = (typeof scenario.preferred_filter_var === 'string' && scenario.preferred_filter_var.length > 0)
      ? scenario.preferred_filter_var
      : null;

    const action = await page.evaluate((preferredFilterVarArg) => {
      const result = { performed: false, kind: null, detail: null };
      const preferredFilterVar = (preferredFilterVarArg || '').trim();
      const visible = (el) => {
        if (!el) return false;
        const st = window.getComputedStyle(el);
        if (!st || st.display === 'none' || st.visibility === 'hidden') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
      };

      const pickDifferent = (vals, current) => {
        if (!Array.isArray(vals)) return null;
        for (const v of vals) {
          if (String(v) !== String(current)) return String(v);
        }
        return null;
      };

      const clickInputOrLabel = (input) => {
        if (!input) return false;
        const label = input.closest('label');
        if (label && typeof label.click === 'function') {
          label.click();
          return true;
        }
        if (typeof input.click === 'function') {
          input.click();
          return true;
        }
        return false;
      };

      const isPreferred = (el) => {
        if (!preferredFilterVar) return false;
        const filterVar = String(el.getAttribute('data-filter-var') || '').trim();
        return filterVar === preferredFilterVar;
      };

      if (preferredFilterVar) {
        const preferredCheckboxGroups = Array.from(document.querySelectorAll('.dashboardr-checkbox-group'))
          .filter((el) => visible(el) && isPreferred(el));
        for (const group of preferredCheckboxGroups) {
          const inputs = Array.from(group.querySelectorAll('input[type="checkbox"]')).filter((el) => !el.disabled);
          if (!inputs.length) continue;

          const checked = inputs.filter((el) => el.checked);
          let target = null;
          if (checked.length > 1) {
            target = checked[0];
          } else if (checked.length === 1) {
            target = inputs.find((el) => !el.checked) || checked[0];
          } else {
            target = inputs[0];
          }

          if (target && clickInputOrLabel(target)) {
            result.performed = true;
            result.kind = 'filter';
            result.detail = 'checkbox-preferred';
            return result;
          }
        }

        const preferredRadioGroups = Array.from(document.querySelectorAll('.dashboardr-radio-group'))
          .filter((el) => visible(el) && isPreferred(el));
        if (preferredRadioGroups.length > 0) {
          const radios = Array.from(preferredRadioGroups[0].querySelectorAll('input[type="radio"]')).filter((r) => !r.disabled);
          if (radios.length > 1) {
            const current = radios.find((r) => r.checked);
            const candidate = radios.find((r) => !r.checked) || radios[0];
            if (candidate && candidate !== current && clickInputOrLabel(candidate)) {
              result.performed = true;
              result.kind = 'filter';
              result.detail = 'radio-preferred';
              return result;
            }
          }
        }

        const preferredSelects = Array.from(document.querySelectorAll('select.dashboardr-input, select[data-filter-var]'))
          .filter((el) => !el.disabled && isPreferred(el));
        if (preferredSelects.length > 0) {
          const sel = preferredSelects[0];
          const selId = sel.id || '';
          const choicesInst = selId && window.dashboardrChoicesInstances && window.dashboardrChoicesInstances[selId];
          // Get all values - Choices.js may reduce sel.options to only selected item(s)
          let allValues = [];
          let selectedValues = [];
          if (choicesInst && choicesInst._store && choicesInst._store.choices) {
            const storeChoices = choicesInst._store.choices.filter((c) => !c.disabled && c.value !== '');
            allValues = storeChoices.map((c) => c.value);
            selectedValues = storeChoices.filter((c) => c.selected).map((c) => c.value);
          } else {
            const nativeOpts = Array.from(sel.options).filter((o) => !o.disabled && o.value !== '');
            allValues = nativeOpts.map((o) => o.value);
            selectedValues = nativeOpts.filter((o) => o.selected).map((o) => o.value);
          }
        if (sel.multiple && allValues.length > 1) {
          const selectedCount = selectedValues.length;
          if (choicesInst && typeof choicesInst.removeActiveItems === 'function') {
            const applyValues = (vals) => {
              choicesInst.removeActiveItems();
              (vals || []).forEach((v) => {
                if (typeof choicesInst.setChoiceByValue === 'function') {
                  choicesInst.setChoiceByValue(v);
                }
              });
            };
            if (selectedCount >= allValues.length) {
              const selectedNow = (typeof choicesInst.getValue === 'function')
                ? [].concat(choicesInst.getValue(true) || [])
                : selectedValues;
              const dropVal = selectedNow[0] || allValues[0];
              if (typeof choicesInst.removeActiveItemsByValue === 'function' && dropVal !== undefined) {
                choicesInst.removeActiveItemsByValue(dropVal);
              } else {
                applyValues(allValues.filter((v) => String(v) !== String(dropVal)));
              }
              result.detail = 'select-multiple-preferred-drop-one-choices';
            } else {
              applyValues(allValues);
              result.detail = 'select-multiple-preferred-all-choices';
            }
          } else {
            const nativeOpts = Array.from(sel.options).filter((o) => !o.disabled && o.value !== '');
            if (selectedCount >= allValues.length) {
              nativeOpts.forEach((o, i) => { o.selected = i < (nativeOpts.length - 1); });
              result.detail = 'select-multiple-preferred-drop-one';
            } else {
              nativeOpts.forEach((o) => { o.selected = true; });
              result.detail = 'select-multiple-preferred-all';
            }
          }
          sel.dispatchEvent(new Event('change', { bubbles: true }));
          result.performed = true;
          result.kind = 'filter';
          return result;
        }
          if (allValues.length > 1) {
            const currentVal = selectedValues.length > 0 ? selectedValues[0] : sel.value;
            const target = pickDifferent(allValues, currentVal);
            if (target !== null) {
              if (choicesInst && typeof choicesInst.setChoiceByValue === 'function') {
                choicesInst.setChoiceByValue(target);
              } else {
                sel.value = target;
              }
              sel.dispatchEvent(new Event('change', { bubbles: true }));
              result.performed = true;
              result.kind = 'filter';
              result.detail = choicesInst ? 'select-single-preferred-choices' : 'select-single-preferred';
              return result;
            }
          }
        }

        const preferredSliders = Array.from(document.querySelectorAll('input[type="range"][data-filter-var], .dashboardr-slider[data-filter-var]'))
          .filter((el) => !el.disabled && isPreferred(el));
        if (preferredSliders.length > 0) {
          const slider = preferredSliders[0];
          const min = Number(slider.min);
          const max = Number(slider.max);
          const stepRaw = Number(slider.step);
          const step = Number.isFinite(stepRaw) && stepRaw > 0 ? stepRaw : 1;
          const current = Number(slider.value);

          if (Number.isFinite(min) && Number.isFinite(max) && Number.isFinite(current) && max > min) {
            const candidate = Math.abs(current - min) < 1e-9 ? Math.min(max, min + step) : min;
            slider.value = String(candidate);
            slider.dispatchEvent(new Event('input', { bubbles: true }));
            slider.dispatchEvent(new Event('change', { bubbles: true }));
            result.performed = true;
            result.kind = 'filter';
            result.detail = 'slider-preferred';
            return result;
          }
        }

        const preferredButtonGroups = Array.from(document.querySelectorAll('.dashboardr-button-group'))
          .filter((el) => visible(el) && isPreferred(el));
        if (preferredButtonGroups.length > 0) {
          const buttons = Array.from(preferredButtonGroups[0].querySelectorAll('.dashboardr-button-option'))
            .filter((btn) => !btn.disabled);
          if (buttons.length > 0) {
            const active = buttons.find((btn) => btn.classList.contains('active'));
            const target = buttons.find((btn) => btn !== active) || buttons[0];
            if (target && typeof target.click === 'function') {
              target.click();
              result.performed = true;
              result.kind = 'filter';
              result.detail = 'button-group-preferred';
              return result;
            }
          }
        }

        const preferredSwitches = Array.from(document.querySelectorAll('input[data-input-type="switch"]'))
          .filter((el) => !el.disabled && visible(el) && isPreferred(el));
        if (preferredSwitches.length > 0) {
          const sw = preferredSwitches[0];
          if (clickInputOrLabel(sw)) {
            result.performed = true;
            result.kind = 'filter';
            result.detail = 'switch-preferred';
            return result;
          }
        }

        const preferredTextInputs = Array.from(document.querySelectorAll('input[data-filter-var]'))
          .filter((el) => !el.disabled && visible(el) && isPreferred(el));
        for (const input of preferredTextInputs) {
          const type = String(input.type || '').toLowerCase();
          if (type === 'text' || type === 'search') {
            input.value = String(input.value || '') + 'x';
            input.dispatchEvent(new Event('input', { bubbles: true }));
            input.dispatchEvent(new Event('change', { bubbles: true }));
            result.performed = true;
            result.kind = 'filter';
            result.detail = 'text-preferred';
            return result;
          }
          if (type === 'number') {
            const currentNum = Number(input.value);
            const minVal = Number(input.min);
            const maxVal = Number(input.max);
            let next = Number.isFinite(currentNum) ? currentNum + 1 : (Number.isFinite(minVal) ? minVal : 1);
            if (Number.isFinite(maxVal) && next > maxVal) next = Number.isFinite(minVal) ? minVal : maxVal;
            input.value = String(next);
            input.dispatchEvent(new Event('input', { bubbles: true }));
            input.dispatchEvent(new Event('change', { bubbles: true }));
            result.performed = true;
            result.kind = 'filter';
            result.detail = 'number-preferred';
            return result;
          }
        }
      }

      const sliders = Array.from(document.querySelectorAll('input[type="range"][data-filter-var], .dashboardr-slider[data-filter-var]'))
        .filter((el) => !el.disabled);
      if (sliders.length > 0) {
        const slider = sliders[0];
        const min = Number(slider.min);
        const max = Number(slider.max);
        const stepRaw = Number(slider.step);
        const step = Number.isFinite(stepRaw) && stepRaw > 0 ? stepRaw : 1;
        const current = Number(slider.value);

        if (Number.isFinite(min) && Number.isFinite(max) && Number.isFinite(current) && max > min) {
          const candidate = Math.abs(current - min) < 1e-9 ? Math.min(max, min + step) : min;
          slider.value = String(candidate);
          slider.dispatchEvent(new Event('input', { bubbles: true }));
          slider.dispatchEvent(new Event('change', { bubbles: true }));
          result.performed = true;
          result.kind = 'filter';
          result.detail = 'slider';
          return result;
        }
      }

      const checkboxGroups = Array.from(document.querySelectorAll('.dashboardr-checkbox-group'))
        .filter((el) => visible(el));
      for (const group of checkboxGroups) {
        const inputs = Array.from(group.querySelectorAll('input[type="checkbox"]')).filter((el) => !el.disabled);
        if (!inputs.length) continue;

        const checked = inputs.filter((el) => el.checked);
        let target = null;
        if (checked.length > 1) {
          target = checked[0];
        } else if (checked.length === 1) {
          target = inputs.find((el) => !el.checked) || checked[0];
        } else {
          target = inputs[0];
        }

        if (target && clickInputOrLabel(target)) {
          result.performed = true;
          result.kind = 'filter';
          result.detail = 'checkbox';
          return result;
        }
      }

      const radioGroups = Array.from(document.querySelectorAll('.dashboardr-radio-group'))
        .filter((el) => visible(el));
      if (radioGroups.length > 0) {
        const radios = Array.from(radioGroups[0].querySelectorAll('input[type="radio"]')).filter((r) => !r.disabled);
        if (radios.length > 1) {
          const current = radios.find((r) => r.checked);
          const candidate = radios.find((r) => !r.checked) || radios[0];
          if (candidate && candidate !== current && clickInputOrLabel(candidate)) {
            result.performed = true;
            result.kind = 'filter';
            result.detail = 'radio';
            return result;
          }
        }
      }

      const selects = Array.from(document.querySelectorAll('select.dashboardr-input, select[data-filter-var]'))
        .filter((el) => !el.disabled);
      if (selects.length > 0) {
        const sel = selects[0];
        const fbSelId = sel.id || '';
        const fbChoicesInst = fbSelId && window.dashboardrChoicesInstances && window.dashboardrChoicesInstances[fbSelId];
        // Get all values - Choices.js may reduce sel.options to only selected item(s)
        let fbAllValues = [];
        let fbSelectedValues = [];
        if (fbChoicesInst && fbChoicesInst._store && fbChoicesInst._store.choices) {
          const storeChoices = fbChoicesInst._store.choices.filter((c) => !c.disabled && c.value !== '');
          fbAllValues = storeChoices.map((c) => c.value);
          fbSelectedValues = storeChoices.filter((c) => c.selected).map((c) => c.value);
        } else {
          const nativeOpts = Array.from(sel.options).filter((o) => !o.disabled && o.value !== '');
          fbAllValues = nativeOpts.map((o) => o.value);
          fbSelectedValues = nativeOpts.filter((o) => o.selected).map((o) => o.value);
        }
        if (sel.multiple && fbAllValues.length > 1) {
          const selectedCount = fbSelectedValues.length;
          if (fbChoicesInst && typeof fbChoicesInst.removeActiveItems === 'function') {
            if (selectedCount >= fbAllValues.length) {
              fbChoicesInst.removeActiveItems();
              fbChoicesInst.setChoiceByValue(fbAllValues.slice(0, fbAllValues.length - 1));
              result.detail = 'select-multiple-drop-one-choices';
            } else {
              fbChoicesInst.removeActiveItems();
              fbChoicesInst.setChoiceByValue(fbAllValues);
              result.detail = 'select-multiple-all-choices';
            }
          } else {
            const nativeOpts = Array.from(sel.options).filter((o) => !o.disabled && o.value !== '');
            if (selectedCount >= fbAllValues.length) {
              nativeOpts.forEach((o, i) => { o.selected = i < (nativeOpts.length - 1); });
              result.detail = 'select-multiple-drop-one';
            } else {
              nativeOpts.forEach((o) => { o.selected = true; });
              result.detail = 'select-multiple-all';
            }
          }
          sel.dispatchEvent(new Event('change', { bubbles: true }));
          result.performed = true;
          result.kind = 'filter';
          return result;
        }
        if (fbAllValues.length > 1) {
          const currentVal = fbSelectedValues.length > 0 ? fbSelectedValues[0] : sel.value;
          const target = pickDifferent(fbAllValues, currentVal);
          if (target !== null) {
            if (fbChoicesInst && typeof fbChoicesInst.setChoiceByValue === 'function') {
              fbChoicesInst.setChoiceByValue(target);
            } else {
              sel.value = target;
            }
            sel.dispatchEvent(new Event('change', { bubbles: true }));
            result.performed = true;
            result.kind = 'filter';
            result.detail = fbChoicesInst ? 'select-single-choices' : 'select-single';
            return result;
          }
        }
      }

      const buttonGroups = Array.from(document.querySelectorAll('.dashboardr-button-group'))
        .filter((el) => visible(el));
      if (buttonGroups.length > 0) {
        const buttons = Array.from(buttonGroups[0].querySelectorAll('.dashboardr-button-option'))
          .filter((btn) => !btn.disabled);
        if (buttons.length > 0) {
          const active = buttons.find((btn) => btn.classList.contains('active'));
          const target = buttons.find((btn) => btn !== active) || buttons[0];
          if (target && typeof target.click === 'function') {
            target.click();
            result.performed = true;
            result.kind = 'filter';
            result.detail = 'button-group';
            return result;
          }
        }
      }

      const switches = Array.from(document.querySelectorAll('input[data-input-type="switch"]'))
        .filter((el) => !el.disabled && visible(el));
      if (switches.length > 0) {
        if (clickInputOrLabel(switches[0])) {
          result.performed = true;
          result.kind = 'filter';
          result.detail = 'switch';
          return result;
        }
      }

      const textInputs = Array.from(document.querySelectorAll('input[data-filter-var]'))
        .filter((el) => !el.disabled && visible(el));
      for (const input of textInputs) {
        const type = String(input.type || '').toLowerCase();
        if (type === 'text' || type === 'search') {
          input.value = String(input.value || '') + 'x';
          input.dispatchEvent(new Event('input', { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
          result.performed = true;
          result.kind = 'filter';
          result.detail = 'text';
          return result;
        }
        if (type === 'number') {
          const currentNum = Number(input.value);
          const minVal = Number(input.min);
          const maxVal = Number(input.max);
          let next = Number.isFinite(currentNum) ? currentNum + 1 : (Number.isFinite(minVal) ? minVal : 1);
          if (Number.isFinite(maxVal) && next > maxVal) next = Number.isFinite(minVal) ? minVal : maxVal;
          input.value = String(next);
          input.dispatchEvent(new Event('input', { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
          result.performed = true;
          result.kind = 'filter';
          result.detail = 'number';
          return result;
        }
      }

      return result;
    }, preferredFilterVar);

    await wait(1500);
    const after = await captureChartState();
    const dynamicTextAfter = await captureDynamicTextSnapshot();
    const dynamicTitleAfter = await captureDynamicTitleSnapshot();
    const changed = signatureForExpected(before) !== signatureForExpected(after);
    return {
      action,
      before,
      after,
      changed,
      dynamic_text: buildDynamicTextResult(dynamicTextBefore, dynamicTextAfter),
      dynamic_title: buildDynamicTitleResult(dynamicTitleBefore, dynamicTitleAfter)
    };
  };

  const performSliderInteraction = async () => {
    const dynamicTextBefore = await captureDynamicTextSnapshot();
    const dynamicTitleBefore = await captureDynamicTitleSnapshot();

    const before = await captureChartState();
    const action = await page.evaluate((preferredSliderVarArg) => {
      const result = { performed: false, detail: null, before: null, after: null, filter_var: null };
      const preferredSliderVar = (preferredSliderVarArg || '').trim();
      const visible = (el) => {
        if (!el) return false;
        const st = window.getComputedStyle(el);
        if (!st || st.display === 'none' || st.visibility === 'hidden') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
      };

      const sliders = Array.from(document.querySelectorAll('input[type="range"], .dashboardr-slider'))
        .filter((el) => {
          const isInputRange = el.tagName && el.tagName.toLowerCase() === 'input' && String(el.type).toLowerCase() === 'range';
          return isInputRange && !el.disabled && visible(el);
        });

      if (!sliders.length) {
        result.detail = 'no-slider';
        return result;
      }

      let slider = sliders[0];
      if (preferredSliderVar) {
        const preferred = sliders.find((el) => String(el.getAttribute('data-filter-var') || '') === preferredSliderVar);
        if (preferred) slider = preferred;
      }

      const min = Number(slider.min);
      const max = Number(slider.max);
      const current = Number(slider.value);
      const stepRaw = Number(slider.step);
      const step = Number.isFinite(stepRaw) && stepRaw > 0 ? stepRaw : 1;
      if (!Number.isFinite(min) || !Number.isFinite(max) || !Number.isFinite(current) || max <= min) {
        result.detail = 'invalid-slider-range';
        return result;
      }

      let candidate = current + step;
      if (candidate > max) candidate = current - step;
      if (candidate < min) candidate = min;
      if (Math.abs(candidate - current) < 1e-9) {
        candidate = Math.abs(current - min) < 1e-9 ? max : min;
      }
      if (!Number.isFinite(candidate) || Math.abs(candidate - current) < 1e-9) {
        result.detail = 'slider-no-alt-value';
        return result;
      }

      result.before = String(slider.value);
      slider.value = String(candidate);
      slider.dispatchEvent(new Event('input', { bubbles: true }));
      slider.dispatchEvent(new Event('change', { bubbles: true }));
      result.after = String(slider.value);
      result.filter_var = slider.getAttribute('data-filter-var') || null;
      result.performed = true;
      result.detail = 'slider-changed';
      return result;
    }, preferredSliderVar);

    await wait(1500);
    const after = await captureChartState();
    const dynamicTextAfter = await captureDynamicTextSnapshot();
    const dynamicTitleAfter = await captureDynamicTitleSnapshot();

    const changed = signatureForExpected(before) !== signatureForExpected(after);
    return {
      action,
      before,
      after,
      changed,
      dynamic_text: buildDynamicTextResult(dynamicTextBefore, dynamicTextAfter),
      dynamic_title: buildDynamicTitleResult(dynamicTitleBefore, dynamicTitleAfter)
    };
  };

  const collectVisibleFilterVars = async () => {
    return await page.evaluate(() => {
      const visible = (el) => {
        if (!el) return false;
        const st = window.getComputedStyle(el);
        if (!st || st.display === 'none' || st.visibility === 'hidden') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
      };
      const controlVisible = (el) => {
        if (!el) return false;
        if (visible(el)) return true;
        const tag = String(el.tagName || '').toLowerCase();
        if (tag === 'select') {
          const group = el.closest('.dashboardr-input-group');
          if (group && visible(group)) return true;
          const choices = group ? group.querySelector('.choices') : null;
          if (choices && visible(choices)) return true;
        }
        return false;
      };

      const nodes = Array.from(document.querySelectorAll('[data-filter-var]'));
      const vars = new Set();
      nodes.forEach((el) => {
        if (!controlVisible(el)) return;
        const val = String(el.getAttribute('data-filter-var') || '').trim();
        if (val) vars.add(val);
      });
      return Array.from(vars);
    });
  };

  const performFilterVarInteraction = async (filterVar) => {
    const dynamicTextBefore = await captureDynamicTextSnapshot();
    const dynamicTitleBefore = await captureDynamicTitleSnapshot();

    const before = await captureChartState();
    const action = await page.evaluate((targetVar) => {
      const result = {
        performed: false,
        detail: null,
        kind: null,
        filter_var: targetVar
      };
      const filterVar = String(targetVar || '').trim();
      if (!filterVar) {
        result.detail = 'missing-filter-var';
        return result;
      }

      const visible = (el) => {
        if (!el) return false;
        const st = window.getComputedStyle(el);
        if (!st || st.display === 'none' || st.visibility === 'hidden') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
      };

      const clickInputOrLabel = (input) => {
        if (!input) return false;
        const label = input.closest('label');
        if (label && typeof label.click === 'function') {
          label.click();
          return true;
        }
        if (typeof input.click === 'function') {
          input.click();
          return true;
        }
        return false;
      };

      const pickDifferent = (vals, current) => {
        if (!Array.isArray(vals)) return null;
        for (const v of vals) {
          if (String(v) !== String(current)) return String(v);
        }
        return null;
      };

      const slider = Array.from(document.querySelectorAll('input[type="range"][data-filter-var], .dashboardr-slider[data-filter-var]'))
        .find((el) => !el.disabled && visible(el) && String(el.getAttribute('data-filter-var') || '') === filterVar);
      if (slider) {
        const min = Number(slider.min);
        const max = Number(slider.max);
        const current = Number(slider.value);
        const stepRaw = Number(slider.step);
        const step = Number.isFinite(stepRaw) && stepRaw > 0 ? stepRaw : 1;
        if (Number.isFinite(min) && Number.isFinite(max) && Number.isFinite(current) && max > min) {
          let candidate = current + step;
          if (candidate > max) candidate = current - step;
          if (candidate < min) candidate = min;
          if (Math.abs(candidate - current) < 1e-9) {
            candidate = Math.abs(current - min) < 1e-9 ? max : min;
          }
          if (Number.isFinite(candidate) && Math.abs(candidate - current) > 1e-9) {
            slider.value = String(candidate);
            slider.dispatchEvent(new Event('input', { bubbles: true }));
            slider.dispatchEvent(new Event('change', { bubbles: true }));
            result.performed = true;
            result.kind = 'slider';
            result.detail = 'slider-var-changed';
            return result;
          }
        }
      }

      const checkboxGroup = Array.from(document.querySelectorAll('.dashboardr-checkbox-group'))
        .find((el) => visible(el) && String(el.getAttribute('data-filter-var') || '') === filterVar);
      if (checkboxGroup) {
        const inputs = Array.from(checkboxGroup.querySelectorAll('input[type="checkbox"]')).filter((el) => !el.disabled);
        const checked = inputs.filter((el) => el.checked);
        let target = null;
        if (checked.length > 1) {
          target = checked[0];
        } else if (checked.length === 1) {
          target = inputs.find((el) => !el.checked) || checked[0];
        } else if (inputs.length) {
          target = inputs[0];
        }
        if (target && clickInputOrLabel(target)) {
          result.performed = true;
          result.kind = 'checkbox';
          result.detail = 'checkbox-var-changed';
          return result;
        }
      }

      const radioGroup = Array.from(document.querySelectorAll('.dashboardr-radio-group'))
        .find((el) => visible(el) && String(el.getAttribute('data-filter-var') || '') === filterVar);
      if (radioGroup) {
        const radios = Array.from(radioGroup.querySelectorAll('input[type="radio"]')).filter((r) => !r.disabled);
        if (radios.length > 1) {
          const current = radios.find((r) => r.checked);
          const candidate = radios.find((r) => !r.checked) || radios[0];
          if (candidate && candidate !== current && clickInputOrLabel(candidate)) {
            result.performed = true;
            result.kind = 'radio';
            result.detail = 'radio-var-changed';
            return result;
          }
        }
      }

      const select = Array.from(document.querySelectorAll('select.dashboardr-input, select[data-filter-var]'))
        .find((el) => {
          if (el.disabled) return false;
          if (String(el.getAttribute('data-filter-var') || '') !== filterVar) return false;
          if (visible(el)) return true;
          const group = el.closest('.dashboardr-input-group');
          if (group && visible(group)) return true;
          const choices = group ? group.querySelector('.choices') : null;
          return !!(choices && visible(choices));
        });
      if (select) {
        // Choices.js-aware option discovery (Choices.js reduces select.options to 1)
        const inputId = select.id || '';
        const choicesInst = inputId && window.dashboardrChoicesInstances && window.dashboardrChoicesInstances[inputId];
        let allValues = [];
        let currentValue = select.value;
        if (choicesInst) {
          const storeChoices = (choicesInst._store && Array.isArray(choicesInst._store.choices))
            ? choicesInst._store.choices
            : (choicesInst._store && choicesInst._store.state && Array.isArray(choicesInst._store.state.choices))
              ? choicesInst._store.state.choices : null;
          if (storeChoices) {
            allValues = storeChoices.filter((c) => !c.disabled && String(c.value || '') !== '').map((c) => c.value);
            const active = storeChoices.filter((c) => c.selected);
            if (active.length > 0) currentValue = active[0].value;
          }
          if (!allValues.length && choicesInst.config && Array.isArray(choicesInst.config.choices)) {
            allValues = choicesInst.config.choices.filter((c) => !c.disabled && String(c.value || '') !== '').map((c) => c.value);
          }
          if (!allValues.length && choicesInst.choiceList && choicesInst.choiceList.element) {
            const items = choicesInst.choiceList.element.querySelectorAll('[data-choice][data-value]');
            allValues = Array.from(items).filter((it) => !it.classList.contains('is-disabled')).map((it) => it.getAttribute('data-value'));
          }
          if (typeof choicesInst.getValue === 'function') {
            const val = choicesInst.getValue(true);
            if (val !== undefined && val !== null) currentValue = Array.isArray(val) ? (val[0] || '') : val;
          }
        }
        // Fallback to native options
        if (!allValues.length) {
          allValues = Array.from(select.options || []).filter((o) => !o.disabled && o.value !== '').map((o) => o.value);
        }

        if (select.multiple && allValues.length > 1) {
          // For multi-select: toggle between all-selected and dropping one
          if (choicesInst && typeof choicesInst.removeActiveItems === 'function') {
            const selectedValues = (typeof choicesInst.getValue === 'function')
              ? [].concat(choicesInst.getValue(true) || [])
              : allValues;
            const applyValues = (vals) => {
              choicesInst.removeActiveItems();
              (vals || []).forEach((v) => {
                if (typeof choicesInst.setChoiceByValue === 'function') {
                  choicesInst.setChoiceByValue(v);
                }
              });
            };
            if (selectedValues.length >= allValues.length) {
              const dropVal = selectedValues[0] || allValues[0];
              if (typeof choicesInst.removeActiveItemsByValue === 'function' && dropVal !== undefined) {
                choicesInst.removeActiveItemsByValue(dropVal);
              } else {
                applyValues(allValues.filter((v) => String(v) !== String(dropVal)));
              }
              result.detail = 'select-multiple-var-drop-one-choices';
            } else {
              applyValues(allValues);
              result.detail = 'select-multiple-var-all-choices';
            }
          } else {
            const options = Array.from(select.options).filter((o) => !o.disabled && o.value !== '');
            const selectedCount = options.filter((o) => o.selected).length;
            if (selectedCount >= options.length) {
              options.forEach((o, i) => { o.selected = i < (options.length - 1); });
              result.detail = 'select-multiple-var-drop-one';
            } else {
              options.forEach((o) => { o.selected = true; });
              result.detail = 'select-multiple-var-all';
            }
          }
          select.dispatchEvent(new Event('change', { bubbles: true }));
          result.performed = true;
          result.kind = 'select-multiple';
          return result;
        }
        if (allValues.length > 1) {
          const target = pickDifferent(allValues, currentValue);
          if (target !== null) {
            if (choicesInst && typeof choicesInst.setChoiceByValue === 'function') {
              choicesInst.setChoiceByValue(target);
              if (String(select.value) !== String(target)) {
                select.value = target;
              }
            } else {
              select.value = target;
            }
            select.dispatchEvent(new Event('input', { bubbles: true }));
            select.dispatchEvent(new Event('change', { bubbles: true }));
            result.performed = true;
            result.kind = 'select-single';
            result.detail = choicesInst ? 'select-single-var-changed-choices' : 'select-single-var-changed';
            return result;
          }
        }
      }

      const buttonGroup = Array.from(document.querySelectorAll('.dashboardr-button-group'))
        .find((el) => visible(el) && String(el.getAttribute('data-filter-var') || '') === filterVar);
      if (buttonGroup) {
        const buttons = Array.from(buttonGroup.querySelectorAll('.dashboardr-button-option')).filter((btn) => !btn.disabled);
        if (buttons.length > 0) {
          const active = buttons.find((btn) => btn.classList.contains('active'));
          const target = buttons.find((btn) => btn !== active) || buttons[0];
          if (target && typeof target.click === 'function') {
            target.click();
            result.performed = true;
            result.kind = 'button_group';
            result.detail = 'button-group-var-changed';
            return result;
          }
        }
      }

      const sw = Array.from(document.querySelectorAll('input[data-input-type="switch"]'))
        .find((el) => !el.disabled && visible(el) && String(el.getAttribute('data-filter-var') || '') === filterVar);
      if (sw) {
        if (clickInputOrLabel(sw)) {
          result.performed = true;
          result.kind = 'switch';
          result.detail = 'switch-var-changed';
          return result;
        }
      }

      const textInput = Array.from(document.querySelectorAll('input[data-filter-var]'))
        .find((el) => !el.disabled && visible(el) && String(el.getAttribute('data-filter-var') || '') === filterVar);
      if (textInput) {
        const type = String(textInput.type || '').toLowerCase();
        const collectCrossTabValues = () => {
          const out = [];
          const registry = (window.dashboardrCrossTab && typeof window.dashboardrCrossTab === 'object')
            ? window.dashboardrCrossTab
            : {};
          Object.keys(registry).forEach((key) => {
            const entry = registry[key] || {};
            const rows = Array.isArray(entry.data) ? entry.data : [];
            rows.forEach((row) => {
              if (!row || typeof row !== 'object') return;
              if (!Object.prototype.hasOwnProperty.call(row, filterVar)) return;
              const val = String(row[filterVar] == null ? '' : row[filterVar]).trim();
              if (val) out.push(val);
            });
          });
          return Array.from(new Set(out));
        };
        if (type === 'text' || type === 'search') {
          const options = collectCrossTabValues();
          const current = String(textInput.value || '').trim();
          const next = pickDifferent(options, current) || (current ? '' : String(textInput.placeholder || '').trim() || 'x');
          textInput.value = next;
          textInput.dispatchEvent(new Event('input', { bubbles: true }));
          textInput.dispatchEvent(new Event('change', { bubbles: true }));
          result.performed = true;
          result.kind = 'text';
          result.detail = 'text-var-changed';
          return result;
        }
        if (type === 'number') {
          const currentNum = Number(textInput.value);
          const minVal = Number(textInput.min);
          const maxVal = Number(textInput.max);
          const valueOptions = collectCrossTabValues()
            .map((x) => Number(x))
            .filter((x) => Number.isFinite(x));
          let next = Number.isFinite(currentNum) ? currentNum + 1 : (Number.isFinite(minVal) ? minVal : 1);
          if (valueOptions.length > 1) {
            const currentText = Number.isFinite(currentNum) ? String(currentNum) : String(textInput.value || '');
            const pick = pickDifferent(valueOptions.map((x) => String(x)), currentText);
            if (pick !== null) next = Number(pick);
          }
          if (Number.isFinite(maxVal) && next > maxVal) next = Number.isFinite(minVal) ? minVal : maxVal;
          if (Number.isFinite(minVal) && next < minVal) next = minVal;
          if (Number.isFinite(currentNum) && Math.abs(next - currentNum) < 1e-9) {
            next = Number.isFinite(maxVal) && maxVal !== currentNum
              ? maxVal
              : (Number.isFinite(minVal) ? minVal : currentNum + 1);
          }
          textInput.value = String(next);
          textInput.dispatchEvent(new Event('input', { bubbles: true }));
          textInput.dispatchEvent(new Event('change', { bubbles: true }));
          result.performed = true;
          result.kind = 'number';
          result.detail = 'number-var-changed';
          return result;
        }
      }

      result.detail = 'unsupported-or-locked';
      return result;
    }, filterVar);

    await wait(1500);
    const after = await captureChartState();
    const dynamicTextAfter = await captureDynamicTextSnapshot();
    const dynamicTitleAfter = await captureDynamicTitleSnapshot();

    const changed = signatureForExpected(before) !== signatureForExpected(after);
    const comparison = compareExpectedBackendEntryChanges(before, after);

    return {
      action,
      before,
      after,
      changed,
      backend_change: comparison,
      dynamic_text: buildDynamicTextResult(dynamicTextBefore, dynamicTextAfter),
      dynamic_title: buildDynamicTitleResult(dynamicTitleBefore, dynamicTitleAfter)
    };
  };

  const validateAllInputVarsAffectAllCharts = async () => {
    const vars = await collectVisibleFilterVars();
    const checks = [];
    const maxAttemptsPerVar = 3;

    for (const filterVar of vars) {
      let result = null;
      let passed = false;
      let attempts = 0;

      for (let i = 0; i < maxAttemptsPerVar; i += 1) {
        attempts += 1;
        result = await performFilterVarInteraction(filterVar);
        if (result && result.action && result.action.performed &&
            result.backend_change && result.backend_change.ok) {
          passed = true;
          break;
        }
      }

      checks.push({
        filter_var: filterVar,
        attempts,
        action: result ? result.action : null,
        changed: !!(result && result.changed),
        backend_change: result ? result.backend_change : null
      });

      if (!result || !result.action || !result.action.performed) {
        fail(`Input '${filterVar}' could not be interacted with for propagation validation.`);
        continue;
      }

      if (!passed) {
        const summary = formatBackendChangeSummary(result.backend_change);
        fail(`Input '${filterVar}' did not affect all chart widgets (${summary}).`);
      }
    }

    return checks;
  };

  const performLinkedInputsInteraction = async () => {
    const result = await page.evaluate(() => {
      const out = { performed: false, changed: false, detail: null };
      const wrappers = Array.from(document.querySelectorAll('[data-linked-child-id]'));
      if (!wrappers.length) {
        out.detail = 'no-linked-wrapper';
        return out;
      }

      for (const wrapper of wrappers) {
        const childId = wrapper.getAttribute('data-linked-child-id');
        const child = childId ? document.getElementById(childId) : null;
        const parent = wrapper.querySelector('select.dashboardr-input, select[id]');
        if (!child || !parent) {
          continue;
        }

        // Choices.js-aware option discovery for linked parent
        const parentId = parent.id || '';
        const parentChoicesInst = parentId && window.dashboardrChoicesInstances && window.dashboardrChoicesInstances[parentId];
        let allParentValues = [];
        let parentCurrent = parent.value;
        if (parentChoicesInst) {
          const storeChoices = (parentChoicesInst._store && Array.isArray(parentChoicesInst._store.choices))
            ? parentChoicesInst._store.choices
            : (parentChoicesInst._store && parentChoicesInst._store.state && Array.isArray(parentChoicesInst._store.state.choices))
              ? parentChoicesInst._store.state.choices : null;
          if (storeChoices) {
            allParentValues = storeChoices.filter((c) => !c.disabled && String(c.value || '') !== '').map((c) => c.value);
            const active = storeChoices.filter((c) => c.selected);
            if (active.length > 0) parentCurrent = active[0].value;
          }
          if (!allParentValues.length && parentChoicesInst.config && Array.isArray(parentChoicesInst.config.choices)) {
            allParentValues = parentChoicesInst.config.choices.filter((c) => !c.disabled && String(c.value || '') !== '').map((c) => c.value);
          }
          if (typeof parentChoicesInst.getValue === 'function') {
            const val = parentChoicesInst.getValue(true);
            if (val !== undefined && val !== null) parentCurrent = Array.isArray(val) ? (val[0] || '') : val;
          }
        }
        // Fallback to native options
        if (!allParentValues.length) {
          allParentValues = Array.from(parent.options || []).filter((o) => !o.disabled && o.value !== '').map((o) => o.value);
        }
        // Fallback to data-options-by-parent mapping
        if (allParentValues.length < 2) {
          const mappingRaw = wrapper.getAttribute('data-options-by-parent');
          if (mappingRaw) {
            try {
              const mapping = JSON.parse(mappingRaw);
              const keys = Object.keys(mapping || {});
              if (keys.length > allParentValues.length) allParentValues = keys;
            } catch (_) {}
          }
        }
        if (allParentValues.length < 2) {
          continue;
        }

        // Discover child options similarly
        const childChoicesInst = child.id && window.dashboardrChoicesInstances && window.dashboardrChoicesInstances[child.id];
        let childBefore = [];
        if (childChoicesInst) {
          const childStore = (childChoicesInst._store && Array.isArray(childChoicesInst._store.choices))
            ? childChoicesInst._store.choices
            : (childChoicesInst._store && childChoicesInst._store.state && Array.isArray(childChoicesInst._store.state.choices))
              ? childChoicesInst._store.state.choices : null;
          if (childStore) childBefore = childStore.filter((c) => String(c.value || '') !== '').map((c) => c.value);
        }
        if (!childBefore.length) {
          childBefore = Array.from(child.options || []).filter((o) => o.value !== '').map((o) => o.value);
        }
        const before = childBefore.join('|');

        const targetValue = allParentValues.find((v) => String(v) !== String(parentCurrent)) || allParentValues[0];
        if (parentChoicesInst && typeof parentChoicesInst.setChoiceByValue === 'function') {
          parentChoicesInst.setChoiceByValue(targetValue);
          if (String(parent.value) !== String(targetValue)) parent.value = targetValue;
        } else {
          parent.value = targetValue;
        }
        parent.dispatchEvent(new Event('input', { bubbles: true }));
        parent.dispatchEvent(new Event('change', { bubbles: true }));

        out.performed = true;
        out.detail = 'parent-changed';
        out.before = before;
        out.child_id = childId;
        return out;
      }
      out.detail = 'insufficient-parent-options';
      return out;
    });

    await wait(1000);

    const after = await page.evaluate((childIdArg) => {
      const childId = childIdArg;
      if (!childId) return null;
      const child = childId ? document.getElementById(childId) : null;
      if (!child) return null;
      // Choices.js-aware child option reading
      const childChoicesInst = child.id && window.dashboardrChoicesInstances && window.dashboardrChoicesInstances[child.id];
      if (childChoicesInst) {
        const childStore = (childChoicesInst._store && Array.isArray(childChoicesInst._store.choices))
          ? childChoicesInst._store.choices
          : (childChoicesInst._store && childChoicesInst._store.state && Array.isArray(childChoicesInst._store.state.choices))
            ? childChoicesInst._store.state.choices : null;
        if (childStore) {
          return childStore.filter((c) => String(c.value || '') !== '').map((c) => c.value).join('|');
        }
      }
      return Array.from(child.options || []).map((o) => o.value).join('|');
    }, result.child_id || null);

    if (result && result.performed) {
      result.after = after;
      result.changed = String(result.before || '') !== String(after || '');
    }

    return result;
  };

  const performTabClickInteraction = async () => {
    const beforeActive = await page.evaluate(() => {
      const active = document.querySelector('.panel-tabset .nav-link.active, .nav-tabs .nav-link.active');
      return active ? (active.textContent || '').trim() : null;
    });

    const tab = page.locator('.panel-tabset .nav-link:not(.active), .nav-tabs .nav-link:not(.active)').first();
    const count = await tab.count();
    if (!count) {
      return { performed: false, changed: false, detail: 'no-secondary-tab' };
    }

    await tab.click();
    await wait(700);

    const afterActive = await page.evaluate(() => {
      const active = document.querySelector('.panel-tabset .nav-link.active, .nav-tabs .nav-link.active');
      return active ? (active.textContent || '').trim() : null;
    });

    return {
      performed: true,
      changed: String(beforeActive || '') !== String(afterActive || ''),
      before: beforeActive,
      after: afterActive,
      detail: 'tab-click'
    };
  };

  const performSidebarToggleInteraction = async () => {
    const toggle = page.locator('.collapse-toggle, [aria-controls^="bslib-sidebar-"]').first();
    const count = await toggle.count();
    if (!count) {
      return { performed: false, changed: false, detail: 'no-sidebar-toggle' };
    }

    const before = await toggle.getAttribute('aria-expanded');
    await toggle.click();
    await wait(500);
    const middle = await toggle.getAttribute('aria-expanded');
    await toggle.click();
    await wait(500);
    const after = await toggle.getAttribute('aria-expanded');

    return {
      performed: true,
      changed: String(before || '') !== String(middle || '') || String(middle || '') !== String(after || ''),
      detail: 'sidebar-toggle',
      before,
      middle,
      after
    };
  };

  const performModalInteraction = async () => {
    const before = await captureModalState();
    const trigger = page.locator('.modal-link, .modal-trigger, [data-bs-toggle="modal"]').first();
    const triggerCount = await trigger.count();
    if (!triggerCount) {
      return { performed: false, changed: false, detail: 'no-modal-trigger', before, after: before };
    }

    await trigger.click();
    await wait(500);
    const opened = await captureModalState();

    if ((opened.active_count || 0) <= 0) {
      return { performed: true, changed: false, detail: 'modal-did-not-open', before, after: opened };
    }

    await page.keyboard.press('Escape').catch(() => {});
    await wait(350);
    let after = await captureModalState();
    let closeDetail = 'closed-with-escape';

    if ((after.active_count || 0) > 0) {
      const closeBtn = page.locator('#dashboardr-modal-close, .dashboardr-modal-close, .modal-close, .btn-close, [data-bs-dismiss="modal"], [aria-label="Close"], [aria-label="Close modal"]').first();
      if (await closeBtn.count()) {
        await closeBtn.click({ force: true }).catch(() => {});
        await wait(350);
      }
      after = await captureModalState();
      closeDetail = 'closed-with-button';
    }

    const closed = (after.active_count || 0) === 0;
    return {
      performed: true,
      changed: closed,
      detail: closed ? closeDetail : 'modal-still-open',
      before,
      opened,
      after
    };
  };

  const performTooltipInteraction = async () => {
    const before = await captureTooltipSnapshot();
    const action = await page.evaluate((expectedBackendsArg) => {
      const expected = Array.isArray(expectedBackendsArg)
        ? expectedBackendsArg.map((x) => String(x || '').trim()).filter((x) => x.length > 0)
        : [];
      const wants = (backend) => expected.length === 0 || expected.includes(backend);

      // Plotly: use Fx.hover on first available trace/point
      if (wants('plotly') && typeof Plotly !== 'undefined' && Plotly.Fx && typeof Plotly.Fx.hover === 'function') {
        const plotDivs = Array.from(document.querySelectorAll('.js-plotly-plot'));
        for (let i = 0; i < plotDivs.length; i += 1) {
          const div = plotDivs[i];
          const data = Array.isArray(div && div.data) ? div.data : [];
          for (let c = 0; c < data.length; c += 1) {
            const tr = data[c] || {};
            const len = Array.isArray(tr.y) ? tr.y.length : (Array.isArray(tr.values) ? tr.values.length : 0);
            if (len > 0) {
              Plotly.Fx.hover(div, [{ curveNumber: c, pointNumber: 0 }]);
              const hasHoverData = !!(div._hoverdata && Array.isArray(div._hoverdata) && div._hoverdata.length > 0);
              const hasHoverLayer = document.querySelectorAll('.hoverlayer .hovertext').length > 0;
              const isPie = String(tr.type || '').toLowerCase() === 'pie';
              const hasPieData = Array.isArray(tr.values) ? tr.values.length > 0 : (Array.isArray(tr.labels) ? tr.labels.length > 0 : false);
              const signal = hasHoverData || hasHoverLayer || (isPie && hasPieData);
              return { performed: true, detail: 'plotly-fx-hover', signal };
            }
          }
        }
      }

      // Highcharts: refresh tooltip with first point
      if (wants('highcharter') && typeof Highcharts !== 'undefined' && Array.isArray(Highcharts.charts)) {
        const charts = Highcharts.charts.filter((c) => !!c && Array.isArray(c.series));
        for (let i = 0; i < charts.length; i += 1) {
          const chart = charts[i];
          for (let s = 0; s < chart.series.length; s += 1) {
            const series = chart.series[s];
            const pts = Array.isArray(series && series.points) ? series.points.filter((p) => p && p.y != null) : [];
            if (pts.length > 0 && chart.tooltip && typeof chart.tooltip.refresh === 'function') {
              chart.tooltip.refresh(pts[0]);
              const signal = !!(chart.tooltip && chart.tooltip.isHidden === false);
              return { performed: true, detail: 'highcharts-tooltip-refresh', signal };
            }
          }
        }
      }

      // ECharts: dispatch showTip on first series/dataIndex
      if (wants('echarts4r') && typeof echarts !== 'undefined') {
        const nodes = Array.from(document.querySelectorAll('[_echarts_instance_], .echarts, .echarts4r'));
        for (let i = 0; i < nodes.length; i += 1) {
          const el = nodes[i];
          const inst = echarts.getInstanceByDom(el);
          if (!inst || typeof inst.getOption !== 'function' || typeof inst.dispatchAction !== 'function') continue;
          const opt = inst.getOption() || {};
          const series = Array.isArray(opt.series) ? opt.series : [];
          for (let s = 0; s < series.length; s += 1) {
            const sd = series[s] && Array.isArray(series[s].data) ? series[s].data : [];
            if (sd.length > 0) {
              inst.dispatchAction({ type: 'showTip', seriesIndex: s, dataIndex: 0 });
              return { performed: true, detail: 'echarts-showTip', signal: true };
            }
          }
        }
      }

      return { performed: false, detail: 'no-tooltip-capable-chart' };
    }, expectedBackends);

    if (!action || !action.performed) {
      return {
        performed: false,
        changed: false,
        detail: action && action.detail ? action.detail : 'tooltip-action-failed',
        before,
        after: before
      };
    }

    await wait(400);
    const after = await captureTooltipSnapshot();
    return {
      performed: true,
      changed: String(before.text || '') !== String(after.text || '') || Number(after.count || 0) > 0 || !!action.signal,
      detail: action.detail || 'tooltip-hover',
      before,
      after,
      has_undefined: !!after.has_undefined,
      signal: !!action.signal
    };
  };

  const performShowWhenInteraction = async () => {
    const dynamicTextBefore = await captureDynamicTextSnapshot();
    const dynamicTitleBefore = await captureDynamicTitleSnapshot();
    const beforeState = await page.evaluate(() => {
      const nodes = Array.from(document.querySelectorAll('[data-show-when]'));
      if (!nodes.length) return null;
      const visible = nodes.filter((el) => {
        const st = window.getComputedStyle(el);
        if (!st || st.display === 'none' || st.visibility === 'hidden') return false;
        return !el.classList.contains('dashboardr-sw-hidden');
      });
      const signature = visible.map((el) => {
        const attr = el.getAttribute('data-show-when') || '';
        const id = el.id || '';
        return `${id}::${attr}`;
      }).join('|');
      return { count: visible.length, signature };
    });

    if (beforeState === null) {
      return { performed: false, changed: false, detail: 'no-show-when-elements' };
    }

    const action = await page.evaluate(() => {
      const out = { performed: false, detail: null };

      const flattenVars = (cond, set) => {
        if (!cond || typeof cond !== 'object') return;
        if (cond.var) set.add(String(cond.var).trim());
        if (Array.isArray(cond.conditions)) cond.conditions.forEach((x) => flattenVars(x, set));
        if (cond.condition) flattenVars(cond.condition, set);
      };

      const collectVarHints = (cond, out) => {
        if (!cond || typeof cond !== 'object') return;
        const op = String(cond.op || '').toLowerCase();
        const key = cond.var ? String(cond.var).trim() : '';
        if (key) {
          if (!Array.isArray(out[key])) out[key] = [];
          if ((op === 'eq' || op === 'neq') && cond.val != null && !Array.isArray(cond.val)) {
            const val = String(cond.val);
            if (val && !out[key].includes(val)) out[key].push(val);
          } else if (op === 'in' && Array.isArray(cond.val)) {
            cond.val.forEach((entry) => {
              const val = String(entry == null ? '' : entry);
              if (val && !out[key].includes(val)) out[key].push(val);
            });
          }
        }
        if (Array.isArray(cond.conditions)) cond.conditions.forEach((x) => collectVarHints(x, out));
        if (cond.condition) collectVarHints(cond.condition, out);
      };

      const pickTargetValue = (filterVar, allValues, currentValue, varHints) => {
        const values = Array.from(new Set((allValues || []).map((x) => String(x == null ? '' : x)).filter((x) => x)));
        if (!values.length) return null;
        const current = String(currentValue == null ? '' : currentValue);
        const hints = Array.isArray(varHints[filterVar]) ? varHints[filterVar].map((x) => String(x)) : [];
        for (const hint of hints) {
          if (hint !== current && values.includes(hint)) return hint;
        }
        return values.find((v) => v !== current) || values[0];
      };

      const triggerInputOrLabel = (input) => {
        if (!input) return false;
        const label = input.closest('label');
        if (label && typeof label.click === 'function') {
          label.click();
          return true;
        }
        if (typeof input.click === 'function') {
          input.click();
          return true;
        }
        return false;
      };

      const varHints = {};

      const changeForVar = (varName) => {
        const filterVar = String(varName || '').trim();
        if (!filterVar) return false;

        const select = document.querySelector(`select[data-filter-var="${filterVar}"]`);
        if (select) {
          const inputId = select.id || '';
          const choicesInst = inputId && window.dashboardrChoicesInstances && window.dashboardrChoicesInstances[inputId];

          // Choices.js may reduce select.options to only the selected item(s).
          // Use multiple strategies to get all available choices.
          let allValues = [];
          let currentValue = select.value;
          if (choicesInst) {
            // Strategy 1: _store.choices (Choices.js v10+)
            const storeChoices = (choicesInst._store && Array.isArray(choicesInst._store.choices))
              ? choicesInst._store.choices
              : (choicesInst._store && choicesInst._store.state && Array.isArray(choicesInst._store.state.choices))
                ? choicesInst._store.state.choices
                : null;
            if (storeChoices) {
              allValues = storeChoices.filter((c) => !c.disabled && String(c.value || '') !== '').map((c) => c.value);
              const active = storeChoices.filter((c) => c.selected);
              if (active.length > 0) currentValue = active[0].value;
            }
            // Strategy 2: _presetChoices from config
            if (!allValues.length && choicesInst.config && Array.isArray(choicesInst.config.choices)) {
              allValues = choicesInst.config.choices.filter((c) => !c.disabled && String(c.value || '') !== '').map((c) => c.value);
            }
            // Strategy 3: query Choices.js rendered dropdown items
            if (!allValues.length && choicesInst.choiceList && choicesInst.choiceList.element) {
              const items = choicesInst.choiceList.element.querySelectorAll('[data-choice][data-value]');
              allValues = Array.from(items).filter((it) => !it.classList.contains('is-disabled')).map((it) => it.getAttribute('data-value'));
            }
            // Strategy 4: getValue for current value
            if (typeof choicesInst.getValue === 'function') {
              const val = choicesInst.getValue(true);
              if (val !== undefined && val !== null) currentValue = Array.isArray(val) ? (val[0] || '') : val;
            }
          }
          // Fallback to native options
          if (!allValues.length) {
            allValues = Array.from(select.options || []).filter((o) => !o.disabled && o.value !== '').map((o) => o.value);
          }

          if (allValues.length > 1) {
            const targetVal = pickTargetValue(filterVar, allValues, currentValue, varHints);
            if (!targetVal) return false;
            if (choicesInst && typeof choicesInst.setChoiceByValue === 'function') {
              if (select.multiple) {
                choicesInst.removeActiveItems();
                choicesInst.setChoiceByValue([targetVal]);
              } else {
                choicesInst.setChoiceByValue(targetVal);
              }
              // Ensure the native select value is updated (Choices.js may not sync immediately)
              if (String(select.value) !== String(targetVal)) {
                select.value = targetVal;
              }
            } else {
              select.value = targetVal;
            }
            select.dispatchEvent(new Event('input', { bubbles: true }));
            select.dispatchEvent(new Event('change', { bubbles: true }));
            return true;
          }
        }

        const radioGroup = document.querySelector(`.dashboardr-radio-group[data-filter-var="${filterVar}"]`);
        if (radioGroup) {
          const radios = Array.from(radioGroup.querySelectorAll('input[type="radio"]')).filter((r) => !r.disabled);
          if (radios.length > 1) {
            const currentRadio = radios.find((r) => r.checked);
            const targetValue = pickTargetValue(
              filterVar,
              radios.map((r) => r.value),
              currentRadio ? currentRadio.value : '',
              varHints
            );
            const candidate = radios.find((r) => String(r.value) === String(targetValue) && !r.checked) ||
              radios.find((r) => !r.checked) ||
              radios[0];
            if (candidate) return triggerInputOrLabel(candidate);
          }
        }

        const checkboxGroup = document.querySelector(`.dashboardr-checkbox-group[data-filter-var="${filterVar}"]`);
        if (checkboxGroup) {
          const inputs = Array.from(checkboxGroup.querySelectorAll('input[type="checkbox"]')).filter((x) => !x.disabled);
          const checked = inputs.filter((x) => x.checked);
          let target = null;
          if (checked.length > 1) {
            target = checked[0];
          } else if (checked.length === 1) {
            target = inputs.find((x) => !x.checked) || checked[0];
          } else if (inputs.length) {
            target = inputs[0];
          }
          if (target) return triggerInputOrLabel(target);
        }

        const buttonGroup = document.querySelector(`.dashboardr-button-group[data-filter-var="${filterVar}"]`);
        if (buttonGroup) {
          const buttons = Array.from(buttonGroup.querySelectorAll('.dashboardr-button-option')).filter((btn) => !btn.disabled);
          if (buttons.length > 0) {
            const active = buttons.find((btn) => btn.classList.contains('active'));
            const target = buttons.find((btn) => btn !== active) || buttons[0];
            if (target && typeof target.click === 'function') {
              target.click();
              return true;
            }
          }
        }

        const switchInput = document.querySelector(`input[data-input-type="switch"][data-filter-var="${filterVar}"]`);
        if (switchInput && !switchInput.disabled) {
          return triggerInputOrLabel(switchInput);
        }

        const slider = document.querySelector(`input[type="range"][data-filter-var="${filterVar}"]`);
        if (slider && !slider.disabled) {
          const min = Number(slider.min);
          const max = Number(slider.max);
          const current = Number(slider.value);
          const stepRaw = Number(slider.step);
          const step = Number.isFinite(stepRaw) && stepRaw > 0 ? stepRaw : 1;
          if (Number.isFinite(min) && Number.isFinite(max) && Number.isFinite(current) && max > min) {
            // Jump to the opposite bound to maximize chance of show_when state transitions.
            let target = Math.abs(current - min) < 1e-9 ? max : min;
            if (Math.abs(target - current) < 1e-9) {
              target = current + step;
              if (target > max) target = current - step;
              if (target < min) target = min;
            }
            if (Math.abs(target - current) > 1e-9) {
              slider.value = String(target);
              slider.dispatchEvent(new Event('input', { bubbles: true }));
              slider.dispatchEvent(new Event('change', { bubbles: true }));
              return true;
            }
          }
        }

        const textInput = document.querySelector(`input[data-filter-var="${filterVar}"]`);
        if (textInput && !textInput.disabled) {
          const type = String(textInput.type || '').toLowerCase();
          if (type === 'text' || type === 'search') {
            textInput.value = String(textInput.value || '') + 'x';
            textInput.dispatchEvent(new Event('input', { bubbles: true }));
            textInput.dispatchEvent(new Event('change', { bubbles: true }));
            return true;
          }
          if (type === 'number') {
            const current = Number(textInput.value);
            const min = Number(textInput.min);
            const max = Number(textInput.max);
            let next = Number.isFinite(current) ? current + 1 : (Number.isFinite(min) ? min : 1);
            if (Number.isFinite(max) && next > max) next = Number.isFinite(min) ? min : max;
            textInput.value = String(next);
            textInput.dispatchEvent(new Event('input', { bubbles: true }));
            textInput.dispatchEvent(new Event('change', { bubbles: true }));
            return true;
          }
        }

        return false;
      };

      const vars = new Set();
      document.querySelectorAll('[data-show-when]').forEach((el) => {
        try {
          const raw = el.getAttribute('data-show-when');
          if (!raw) return;
          const cond = JSON.parse(raw);
          flattenVars(cond, vars);
          collectVarHints(cond, varHints);
        } catch (_) {
          // ignore
        }
      });

      const orderedVars = Array.from(vars).filter((x) => !!x);
      for (const filterVar of orderedVars) {
        if (changeForVar(filterVar)) {
          out.performed = true;
          out.detail = `changed:${filterVar}`;
          return out;
        }
      }

      const fallbackVar = document.querySelector('[data-filter-var]')?.getAttribute('data-filter-var');
      if (fallbackVar && changeForVar(fallbackVar)) {
        out.performed = true;
        out.detail = `fallback:${fallbackVar}`;
        return out;
      }

      out.detail = 'no-compatible-input-for-show-when';
      return out;
    });

    await wait(900);

    const getVisibleShowWhenState = async () => {
      return await page.evaluate(() => {
        const nodes = Array.from(document.querySelectorAll('[data-show-when]'));
        const visible = nodes.filter((el) => {
          const st = window.getComputedStyle(el);
          if (!st || st.display === 'none' || st.visibility === 'hidden') return false;
          return !el.classList.contains('dashboardr-sw-hidden');
        });
        const signature = visible.map((el) => {
          const attr = el.getAttribute('data-show-when') || '';
          const id = el.id || '';
          return `${id}::${attr}`;
        }).join('|');
        return { count: visible.length, signature };
      });
    };

    const afterState = await getVisibleShowWhenState();
    const dynamicTextAfter = await captureDynamicTextSnapshot();
    const dynamicTitleAfter = await captureDynamicTitleSnapshot();
    const changed = String(beforeState.signature || '') !== String(afterState.signature || '') ||
      Number(beforeState.count) !== Number(afterState.count);

    return {
      performed: !!action.performed,
      changed,
      before: beforeState.count,
      after: afterState.count,
      before_signature: beforeState.signature,
      after_signature: afterState.signature,
      detail: action.detail,
      dynamic_text: buildDynamicTextResult(dynamicTextBefore, dynamicTextAfter),
      dynamic_title: buildDynamicTitleResult(dynamicTitleBefore, dynamicTitleAfter)
    };
  };

  const assertEducationBoxplotCoverage = async () => {
    const info = await page.evaluate(() => {
      const expected = ["High School", "Some College", "Bachelor's", "Graduate"];
      const found = [];
      let boxplotDetected = false;
      let plotlyBoxTraceCount = 0;
      let plotlyActiveBoxTraceCount = 0;
      let plotlyRawLikeCount = 0;

      const addLabel = (value) => {
        const txt = String(value == null ? '' : value).trim();
        if (txt) found.push(txt);
      };

      if (window.Highcharts && Array.isArray(window.Highcharts.charts)) {
        window.Highcharts.charts.filter((c) => !!c && !!c.series).forEach((chart) => {
          const hasBox = (chart.series || []).some((s) => String(s && s.type || '').toLowerCase() === 'boxplot');
          if (hasBox) {
            boxplotDetected = true;
            const cats = chart.xAxis && chart.xAxis[0] && Array.isArray(chart.xAxis[0].categories)
              ? chart.xAxis[0].categories
              : [];
            cats.forEach(addLabel);
          }
        });
      }

      document.querySelectorAll('.js-plotly-plot').forEach((div) => {
        const traces = Array.isArray(div.data) ? div.data : [];
        const boxTraces = traces.filter((t) => String(t && t.type || '').toLowerCase() === 'box');
        if (boxTraces.length) {
          boxplotDetected = true;
          boxTraces.forEach((trace) => {
            plotlyBoxTraceCount += 1;
            const visibility = String((trace && trace.visible) || '').toLowerCase();
            const traceVisible = visibility !== 'legendonly' && visibility !== 'false';
            const orientation = String(trace && trace.orientation || 'v').toLowerCase();
            const xVals = Array.isArray(trace && trace.x) ? trace.x : [];
            const yVals = Array.isArray(trace && trace.y) ? trace.y : [];
            const activeVals = orientation === 'h' ? xVals : yVals;
            if (traceVisible && activeVals.length > 0) {
              plotlyActiveBoxTraceCount += 1;
            }
            const numericCount = activeVals.filter((v) => Number.isFinite(Number(v))).length;
            if (traceVisible && activeVals.length > 0 && activeVals.length >= 5 && numericCount >= 3) {
              plotlyRawLikeCount += 1;
            }
            (Array.isArray(trace.x) ? trace.x : []).forEach(addLabel);
          });
          const xaxis = div.layout && div.layout.xaxis ? div.layout.xaxis : {};
          (Array.isArray(xaxis.ticktext) ? xaxis.ticktext : []).forEach(addLabel);
          (Array.isArray(xaxis.categoryarray) ? xaxis.categoryarray : []).forEach(addLabel);
        }
      });

      if (window.echarts && typeof window.echarts.getInstanceByDom === 'function') {
        document.querySelectorAll('.echarts4r, .echarts, .html-widget').forEach((el) => {
          const inst = window.echarts.getInstanceByDom(el);
          if (!inst) return;
          const option = inst.getOption ? inst.getOption() : {};
          const series = Array.isArray(option && option.series) ? option.series : [];
          const hasBox = series.some((s) => String(s && s.type || '').toLowerCase() === 'boxplot');
          if (!hasBox) return;
          boxplotDetected = true;
          const xAxis = Array.isArray(option && option.xAxis) ? option.xAxis[0] : option.xAxis;
          const categories = xAxis && Array.isArray(xAxis.data) ? xAxis.data : [];
          categories.forEach(addLabel);
        });
      }

      const uniqueLabels = Array.from(new Set(found.map((x) => String(x))));
      const matched = expected.filter((label) => uniqueLabels.includes(label));
      return {
        boxplot_detected: boxplotDetected,
        matched,
        unique_labels: uniqueLabels,
        plotly_box_trace_count: plotlyBoxTraceCount,
        plotly_active_box_trace_count: plotlyActiveBoxTraceCount,
        plotly_box_raw_like_count: plotlyRawLikeCount
      };
    });

    if (!info.boxplot_detected) {
      fail('Expected education boxplot checks, but no boxplot was detected.');
      return;
    }
    if (Number(info.plotly_active_box_trace_count || 0) > 0 &&
        Number(info.plotly_box_raw_like_count || 0) < Number(info.plotly_active_box_trace_count || 0)) {
      fail('Plotly boxplot appears malformed (traces are not backed by raw sample values).');
    }
    if (!Array.isArray(info.matched) || info.matched.length < 2) {
      const labels = Array.isArray(info.unique_labels) ? info.unique_labels.join(', ') : '';
      fail(`Education boxplot categories are missing/unclear (found: ${labels || 'none'}).`);
    }
  };

  const assertShowWhenConsistency = async (stage) => {
    const info = await page.evaluate(() => {
      const values = {};
      const choicesMap = window.dashboardrChoicesInstances || {};
      document.querySelectorAll('select').forEach((el) => {
        let val = el.value;
        const id = el.getAttribute('data-input-id') || el.name || el.id;
        if (id && choicesMap[id] && typeof choicesMap[id].getValue === 'function') {
          const choicesVal = choicesMap[id].getValue(true);
          if (choicesVal !== undefined && choicesVal !== null) {
            val = Array.isArray(choicesVal) ? (choicesVal[0] || '') : choicesVal;
          }
        } else if (el.id && choicesMap[el.id] && typeof choicesMap[el.id].getValue === 'function') {
          const choicesVal2 = choicesMap[el.id].getValue(true);
          if (choicesVal2 !== undefined && choicesVal2 !== null) {
            val = Array.isArray(choicesVal2) ? (choicesVal2[0] || '') : choicesVal2;
          }
        }
        const fv = el.getAttribute('data-filter-var') || (el.closest('[data-filter-var]') && el.closest('[data-filter-var]').getAttribute('data-filter-var'));
        if (fv) values[fv] = val;
      });
      document.querySelectorAll('input[type="radio"]:checked').forEach((el) => {
        const group = el.closest('[data-filter-var]');
        const fv = group && group.getAttribute('data-filter-var');
        if (fv) values[fv] = el.value;
      });
      document.querySelectorAll('.dashboardr-checkbox-group[data-filter-var]').forEach((group) => {
        const fv = group.getAttribute('data-filter-var');
        if (!fv) return;
        values[fv] = Array.from(group.querySelectorAll('input[type="checkbox"]:checked'))
          .map((el) => el.value)
          .filter((v) => String(v || '') !== '');
      });
      document.querySelectorAll('.dashboardr-button-group[data-filter-var]').forEach((group) => {
        const fv = group.getAttribute('data-filter-var');
        if (!fv) return;
        const active = group.querySelector('.dashboardr-button-option.active');
        if (active) {
          const activeVal = active.getAttribute('data-value') ?? active.value ?? active.textContent;
          if (activeVal != null) values[fv] = String(activeVal).trim();
        }
      });
      document.querySelectorAll('input[data-filter-var], textarea[data-filter-var]').forEach((el) => {
        const fv = el.getAttribute('data-filter-var');
        if (!fv) return;
        const type = String(el.type || '').toLowerCase();
        if (type === 'radio' || type === 'checkbox') return;
        values[fv] = el.value;
      });

      const evalCond = (cond) => {
        if (!cond || typeof cond !== 'object') return true;
        if (cond.op === 'and') return (cond.conditions || []).every((c) => evalCond(c));
        if (cond.op === 'or') return (cond.conditions || []).some((c) => evalCond(c));
        if (cond.op === 'not') return !evalCond(cond.condition);
        const val = values[cond.var];
        const numVal = parseFloat(val);
        const numCond = parseFloat(cond.val);
        const valueIsArray = Array.isArray(val);
        const condIsArray = Array.isArray(cond.val);
        switch (cond.op) {
          case 'eq':
            if (valueIsArray) return val.indexOf(cond.val) !== -1;
            return val === cond.val;
          case 'neq':
            if (valueIsArray) return val.indexOf(cond.val) === -1;
            return val !== cond.val;
          case 'in':
            if (valueIsArray && condIsArray) return val.some((v) => cond.val.indexOf(v) !== -1);
            if (condIsArray) return cond.val.indexOf(val) !== -1;
            return false;
          case 'gt':
            return !isNaN(numVal) && !isNaN(numCond) && numVal > numCond;
          case 'lt':
            return !isNaN(numVal) && !isNaN(numCond) && numVal < numCond;
          case 'gte':
            return !isNaN(numVal) && !isNaN(numCond) && numVal >= numCond;
          case 'lte':
            return !isNaN(numVal) && !isNaN(numCond) && numVal <= numCond;
          default:
            return true;
        }
      };

      const isActuallyVisible = (el) => {
        if (!el) return false;
        if (el.classList && el.classList.contains('dashboardr-sw-hidden')) return false;
        const st = window.getComputedStyle(el);
        if (!st || st.display === 'none' || st.visibility === 'hidden' || st.opacity === '0') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
      };

      const nodes = Array.from(document.querySelectorAll('[data-show-when]'));
      const mismatches = [];
      nodes.forEach((el, idx) => {
        const raw = el.getAttribute('data-show-when');
        if (!raw) return;
        let cond = null;
        try {
          cond = JSON.parse(raw);
        } catch (_) {
          return;
        }
        const expectedVisible = !!evalCond(cond);
        const actualVisible = isActuallyVisible(el);
        if (expectedVisible !== actualVisible) {
          const text = String(el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim();
          mismatches.push({
            index: idx + 1,
            id: el.id || '',
            expected_visible: expectedVisible,
            actual_visible: actualVisible,
            text: text.slice(0, 120),
            condition: raw
          });
        }
      });

      return {
        count: nodes.length,
        mismatch_count: mismatches.length,
        mismatches,
        values
      };
    });

    interactionResults.show_when_consistency = interactionResults.show_when_consistency || {};
    interactionResults.show_when_consistency[stage] = info;
    if (Number(info.mismatch_count || 0) > 0) {
      const first = (info.mismatches && info.mismatches[0]) || {};
      fail(
        `show_when mismatch (${stage}): expected=${first.expected_visible} actual=${first.actual_visible} ` +
        `id='${first.id || `#${first.index || 0}`}' cond='${first.condition || ''}'`
      );
    }
  };

  const assertDynamicBindings = async (stage) => {
    if (!dynamicBindingRules.length) return;
    const result = await page.evaluate((rules) => {
      const values = {};
      const choicesMap = window.dashboardrChoicesInstances || {};
      const normalize = (v) => String(v || '').replace(/\s+/g, ' ').trim().toLowerCase();
      const asTokens = (val) => {
        if (Array.isArray(val)) return val.map((x) => String(x || '').trim()).filter((x) => x.length > 0);
        const one = String(val || '').trim();
        return one ? [one] : [];
      };
      const isVisible = (el) => {
        if (!el) return false;
        if (el.classList && el.classList.contains('dashboardr-sw-hidden')) return false;
        const st = window.getComputedStyle(el);
        if (!st || st.display === 'none' || st.visibility === 'hidden' || st.opacity === '0') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
      };

      document.querySelectorAll('select').forEach((el) => {
        let val = el.value;
        const id = el.getAttribute('data-input-id') || el.name || el.id;
        if (id && choicesMap[id] && typeof choicesMap[id].getValue === 'function') {
          const choicesVal = choicesMap[id].getValue(true);
          if (choicesVal !== undefined && choicesVal !== null) {
            val = Array.isArray(choicesVal) ? (choicesVal[0] || '') : choicesVal;
          }
        } else if (el.id && choicesMap[el.id] && typeof choicesMap[el.id].getValue === 'function') {
          const choicesVal2 = choicesMap[el.id].getValue(true);
          if (choicesVal2 !== undefined && choicesVal2 !== null) {
            val = Array.isArray(choicesVal2) ? (choicesVal2[0] || '') : choicesVal2;
          }
        }
        const fv = el.getAttribute('data-filter-var') || (el.closest('[data-filter-var]') && el.closest('[data-filter-var]').getAttribute('data-filter-var'));
        if (fv) values[fv] = val;
      });
      document.querySelectorAll('input[type="radio"]:checked').forEach((el) => {
        const group = el.closest('[data-filter-var]');
        const fv = group && group.getAttribute('data-filter-var');
        if (fv) values[fv] = el.value;
      });
      document.querySelectorAll('.dashboardr-checkbox-group[data-filter-var]').forEach((group) => {
        const fv = group.getAttribute('data-filter-var');
        if (!fv) return;
        values[fv] = Array.from(group.querySelectorAll('input[type="checkbox"]:checked'))
          .map((el) => el.value)
          .filter((v) => String(v || '') !== '');
      });
      document.querySelectorAll('.dashboardr-button-group[data-filter-var]').forEach((group) => {
        const fv = group.getAttribute('data-filter-var');
        if (!fv) return;
        const active = group.querySelector('.dashboardr-button-option.active');
        if (active) {
          const activeVal = active.getAttribute('data-value') ?? active.value ?? active.textContent;
          if (activeVal != null) values[fv] = String(activeVal).trim();
        }
      });
      document.querySelectorAll('input[data-filter-var], textarea[data-filter-var]').forEach((el) => {
        const fv = el.getAttribute('data-filter-var');
        if (!fv) return;
        const type = String(el.type || '').toLowerCase();
        if (type === 'radio' || type === 'checkbox') return;
        values[fv] = el.value;
      });

      const failures = [];
      const details = [];
      (rules || []).forEach((rule) => {
        const selector = String(rule.selector || '');
        const nodes = Array.from(document.querySelectorAll(selector));
        if (!nodes.length) {
          if (rule.required !== false) failures.push(`selector missing: ${selector}`);
          details.push({ selector, matched: false, reason: 'missing-selector' });
          return;
        }

        const effectiveNodes = (rule.require_visible === false) ? nodes : nodes.filter((n) => isVisible(n));
        if (!effectiveNodes.length) {
          if (rule.required !== false) failures.push(`selector has no visible node: ${selector}`);
          details.push({ selector, matched: false, reason: 'no-visible-node' });
          return;
        }

        const text = effectiveNodes
          .map((n) => String(n.innerText || n.textContent || '').replace(/\s+/g, ' ').trim())
          .filter((x) => x.length > 0)
          .join(' | ');
        const textNorm = normalize(text);
        const vars = Array.isArray(rule.vars) ? rule.vars : [];
        if (!vars.length) {
          details.push({ selector, matched: true, reason: 'no-vars', text });
          return;
        }

        const varMatches = vars.map((v) => {
          const tokens = asTokens(values[v]);
          const matched = tokens.some((t) => textNorm.includes(normalize(t)));
          return { var: v, tokens, matched };
        });
        const overall = String(rule.match_mode || 'any') === 'all'
          ? varMatches.every((x) => x.matched)
          : varMatches.some((x) => x.matched);
        if (!overall && rule.required !== false) {
          const pairText = varMatches.map((x) => `${x.var}=[${x.tokens.join(', ')}]`).join('; ');
          failures.push(`selector '${selector}' text did not reflect selected values (${pairText})`);
        }
        details.push({ selector, matched: overall, var_matches: varMatches, text });
      });

      return { values, failures, details };
    }, dynamicBindingRules);

    interactionResults.dynamic_bindings = interactionResults.dynamic_bindings || {};
    interactionResults.dynamic_bindings[stage] = result;
    (result.failures || []).forEach((msg) => fail(`Dynamic binding failed (${stage}): ${msg}`));
  };

  const captureLargeEmptyCards = async () => {
    return await page.evaluate(({ minHeight, minWidth }) => {
      const isVisible = (el) => {
        if (!el) return false;
        if (el.classList && el.classList.contains('dashboardr-sw-hidden')) return false;
        const st = window.getComputedStyle(el);
        if (!st || st.display === 'none' || st.visibility === 'hidden' || st.opacity === '0') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
      };

      const visibleContentSelectors = [
        '.js-plotly-plot',
        '.echarts4r',
        '.echarts',
        '.highcharts-container',
        '.girafe',
        '.leaflet-container',
        'table',
        'svg',
        'img',
        'iframe',
        'video'
      ];

      const cards = Array.from(document.querySelectorAll('.sidebar-content .card, .sidebar-content .bslib-card'));
      const emptyCards = [];

      cards.forEach((card, idx) => {
        if (!isVisible(card)) return;
        const rect = card.getBoundingClientRect();
        if (rect.height < minHeight || rect.width < minWidth) return;

        const hasVisibleContent = visibleContentSelectors.some((selector) => {
          const nodes = Array.from(card.querySelectorAll(selector));
          return nodes.some((node) => isVisible(node));
        });

        const text = String(card.innerText || card.textContent || '').replace(/\s+/g, ' ').trim();
        const hasMeaningfulText = text.length >= 40;

        if (!hasVisibleContent && !hasMeaningfulText) {
          emptyCards.push({
            index: idx + 1,
            id: card.id || '',
            className: card.className || '',
            width: Math.round(rect.width),
            height: Math.round(rect.height),
            text
          });
        }
      });

      return {
        count: emptyCards.length,
        cards: emptyCards
      };
    }, { minHeight: largeEmptyCardMinHeight, minWidth: largeEmptyCardMinWidth });
  };

  const assertFontExpectations = async () => {
    if (!fontExpectations.length) return [];
    const checks = await page.evaluate((rules) => {
      const isVisible = (el) => {
        if (!el) return false;
        const st = window.getComputedStyle(el);
        if (!st || st.display === 'none' || st.visibility === 'hidden' || st.opacity === '0') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
      };

      const parsePx = (value) => {
        const n = Number.parseFloat(String(value || ''));
        return Number.isFinite(n) ? n : null;
      };

      return (rules || []).map((rule) => {
        const selector = String((rule && rule.selector) || '').trim();
        const selectors = selector.split(',').map((x) => x.trim()).filter((x) => x.length > 0);
        let selected = null;
        let matchedSelector = null;

        for (const sel of selectors) {
          const nodes = Array.from(document.querySelectorAll(sel));
          const visibleNode = nodes.find((node) => isVisible(node));
          if (visibleNode) {
            selected = visibleNode;
            matchedSelector = sel;
            break;
          }
          if (!selected && nodes.length > 0) {
            selected = nodes[0];
            matchedSelector = sel;
          }
        }

        if (!selected) {
          return {
            selector,
            found: false,
            matched_selector: null,
            font_family: '',
            font_size_px: null,
            font_weight: null
          };
        }

        const style = window.getComputedStyle(selected);
        return {
          selector,
          found: true,
          matched_selector: matchedSelector,
          font_family: String(style.fontFamily || ''),
          font_size_px: parsePx(style.fontSize),
          font_weight: style.fontWeight ? String(style.fontWeight) : null
        };
      });
    }, fontExpectations);

    checks.forEach((entry, idx) => {
      const rule = fontExpectations[idx] || {};
      const selector = String(rule.selector || entry.selector || '').trim();
      if (!entry.found) {
        if (rule.required !== false) {
          fail(`Font check selector not found: ${selector}`);
        }
        return;
      }

      const family = String(entry.font_family || '');
      const familyLower = family.toLowerCase();
      const containsAny = Array.isArray(rule.contains_any) ? rule.contains_any : [];
      const notContainsAny = Array.isArray(rule.not_contains_any) ? rule.not_contains_any : [];

      if (!family.trim()) {
        fail(`Font family is empty for selector '${selector}'.`);
      }
      if (containsAny.length > 0) {
        const ok = containsAny.some((token) => familyLower.includes(String(token || '').toLowerCase()));
        if (!ok) {
          fail(`Font family '${family}' for selector '${selector}' did not match expected set.`);
        }
      }
      if (notContainsAny.length > 0) {
        const blocked = notContainsAny.find((token) => familyLower.includes(String(token || '').toLowerCase()));
        if (blocked) {
          fail(`Font family '${family}' for selector '${selector}' contains forbidden token '${blocked}'.`);
        }
      }
      if (Number.isFinite(rule.min_size_px) && Number.isFinite(entry.font_size_px) && entry.font_size_px < rule.min_size_px) {
        fail(`Font size ${entry.font_size_px}px for selector '${selector}' is below minimum ${rule.min_size_px}px.`);
      }
    });

    return checks;
  };

  try {
    // Ensure viewport is large enough for Quarto dashboard fill layouts
    await page.setViewportSize({ width: 1440, height: 900 });

    await page.goto(scenario.url, {
      waitUntil: 'networkidle',
      timeout: 45000
    });
    await wait(1200);

    // Wait for chart widgets to finish rendering (Highcharts, plotly, echarts)
    // Some backends (especially highcharter) load data asynchronously after DOM ready.
    const chartsReady = await page.evaluate(() => {
      const hasHCWidgets = document.querySelectorAll('.htmlwidget-output, .html-widget').length > 0;
      if (!hasHCWidgets) return true;
      const hcCharts = (window.Highcharts && Array.isArray(window.Highcharts.charts))
        ? window.Highcharts.charts.filter((x) => !!x && !!x.series) : [];
      if (hcCharts.length > 0 && hcCharts.every((c) => c.series.length > 0)) return true;
      const plotlyDivs = document.querySelectorAll('.js-plotly-plot');
      if (plotlyDivs.length > 0 && Array.from(plotlyDivs).every((d) => d.data && d.data.length > 0)) return true;
      const echartsWidgets = document.querySelectorAll('[_echarts_instance_]');
      if (echartsWidgets.length > 0) return true;
      return false;
    });
    if (!chartsReady) {
      // Extra wait for slow backends
      await wait(3000);
    }

    for (const selector of requiredSelectors) {
      const locator = page.locator(selector).first();
      const count = await locator.count();
      if (!count) {
        fail(`Missing required selector: ${selector}`);
      }
    }

    for (const textNeedle of requiredTexts) {
      const found = await page.evaluate((needle) => {
        if (!document || !document.body) return false;
        const normalize = (value) => String(value || '')
          .replace(/\s+/g, ' ')
          .trim()
          .toLowerCase();
        const text = normalize(document.body.innerText || '');
        const target = normalize(needle);
        return text.includes(target);
      }, textNeedle);
      if (!found) {
        fail(`Missing required text: ${textNeedle}`);
      }
    }
    await assertForbiddenTextsAbsent('initial');

    if (fontExpectations.length > 0) {
      interactionResults.fonts = await assertFontExpectations();
    }
    if (requireShowWhenConsistency) {
      await assertShowWhenConsistency('initial');
    }
    await assertDynamicBindings('initial');

    const initialState = await captureChartState();
    assertExpectedBackendsVisible(initialState);

    for (const action of interactionPlan) {
      if (action === 'filter') {
        interactionResults.filter = await performFilterInteraction();
        if (!interactionResults.filter.action || !interactionResults.filter.action.performed) {
          fail('Filter interaction could not be performed.');
        }
      } else if (action === 'linked_inputs') {
        interactionResults.linked_inputs = await performLinkedInputsInteraction();
        if (!interactionResults.linked_inputs || !interactionResults.linked_inputs.performed) {
          fail('Linked-input interaction could not be performed.');
        } else if (!interactionResults.linked_inputs.changed) {
          fail('Linked-input interaction did not update child options.');
        }
      } else if (action === 'tab_click') {
        interactionResults.tab_click = await performTabClickInteraction();
        if (!interactionResults.tab_click || !interactionResults.tab_click.performed) {
          fail('Tab-click interaction could not be performed.');
        } else if (!interactionResults.tab_click.changed) {
          fail('Tab-click interaction did not change active tab.');
        }
      } else if (action === 'sidebar_toggle') {
        interactionResults.sidebar_toggle = await performSidebarToggleInteraction();
        if (!interactionResults.sidebar_toggle || !interactionResults.sidebar_toggle.performed) {
          fail('Sidebar-toggle interaction could not be performed.');
        }
      } else if (action === 'modal_toggle') {
        interactionResults.modal_toggle = await performModalInteraction();
        if (!interactionResults.modal_toggle || !interactionResults.modal_toggle.performed) {
          fail('Modal interaction could not be performed.');
        } else if (!interactionResults.modal_toggle.changed) {
          fail('Modal interaction did not open and close the modal correctly.');
        }
      } else if (action === 'tooltip_hover') {
        interactionResults.tooltip_hover = await performTooltipInteraction();
        if (!interactionResults.tooltip_hover || !interactionResults.tooltip_hover.performed) {
          fail('Tooltip interaction could not be performed.');
        } else if (!interactionResults.tooltip_hover.changed) {
          fail('Tooltip interaction did not produce visible tooltip content.');
        } else if (interactionResults.tooltip_hover.has_undefined) {
          fail('Tooltip text contains "undefined".');
        }
      } else if (action === 'show_when_toggle') {
        interactionResults.show_when_toggle = await performShowWhenInteraction();
        if (!interactionResults.show_when_toggle || !interactionResults.show_when_toggle.performed) {
          fail('Show-when interaction could not be performed.');
        } else if (!interactionResults.show_when_toggle.changed) {
          fail('Show-when interaction did not change visible conditional blocks.');
        }
      } else if (action === 'slider') {
        interactionResults.slider = await performSliderInteraction();
        if (!interactionResults.slider || !interactionResults.slider.action || !interactionResults.slider.action.performed) {
          fail('Slider interaction could not be performed.');
        }
      }
    }

    if (isTruthy(scenario.expect_filter_effect)) {
      if (!interactionResults.filter || !interactionResults.filter.action || !interactionResults.filter.action.performed) {
        fail('Expected filter effect, but filter action was not performed.');
      } else if (!interactionResults.filter.changed) {
        fail('Expected filter effect, but chart/widget state did not change.');
      }
    }
    if (requireAllChartsChangeOnFilter && interactionResults.filter && interactionResults.filter.action && interactionResults.filter.action.performed) {
      const comparison = compareExpectedBackendEntryChanges(interactionResults.filter.before, interactionResults.filter.after);
      interactionResults.filter.backend_change = comparison;
      if (!comparison.ok) {
        fail(`Filter interaction did not affect all chart widgets (${formatBackendChangeSummary(comparison)}).`);
      }
    }

    if (isTruthy(scenario.expect_slider_effect)) {
      if (!interactionResults.slider || !interactionResults.slider.action || !interactionResults.slider.action.performed) {
        fail('Expected slider effect, but slider action was not performed.');
      } else if (!interactionResults.slider.changed) {
        fail('Expected slider effect, but chart/widget state did not change.');
      }
    }
    if (expectModalEffect) {
      if (!interactionResults.modal_toggle || !interactionResults.modal_toggle.performed) {
        fail('Expected modal effect, but modal action was not performed.');
      } else if (!interactionResults.modal_toggle.changed) {
        fail('Expected modal effect, but modal did not open and close cleanly.');
      }
    }
    if (expectTooltipEffect) {
      if (!interactionResults.tooltip_hover || !interactionResults.tooltip_hover.performed) {
        fail('Expected tooltip effect, but tooltip action was not performed.');
      } else if (!interactionResults.tooltip_hover.changed) {
        fail('Expected tooltip effect, but tooltip content did not appear/change.');
      } else if (interactionResults.tooltip_hover.has_undefined) {
        fail('Expected tooltip effect, but tooltip contains "undefined".');
      }
    }
    if (requireAllChartsChangeOnSlider && interactionResults.slider && interactionResults.slider.action && interactionResults.slider.action.performed) {
      const comparison = compareExpectedBackendEntryChanges(interactionResults.slider.before, interactionResults.slider.after);
      interactionResults.slider.backend_change = comparison;
      if (!comparison.ok) {
        fail(`Slider interaction did not affect all chart widgets (${formatBackendChangeSummary(comparison)}).`);
      }
    }

    if (isTruthy(scenario.expect_dynamic_text_effect)) {
      const hasPerformed = (candidate) => {
        if (!candidate) return false;
        if (candidate.action && candidate.action.performed) return true;
        if (Object.prototype.hasOwnProperty.call(candidate, 'performed') && candidate.performed) return true;
        return false;
      };
      const dynamicCandidate = [
        interactionResults.show_when_toggle,
        interactionResults.slider,
        interactionResults.filter
      ].find((candidate) => hasPerformed(candidate));
      if (!dynamicCandidate) {
        fail('Expected dynamic text effect, but no eligible interaction was performed.');
      } else if (!dynamicCandidate.dynamic_text || !dynamicCandidate.dynamic_text.changed) {
        const mode = dynamicCandidate.dynamic_text && dynamicCandidate.dynamic_text.mode === 'selectors'
          ? 'configured selector text'
          : 'slider-linked text';
        fail(`Expected dynamic text effect, but ${mode} did not change.`);
      }
    }

    if (expectDynamicTitleEffect) {
      const hasPerformed = (candidate) => {
        if (!candidate) return false;
        if (candidate.action && candidate.action.performed) return true;
        if (Object.prototype.hasOwnProperty.call(candidate, 'performed') && candidate.performed) return true;
        return false;
      };
      const titleCandidate = [
        interactionResults.show_when_toggle,
        interactionResults.slider,
        interactionResults.filter
      ].find((candidate) => hasPerformed(candidate));
      if (!titleCandidate) {
        fail('Expected dynamic title effect, but no eligible interaction was performed.');
      } else if (!titleCandidate.dynamic_title || !titleCandidate.dynamic_title.changed) {
        fail('Expected dynamic title effect, but chart title text did not change.');
      } else if (requireDynamicTitlePlaceholdersResolved && titleCandidate.dynamic_title.after_has_placeholders) {
        fail('Dynamic title still contains unresolved placeholders after interaction.');
      }
    }

    if (requireAllInputVarsAffectAllCharts) {
      interactionResults.input_propagation = await validateAllInputVarsAffectAllCharts();
    }

    const finalState = await captureChartState();
    assertExpectedBackendsVisible(finalState);
    await assertForbiddenTextsAbsent('final');
    if (minNonEmptyChartsExpected !== null) {
      const nonEmptyCharts = countNonEmptyForExpected(finalState);
      if (nonEmptyCharts < minNonEmptyChartsExpected) {
        fail(`Expected at least ${minNonEmptyChartsExpected} non-empty chart(s), but detected ${nonEmptyCharts}.`);
      }
    }
    if (requireEducationBoxplotCategories) {
      await assertEducationBoxplotCoverage();
    }
    if (maxLargeEmptyCards !== null) {
      const emptyInfo = await captureLargeEmptyCards();
      interactionResults.large_empty_cards = emptyInfo;
      if (Number(emptyInfo.count || 0) > maxLargeEmptyCards) {
        fail(`Detected ${emptyInfo.count} large visible empty card(s); expected <= ${maxLargeEmptyCards}.`);
      }
    }
    if (requireShowWhenConsistency) {
      await assertShowWhenConsistency('final');
    }
    await assertDynamicBindings('final');

    const endedAt = new Date().toISOString();

    return {
      id: scenario.id,
      source_type: scenario.source_type,
      backend: scenario.backend,
      url: scenario.url,
      local_file_url: localFileUrl,
      local_file_path: localFilePath,
      started_at: startedAt,
      ended_at: endedAt,
      duration_ms: Date.now() - startMs,
      failures,
      interaction_results: interactionResults,
      initial_state: initialState,
      final_state: finalState,
      status: failures.length === 0 ? 'pass' : 'fail'
    };
  } catch (err) {
    fail(`Scenario runtime error: ${err && err.message ? err.message : String(err)}`);
    return {
      id: scenario.id,
      source_type: scenario.source_type,
      backend: scenario.backend,
      url: scenario.url,
      local_file_url: localFileUrl,
      local_file_path: localFilePath,
      started_at: startedAt,
      ended_at: new Date().toISOString(),
      duration_ms: Date.now() - startMs,
      failures,
      interaction_results: interactionResults,
      status: 'fail'
    };
  }
}
