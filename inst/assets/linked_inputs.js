/**
 * Linked (cascading) parent-child select inputs for dashboardr
 *
 * When a parent select has data-linked-child-id and data-options-by-parent,
 * changing the parent updates the child select's options and resets its value.
 *
 * Works with both native <select> elements and Choices.js-wrapped selects.
 */
(function() {
  'use strict';

  function initLinkedInputs() {
    var wrappers = document.querySelectorAll('[data-linked-child-id]');
    wrappers.forEach(function(wrapper) {
      var childId = wrapper.getAttribute('data-linked-child-id');
      var optionsByParentStr = wrapper.getAttribute('data-options-by-parent');
      if (!childId || !optionsByParentStr) return;

      var optionsByParent;
      try {
        optionsByParent = JSON.parse(optionsByParentStr);
      } catch (e) {
        console.warn('dashboardr linked_inputs: invalid data-options-by-parent', e);
        return;
      }

      var childEl = document.getElementById(childId);
      if (!childEl) return;

      var parentSelect = wrapper.querySelector('select.dashboardr-input, select[id]');
      if (!parentSelect) return;

      function updateChildOptions() {
        var parentValue = parentSelect.value;
        var rawOptions = optionsByParent[parentValue];
        var newOptions = Array.isArray(rawOptions)
          ? rawOptions
          : (rawOptions == null ? [] : [rawOptions]);
        newOptions = newOptions
          .filter(function(opt) { return opt !== null && opt !== undefined; })
          .map(function(opt) { return String(opt); });

        // Check if child is wrapped by Choices.js
        var choicesInstances = window.dashboardrChoicesInstances || {};
        var childChoices = choicesInstances[childId];

        if (childChoices) {
          // Use Choices.js API: clear all items/choices, then set new ones
          childChoices.clearStore();
          childChoices.setChoices(
            newOptions.map(function(opt, idx) {
              return { value: opt, label: opt, selected: idx === 0 };
            }),
            'value', 'label', true
          );
        } else {
          // Native select: rebuild via DocumentFragment for atomic DOM update
          var frag = document.createDocumentFragment();
          newOptions.forEach(function(opt) {
            var option = document.createElement('option');
            option.value = opt;
            option.textContent = opt;
            frag.appendChild(option);
          });
          childEl.innerHTML = '';
          childEl.appendChild(frag);
        }

        // Fire change on the underlying select so input_filter.js picks it up
        childEl.dispatchEvent(new Event('change', { bubbles: true }));
      }

      parentSelect.addEventListener('change', updateChildOptions);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initLinkedInputs);
  } else {
    initLinkedInputs();
  }
})();
