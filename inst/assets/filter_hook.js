/**
 * dashboardrFilterHook  (LEGACY)
 * ===============================
 *
 * This file exists only for backward compatibility with dashboards that
 * were generated before the `dashboardrInputs` system was introduced.
 *
 * Older dashboards may call `window.dashboardrFilterHook(inputId, filterVar)`
 * from inline `<script>` tags. This shim redirects those calls to the
 * current input system (`dashboardrInputs.init()`), which lives in
 * `input_filter.js`.
 *
 * New dashboards register inputs directly through `input_filter.js` and
 * never call this hook. It can be safely removed once all previously
 * generated dashboards have been rebuilt.
 *
 * @param {string} inputId   - The input element id (unused in shim).
 * @param {string} filterVar - The filter variable name (unused in shim).
 * @param {number} [attempt] - Retry counter (unused in shim).
 */
(function() {
  window.dashboardrFilterHook = function(inputId, filterVar, attempt) {
    // Delegate to the current input system if available
    if (window.dashboardrInputs && window.dashboardrInputs.init) {
      if (document.readyState !== 'loading') {
        window.dashboardrInputs.init();
      }
    }
  };
})();
