/**
 * Language tab switching (FR-03.3). Progressive enhancement: the server
 * renders every language's code sample fully visible and stacked (so the
 * page is complete and readable with JavaScript disabled, NFR-02.4) — this
 * module only collapses that into a tabbed view once it loads, scoping every
 * lookup to the clicked control's own .securepress-code-panel ancestor so
 * one mitigation's tabs never affect another mitigation's on the same page.
 *
 * The attack-demo confirmation gate (FR-03.4) is a native <details>/<summary>
 * element instead of a JS-driven <dialog> specifically so it also works with
 * JavaScript disabled — no JS handling is needed or present for it here.
 */
(function () {
  'use strict';

  const panel = document.getElementById('code-samples');
  if (!panel) {
    return;
  }

  panel.querySelectorAll('.securepress-code-panel').forEach(function (codePanel) {
    const tabs = codePanel.querySelectorAll('[data-language-tab]');
    const bodies = codePanel.querySelectorAll('[data-language-body]');

    if (tabs.length === 0) {
      return;
    }

    bodies.forEach(function (body, index) {
      body.hidden = index !== 0;
    });
    tabs.forEach(function (tab, index) {
      tab.setAttribute('aria-selected', index === 0 ? 'true' : 'false');
    });
  });

  panel.addEventListener('click', function (event) {
    const tabButton = event.target.closest('[data-language-tab]');
    if (!tabButton) {
      return;
    }

    const scope = tabButton.closest('.securepress-code-panel') || panel;
    scope.querySelectorAll('[data-language-tab]').forEach(function (btn) {
      btn.setAttribute('aria-selected', btn === tabButton ? 'true' : 'false');
    });
    scope.querySelectorAll('[data-language-body]').forEach(function (body) {
      body.hidden = body.dataset.languageBody !== tabButton.dataset.languageTab;
    });
  });
})();
