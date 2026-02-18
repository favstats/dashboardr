/**
 * Simple Modal System for dashboardr
 *
 * Opens specific links in a modal instead of navigating to new page
 *
 * Usage in Markdown (add {.modal-link} class):
 * [Click me](#modal-id){.modal-link}
 * [{{< iconify ph:chart >}} View Results](#results-modal){.modal-link}
 *
 * Or with data-modal attribute:
 * <a href="#" data-modal="modal1">Click me</a>
 *
 * Modal content:
 * <div id="modal-id" class="modal-content" style="display:none;">
 *   <img src="image.jpg" alt="Description">
 *   <p>Text content here</p>
 * </div>
 */

(function() {
  'use strict';

  // Reuse the same debug check as show_when.js
  function isDebugEnabled() {
    if (window.DASHBOARDR_DEBUG === true || window.dashboardrDebug === true) return true;
    try {
      if (window.localStorage && window.localStorage.getItem('dashboardr_debug') === '1') return true;
    } catch (e) {}
    try {
      var qs = new URLSearchParams(window.location.search || '');
      if (qs.get('dashboardr_debug') === '1' || qs.get('debug') === '1') return true;
    } catch (e) {}
    return false;
  }

  function debugLog() {
    if (!isDebugEnabled()) return;
    try { console.log.apply(console, arguments); } catch (e) {}
  }

  // Initialize modals
  function initializeModals() {
    debugLog('Initializing dashboardr modals...');

    // Prevent duplicate initialization
    if (document.getElementById('dashboardr-modal-overlay')) {
      debugLog('Modal overlay already exists, skipping initialization');
      return;
    }

    // Create modal overlay and container
    const modalOverlay = document.createElement('div');
    modalOverlay.id = 'dashboardr-modal-overlay';
    modalOverlay.className = 'dashboardr-modal-overlay';
    modalOverlay.style.display = 'none';

    const modalContainer = document.createElement('div');
    modalContainer.id = 'dashboardr-modal-container';
    modalContainer.className = 'dashboardr-modal-container';

    const modalClose = document.createElement('button');
    modalClose.id = 'dashboardr-modal-close';
    modalClose.className = 'dashboardr-modal-close';
    modalClose.innerHTML = '&times;';
    modalClose.setAttribute('aria-label', 'Close modal');

    const modalBody = document.createElement('div');
    modalBody.id = 'dashboardr-modal-body';
    modalBody.className = 'dashboardr-modal-body';

    modalContainer.appendChild(modalClose);
    modalContainer.appendChild(modalBody);
    modalOverlay.appendChild(modalContainer);

    // Ensure document.body exists before appending
    if (document.body) {
      document.body.appendChild(modalOverlay);
      debugLog('Modal overlay created and appended to document.body');
    } else {
      console.error('document.body not available, cannot append modal overlay');
    }

    // Close modal function
    function closeModal() {
      modalOverlay.style.display = 'none';
      modalBody.innerHTML = '';
      document.body.style.overflow = '';
    }

    // Find a .modal-content element by ID.
    // Quarto can generate a <section id="..."> from headings that shadows
    // the dashboardr <div id="..." class="modal-content">, so getElementById
    // alone may return the wrong element.  Fall back to querySelectorAll.
    function findModalContent(id) {
      var el = document.getElementById(id);
      if (el && el.classList.contains('modal-content')) return el;

      // Fallback: find the .modal-content with this ID (handles duplicate IDs)
      var candidates = document.querySelectorAll('.modal-content#' + CSS.escape(id));
      if (candidates.length > 0) return candidates[0];

      // Last resort: case-insensitive scan
      var all = document.querySelectorAll('.modal-content[id]');
      for (var i = 0; i < all.length; i++) {
        if (all[i].id.toLowerCase() === id.toLowerCase()) return all[i];
      }
      return null;
    }

    // Open modal function
    function openModal(contentId) {
      debugLog('Attempting to open modal:', contentId);

      const content = findModalContent(contentId);
      if (!content) {
        console.error('Modal content not found: ' + contentId);
        return;
      }

      debugLog('Found modal content:', content);

      // Clone the content to avoid moving it from its original location
      const clonedContent = content.cloneNode(true);
      clonedContent.style.display = 'block';

      modalBody.innerHTML = '';
      modalBody.appendChild(clonedContent);
      modalOverlay.style.display = 'flex';
      document.body.style.overflow = 'hidden';

      debugLog('Modal visible, overlay display:', window.getComputedStyle(modalOverlay).display);
    }

    // Event listeners for closing
    modalClose.addEventListener('click', closeModal);

    modalOverlay.addEventListener('click', function(e) {
      if (e.target === modalOverlay) {
        closeModal();
      }
    });

    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && modalOverlay.style.display === 'flex') {
        closeModal();
      }
    });

    // Find all links with data-modal attribute or .modal-link class
    document.addEventListener('click', function(e) {
      const link = e.target.closest('a');
      if (!link) return;

      // Check for data-modal attribute first
      const dataModal = link.getAttribute('data-modal');
      if (dataModal) {
        debugLog('Found data-modal attribute:', dataModal);
        e.preventDefault();
        openModal(dataModal);
        return;
      }

      // Check if link has modal-link class
      if (link.classList.contains('modal-link')) {
        try {
          const href = link.getAttribute('href');

          // Extract modal ID from href - handle both relative (#id) and absolute URLs (https://...#id)
          let modalId = null;
          if (href) {
            const hashIndex = href.indexOf('#');
            if (hashIndex !== -1) {
              modalId = href.substring(hashIndex + 1); // Get everything after '#'
            }
          }

          if (modalId) {
            debugLog('Extracted modal ID:', modalId);
            let modalContent = findModalContent(modalId);

            if (modalContent) {
              debugLog('Found matching modal content:', modalContent);
              e.preventDefault(); // Only prevent default if we found a valid modal
              openModal(modalId);
            } else {
              debugLog('No matching modal content found for ID:', modalId);
              // Don't prevent default if no valid modal found - let the link work normally
            }
          } else {
            debugLog('No modal ID found in href:', href);
          }
        } catch (err) {
          console.error('Error in modal-link handler:', err);
        }
      }
    });
  }

  // Run initialization when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeModals);
  } else {
    initializeModals();
  }

  // Also initialize on window load as a fallback
  window.addEventListener('load', function() {
    initializeModals();
  });

})();
