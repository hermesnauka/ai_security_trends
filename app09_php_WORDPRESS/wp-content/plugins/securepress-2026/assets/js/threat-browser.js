/**
 * Progressive enhancement for archive-threat.php's filter panel (FR-02.4).
 * The page already works via a full form submission with no JS at all —
 * this module only makes filtering faster once it loads, debouncing input
 * and re-fetching via securepress/v1/threats instead of a full navigation.
 */
(function () {
  'use strict';

  if (typeof window.securePressConfig === 'undefined') {
    return;
  }

  const DEBOUNCE_MS = 300;
  const form = document.querySelector('.securepress-filter-panel');
  const resultsList = document.getElementById('threat-results');

  if (!form || !resultsList) {
    return;
  }

  let debounceTimer = null;

  function buildQuery() {
    const formData = new FormData(form);
    const params = new URLSearchParams();
    for (const [key, value] of formData.entries()) {
      if (value !== '') {
        params.set(key, String(value));
      }
    }
    return params;
  }

  function escapeHtml(value) {
    const div = document.createElement('div');
    div.textContent = value;
    return div.innerHTML;
  }

  function renderResults(threats) {
    if (threats.length === 0) {
      resultsList.innerHTML =
        '<li>' + escapeHtml(securePressConfig.strings && securePressConfig.strings.noResults ? securePressConfig.strings.noResults : 'Brak wynikow.') + '</li>';
      return;
    }

    resultsList.innerHTML = threats
      .map(function (threat) {
        const href = '/threats/' + encodeURIComponent(threat.id) + '/';
        return (
          '<li class="securepress-threat-card" data-testid="threat-result">' +
          '<a href="' + href + '">' +
          '<span class="securepress-threat-code">' + escapeHtml(threat.code) + '</span> ' +
          '<span class="securepress-threat-title">' + escapeHtml(threat.title) + '</span> ' +
          '<span class="securepress-severity-badge securepress-severity-' + escapeHtml(threat.severity) + '">' +
          escapeHtml(threat.severity) +
          '</span></a></li>'
        );
      })
      .join('');
  }

  function fetchAndRender() {
    const params = buildQuery();
    const url = securePressConfig.restUrl + 'threats?' + params.toString();

    // Progressive enhancement: keep the URL bar in sync so a refresh/share
    // reproduces the same filtered view via the no-JS server-rendered path.
    const pageUrl = new URL(window.location.href);
    pageUrl.search = params.toString();
    window.history.replaceState(null, '', pageUrl.toString());

    fetch(url, { headers: { Accept: 'application/json' } })
      .then(function (response) {
        if (!response.ok) {
          throw new Error('securepress: request failed with ' + response.status);
        }
        return response.json();
      })
      .then(function (body) {
        renderResults(body.content || []);
      })
      .catch(function () {
        // Network/API failure: leave the last-rendered (server- or client-
        // rendered) result set in place rather than showing a broken state.
      });
  }

  form.addEventListener('submit', function (event) {
    event.preventDefault();
    fetchAndRender();
  });

  form.querySelectorAll('input, select').forEach(function (field) {
    field.addEventListener('input', function () {
      window.clearTimeout(debounceTimer);
      debounceTimer = window.setTimeout(fetchAndRender, DEBOUNCE_MS);
    });
  });
})();
