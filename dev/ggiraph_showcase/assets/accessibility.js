/**
 * Accessibility Enhancements for dashboardr
 *
 * Provides:
 * - Modal focus trapping (Tab/Shift+Tab within modal, focus return on close)
 * - Tab keyboard navigation (Arrow keys, Home/End)
 * - ARIA live region for filter change announcements
 */

(function() {
  'use strict';

  // =========================================================
  // ARIA Live Region
  // Announces filter changes to screen readers
  // =========================================================

  var liveRegion = null;
  var announceTimer = null;

  function ensureLiveRegion() {
    if (liveRegion) return liveRegion;
    liveRegion = document.getElementById('dashboardr-live-region');
    if (!liveRegion) {
      liveRegion = document.createElement('div');
      liveRegion.id = 'dashboardr-live-region';
      liveRegion.setAttribute('aria-live', 'polite');
      liveRegion.setAttribute('aria-atomic', 'true');
      liveRegion.setAttribute('role', 'status');
      document.body.appendChild(liveRegion);
    }
    return liveRegion;
  }

  function announce(message) {
    var region = ensureLiveRegion();
    // Clear then set after a frame to ensure screen readers pick up the change
    region.textContent = '';
    clearTimeout(announceTimer);
    announceTimer = setTimeout(function() {
      region.textContent = message;
    }, 100);
  }

  // Listen for filter changes and announce
  document.addEventListener('dashboardr:filter-changed', function(e) {
    // Debounce announcements (500ms)
    clearTimeout(announceTimer);
    announceTimer = setTimeout(function() {
      announce('Filters updated');
    }, 500);
  });

  // =========================================================
  // Modal Focus Trapping
  // Trap Tab/Shift+Tab within open modals, return focus on close
  // =========================================================

  var previousActiveElement = null;

  function getFocusableElements(container) {
    var selectors = [
      'a[href]',
      'button:not([disabled])',
      'input:not([disabled])',
      'select:not([disabled])',
      'textarea:not([disabled])',
      '[tabindex]:not([tabindex="-1"])'
    ];
    return Array.from(container.querySelectorAll(selectors.join(', ')));
  }

  function initModalFocusTrap() {
    var overlay = document.getElementById('dashboardr-modal-overlay');
    if (!overlay) return;

    // Add ARIA attributes
    overlay.setAttribute('role', 'dialog');
    overlay.setAttribute('aria-modal', 'true');
    overlay.setAttribute('aria-label', 'Modal dialog');

    // Observe modal visibility changes
    var observer = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        if (mutation.attributeName === 'style') {
          var isVisible = overlay.style.display === 'flex';
          if (isVisible) {
            onModalOpen(overlay);
          } else {
            onModalClose();
          }
        }
      });
    });
    observer.observe(overlay, { attributes: true, attributeFilter: ['style'] });
  }

  function onModalOpen(overlay) {
    // Store the element that triggered the modal
    previousActiveElement = document.activeElement;

    // Focus the close button after a short delay (content needs to render)
    setTimeout(function() {
      var closeBtn = overlay.querySelector('.dashboardr-modal-close');
      if (closeBtn) {
        closeBtn.focus();
      }
    }, 100);
  }

  function onModalClose() {
    // Return focus to the element that opened the modal
    if (previousActiveElement && typeof previousActiveElement.focus === 'function') {
      try {
        previousActiveElement.focus();
      } catch (e) {
        // Element may have been removed from DOM
      }
    }
    previousActiveElement = null;
  }

  // Global keydown handler for modal focus trapping
  document.addEventListener('keydown', function(e) {
    var overlay = document.getElementById('dashboardr-modal-overlay');
    if (!overlay || overlay.style.display !== 'flex') return;

    if (e.key === 'Tab') {
      var focusable = getFocusableElements(overlay);
      if (focusable.length === 0) return;

      var first = focusable[0];
      var last = focusable[focusable.length - 1];

      if (e.shiftKey) {
        // Shift+Tab: wrap to last element
        if (document.activeElement === first) {
          e.preventDefault();
          last.focus();
        }
      } else {
        // Tab: wrap to first element
        if (document.activeElement === last) {
          e.preventDefault();
          first.focus();
        }
      }
    }
  });

  // =========================================================
  // Tab Keyboard Navigation
  // Arrow keys navigate between tabs, Home/End jump to first/last
  // =========================================================

  function initTabKeyboardNav() {
    // Delegate on document for tabs that exist now or are added later
    document.addEventListener('keydown', function(e) {
      var tab = e.target;
      if (!tab.matches || !tab.matches('[role="tab"]')) return;

      var tablist = tab.closest('[role="tablist"]');
      if (!tablist) {
        // Quarto doesn't always add role="tablist"; try .nav-tabs
        tablist = tab.closest('.nav-tabs');
      }
      if (!tablist) return;

      var tabs = Array.from(tablist.querySelectorAll('[role="tab"]'));
      if (tabs.length < 2) return;

      var currentIndex = tabs.indexOf(tab);
      if (currentIndex === -1) return;

      var newIndex = -1;

      switch (e.key) {
        case 'ArrowRight':
        case 'ArrowDown':
          e.preventDefault();
          newIndex = (currentIndex + 1) % tabs.length;
          break;
        case 'ArrowLeft':
        case 'ArrowUp':
          e.preventDefault();
          newIndex = (currentIndex - 1 + tabs.length) % tabs.length;
          break;
        case 'Home':
          e.preventDefault();
          newIndex = 0;
          break;
        case 'End':
          e.preventDefault();
          newIndex = tabs.length - 1;
          break;
        default:
          return;
      }

      if (newIndex >= 0 && newIndex < tabs.length) {
        tabs[newIndex].focus();
        tabs[newIndex].click();
      }
    });
  }

  // =========================================================
  // Initialization
  // =========================================================

  function initAccessibility() {
    ensureLiveRegion();
    initModalFocusTrap();
    initTabKeyboardNav();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAccessibility);
  } else {
    initAccessibility();
  }

  // Also run on window load as fallback (modal may be created later)
  window.addEventListener('load', function() {
    initModalFocusTrap();
  });

})();
