/**
 * FR-17.3/17.4: progressive enhancement over the plain REST link in
 * archive-threat.php. Without this script, clicking the link navigates to
 * the REST endpoint and shows raw {jobId, statusUrl} JSON — functional, not
 * seamless. With it, the click is intercepted, the job is polled, and a
 * download link is inserted in place once the export completes.
 */
(function () {
  'use strict';

  const POLL_INTERVAL_MS = 1500;
  const MAX_POLLS = 40;

  document.querySelectorAll('[data-testid="export-panel"]').forEach(function (panel) {
    const trigger = panel.querySelector('[data-testid="export-trigger"]');
    const statusEl = panel.querySelector('[data-testid="export-status"]');
    const exportUrl = panel.dataset.exportUrl;

    if (!trigger || !statusEl || !exportUrl) {
      return;
    }

    trigger.addEventListener('click', function (event) {
      event.preventDefault();
      statusEl.textContent = '…';

      fetch(exportUrl, { headers: { Accept: 'application/json' } })
        .then(function (response) {
          return response.json();
        })
        .then(function (body) {
          if (!body.statusUrl) {
            statusEl.textContent = 'Error';
            return;
          }
          poll(body.statusUrl, 0);
        })
        .catch(function () {
          statusEl.textContent = 'Error';
        });
    });

    function poll(statusUrl, attempt) {
      if (attempt >= MAX_POLLS) {
        statusEl.textContent = 'Timed out';
        return;
      }

      fetch(statusUrl, { headers: { Accept: 'application/json' } })
        .then(function (response) {
          return response.json();
        })
        .then(function (body) {
          if (body.status === 'completed' && body.downloadUrl) {
            statusEl.innerHTML = '';
            const link = document.createElement('a');
            link.href = body.downloadUrl;
            link.textContent = 'Pobierz CSV';
            statusEl.appendChild(link);
            return;
          }
          if (body.status === 'failed') {
            statusEl.textContent = 'Failed';
            return;
          }
          statusEl.textContent = body.status || '…';
          window.setTimeout(function () {
            poll(statusUrl, attempt + 1);
          }, POLL_INTERVAL_MS);
        })
        .catch(function () {
          statusEl.textContent = 'Error';
        });
    }
  });
})();
