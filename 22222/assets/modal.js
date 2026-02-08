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

  // Simple check to ensure script is loaded
  console.log('dashboardr modal.js loaded successfully');
  
  // Initialize modals
  function initializeModals() {
    console.log('Initializing dashboardr modals...');

    // Prevent duplicate initialization
    if (document.getElementById('dashboardr-modal-overlay')) {
      console.log('Modal overlay already exists, skipping initialization');
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
      console.log('Modal overlay created and appended to document.body:', modalOverlay);
    } else {
      console.error('document.body not available, cannot append modal overlay');
    }
    
    // Close modal function
    function closeModal() {
      modalOverlay.style.display = 'none';
      modalBody.innerHTML = '';
      document.body.style.overflow = '';
    }
    
    // Open modal function
    function openModal(contentId) {
      console.log('Attempting to open modal:', contentId);

      const content = document.getElementById(contentId);
      if (!content) {
        console.error('Modal content not found: ' + contentId);
        return;
      }

      console.log('Found modal content:', content);

      // Clone the content to avoid moving it from its original location
      const clonedContent = content.cloneNode(true);
      clonedContent.style.display = 'block';

      modalBody.innerHTML = '';
      modalBody.appendChild(clonedContent);
      modalOverlay.style.display = 'flex';
      modalOverlay.style.zIndex = '100000';
      document.body.style.overflow = 'hidden';

      console.log('Modal should now be visible');
      console.log('Modal overlay display:', window.getComputedStyle(modalOverlay).display);
      console.log('Modal overlay z-index:', window.getComputedStyle(modalOverlay).zIndex);
      console.log('Modal overlay visibility:', window.getComputedStyle(modalOverlay).visibility);
      console.log('Modal container display:', window.getComputedStyle(modalContainer).display);
      console.log('Modal container visibility:', window.getComputedStyle(modalContainer).visibility);
      console.log('Modal body display:', window.getComputedStyle(modalBody).display);
      console.log('Modal body content length:', modalBody.innerHTML.length);
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

      console.log('Click detected on link:', link);

      // Check for data-modal attribute first
      const dataModal = link.getAttribute('data-modal');
      if (dataModal) {
        console.log('Found data-modal attribute:', dataModal);
        e.preventDefault();
        openModal(dataModal);
        return;
      }

      // Check if link has modal-link class
      if (link.classList.contains('modal-link')) {
        try {
          console.log('Link has modal-link class');
          const href = link.getAttribute('href');
          console.log('Raw href:', href);

          // Extract modal ID from href - handle both relative (#id) and absolute URLs (https://...#id)
          let modalId = null;
          if (href) {
            const hashIndex = href.indexOf('#');
            if (hashIndex !== -1) {
              modalId = href.substring(hashIndex + 1); // Get everything after '#'
            }
          }

          console.log('About to check for modalId, current value:', modalId);
          
          if (modalId) {
            console.log('Extracted modal ID:', modalId);
            let modalContent = document.getElementById(modalId);
            console.log('Searched for element with ID:', modalId);
            console.log('Result of getElementById:', modalContent);
            
            // Fallback: try case-insensitive search if not found
            if (!modalContent) {
              console.log('Trying case-insensitive search...');
              const allElements = document.querySelectorAll('[id]');
              for (const el of allElements) {
                if (el.id.toLowerCase() === modalId.toLowerCase()) {
                  modalContent = el;
                  console.log('Found with case-insensitive match:', el.id);
                  break;
                }
              }
            }

            // Only open if there's a matching modal-content div
            if (modalContent && modalContent.classList.contains('modal-content')) {
              console.log('Found matching modal content:', modalContent);
              console.log('Modal content classes:', modalContent.className);
              console.log('Modal content display:', window.getComputedStyle(modalContent).display);
              e.preventDefault(); // Only prevent default if we found a valid modal
              openModal(modalId);
            } else {
              console.log('No matching modal content found for ID:', modalId);
              console.log('modalContent element:', modalContent);
              if (modalContent) {
                console.log('modalContent classes:', modalContent.className);
                console.log('Does it have modal-content class?', modalContent.classList.contains('modal-content'));
              } else {
                console.log('Element with ID not found in document');
                console.log('All elements with modal-content class:', document.querySelectorAll('.modal-content').length);
              }
              // Don't prevent default if no valid modal found - let the link work normally
            }
          } else {
            console.log('No modal ID found in href');
            console.log('href was:', href);
          }
        } catch (err) {
          console.error('Error in modal-link handler:', err);
          console.error('Error stack:', err.stack);
        }
      }
    });
  }
  
  // Run initialization when DOM is ready
  // Handle both cases: DOM already loaded or still loading
  if (document.readyState === 'loading') {
    // DOM is still loading, wait for it
    document.addEventListener('DOMContentLoaded', initializeModals);
  } else {
    // DOM is already loaded, initialize immediately
    initializeModals();
  }

  // Also initialize on window load as a fallback
  window.addEventListener('load', function() {
    console.log('Window loaded, ensuring modals are initialized...');
    initializeModals();
    
    // Diagnostic: List all elements with IDs that might be modal content
    try {
      console.log('=== MODAL DIAGNOSTIC ===');
      console.log('All elements with modal-content class:', document.querySelectorAll('.modal-content'));
      console.log('All elements with IDs starting with P:', document.querySelectorAll('[id^="P"]'));
      console.log('Sample of all IDs in document:', Array.from(document.querySelectorAll('[id]')).slice(0, 20).map(el => el.id));
      console.log('=== END DIAGNOSTIC ===');
    } catch (err) {
      console.error('Diagnostic failed:', err);
    }
    
    // Set up MutationObserver to watch for dynamically added modal content
    const observer = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        mutation.addedNodes.forEach(function(node) {
          if (node.nodeType === 1) { // Element node
            // Check if the added node or any of its children have modal-content class
            if (node.classList && node.classList.contains('modal-content')) {
              console.log('New modal content detected:', node.id);
            } else if (node.querySelectorAll) {
              const modalContents = node.querySelectorAll('.modal-content');
              if (modalContents.length > 0) {
                console.log('New modal content(s) detected in added node:', Array.from(modalContents).map(el => el.id));
              }
            }
          }
        });
      });
    });
    
    // Start observing the document body for child additions
    observer.observe(document.body, { childList: true, subtree: true });
    console.log('MutationObserver set up to watch for dynamic modal content');
  });
  
})();

