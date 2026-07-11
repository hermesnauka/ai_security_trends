/**
 * D-05 / FR-18.2: visible PL<->EN switch on every page. The underlying
 * mechanism is always a plain link (?lang=pl / ?lang=en) that works with
 * JavaScript disabled — this module only intercepts the click to avoid a
 * full page reload where feasible, re-fetching translated content instead.
 */
(function () {
  'use strict';

  const toggle = document.querySelector('[data-securepress-language-toggle]');

  if (!toggle) {
    return;
  }

  const ALLOWED_LOCALES = ['pl', 'en'];

  toggle.addEventListener('click', function (event) {
    const link = event.target.closest('a[data-lang]');
    if (!link) {
      return;
    }

    const requestedLocale = link.getAttribute('data-lang');
    if (ALLOWED_LOCALES.indexOf(requestedLocale) === -1) {
      return; // SR-13.1: unrecognized values are never sent, plain navigation
              // will fall back to the site default on the server side anyway.
    }

    event.preventDefault();

    const url = new URL(window.location.href);
    url.searchParams.set('lang', requestedLocale);
    window.history.replaceState(null, '', url.toString());

    document.documentElement.setAttribute('lang', requestedLocale);
    toggle.querySelectorAll('a[data-lang]').forEach(function (a) {
      a.setAttribute('aria-current', a.getAttribute('data-lang') === requestedLocale ? 'true' : 'false');
    });

    window.dispatchEvent(new CustomEvent('securepress:locale-changed', { detail: { locale: requestedLocale } }));
  });
})();
