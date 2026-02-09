/**
 * dashboardrFilterHook
 * 
 * Legacy hook - delegates to dashboardrInputs system.
 */
(function() {
  window.dashboardrFilterHook = function(inputId, filterVar, attempt) {
    // Trigger initialization if dashboardrInputs is ready
    if (window.dashboardrInputs && window.dashboardrInputs.init) {
      if (document.readyState !== 'loading') {
        window.dashboardrInputs.init();
      }
    }
  };
})();
