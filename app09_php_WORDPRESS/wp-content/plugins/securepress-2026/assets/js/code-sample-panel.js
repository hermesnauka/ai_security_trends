/**
 * Language tab switching + attack-demo confirmation dialog (FR-03.3/FR-03.4).
 * Code samples land in a later build phase (PLAN.md Phase 4); this module is
 * written against the markup contract those samples will use, so it is
 * inert (no-op) until #code-samples actually contains sample data.
 */
(function () {
  'use strict';

  const panel = document.getElementById('code-samples');
  if (!panel) {
    return;
  }

  panel.addEventListener('click', function (event) {
    const tabButton = event.target.closest('[data-language-tab]');
    if (tabButton) {
      panel.querySelectorAll('[data-language-tab]').forEach(function (btn) {
        btn.setAttribute('aria-selected', btn === tabButton ? 'true' : 'false');
      });
      panel.querySelectorAll('[data-language-body]').forEach(function (body) {
        body.hidden = body.dataset.languageBody !== tabButton.dataset.languageTab;
      });
      return;
    }

    const confirmButton = event.target.closest('[data-testid="attack-demo-confirm"]');
    if (confirmButton) {
      const dialog = confirmButton.closest('dialog');
      const codeBody = dialog ? dialog.parentElement.querySelector('[data-testid="attack-demo-code-body"]') : null;
      if (codeBody) {
        codeBody.hidden = false;
      }
      if (dialog && typeof dialog.close === 'function') {
        dialog.close();
      }
    }
  });
})();
