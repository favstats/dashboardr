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
  
  // Create modal container on page load
  document.addEventListener('DOMContentLoaded', function() {
    
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
    document.body.appendChild(modalOverlay);
    
    // Close modal function
    function closeModal() {
      modalOverlay.style.display = 'none';
      modalBody.innerHTML = '';
      document.body.style.overflow = '';
    }
    
    // Open modal function
    function openModal(contentId) {
      const content = document.getElementById(contentId);
      if (!content) {
        console.error('Modal content not found: ' + contentId);
        return;
      }
      
      // Clone the content to avoid moving it from its original location
      const clonedContent = content.cloneNode(true);
      clonedContent.style.display = 'block';
      
      modalBody.innerHTML = '';
      modalBody.appendChild(clonedContent);
      modalOverlay.style.display = 'flex';
      document.body.style.overflow = 'hidden';
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
        e.preventDefault();
        openModal(dataModal);
        return;
      }
      
      // Check if link has modal-link class
      if (link.classList.contains('modal-link')) {
        const href = link.getAttribute('href');
        if (href && href.startsWith('#')) {
          const modalId = href.substring(1); // Remove the '#'
          const modalContent = document.getElementById(modalId);
          
          // Only open if there's a matching modal-content div
          if (modalContent && modalContent.classList.contains('modal-content')) {
            e.preventDefault();
            openModal(modalId);
          }
        }
      }
    });
    
  });
  
})();

