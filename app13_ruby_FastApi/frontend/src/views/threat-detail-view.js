import { api } from "../api-client.js";
import { t, getLocale } from "../i18n.js";

// D-09: every code sample ships read-only, bundled, never executed. The
// attack-demo confirmation is a native <dialog> element — this frontend's
// equivalent of app09's <details> reveal, app11's .confirmationDialog, and
// app12's AlertDialog.
function renderCodeSamplePanel(mitigationSlug, codeSamples) {
  if (codeSamples.length === 0) return `<p class="muted">${t("codeSample.empty")}</p>`;

  const languages = [...new Set(codeSamples.map((s) => s.language))].sort();
  const dialogId = `attack-demo-dialog-${mitigationSlug}`;

  const languageTabs = languages
    .map((lang, i) => `<button data-lang="${lang}" class="${i === 0 ? "active" : ""}">${lang.toUpperCase()}</button>`)
    .join("");

  const samplesByLanguage = languages
    .map((lang) => {
      const samples = codeSamples.filter((s) => s.language === lang);
      const blocks = samples
        .map((sample) => {
          if (sample.sampleType === "defense") {
            return renderCodeBlock(sample);
          }
          return `
            <div class="attack-demo-block" data-sample-id="${sample.language}-${sample.sampleType}">
              <p class="attack-demo-label">${t("codeSample.attackDemo.label")}</p>
              <div class="attack-demo-hidden">
                <button class="attack-demo-reveal-button" data-testid="attack-demo-reveal-button">
                  ${t("codeSample.attackDemo.reveal")}
                </button>
              </div>
              <div class="attack-demo-revealed" hidden data-testid="attack-demo-code-body">
                ${renderCodeBlock(sample)}
              </div>
            </div>`;
        })
        .join("");
      return `<div class="lang-panel" data-lang="${lang}" ${lang === languages[0] ? "" : "hidden"}>${blocks}</div>`;
    })
    .join("");

  return `
    <div class="code-sample-panel">
      <div class="lang-tabs">${languageTabs}</div>
      ${samplesByLanguage}
      <dialog id="${dialogId}" class="attack-demo-dialog">
        <p>${t("codeSample.attackDemo.confirmTitle")}</p>
        <p>${t("codeSample.attackDemo.confirmBody")}</p>
        <button data-action="confirm" data-testid="attack-demo-confirm-button">${t("codeSample.attackDemo.confirm")}</button>
        <button data-action="cancel">${t("codeSample.attackDemo.cancel")}</button>
      </dialog>
    </div>`;
}

function renderCodeBlock(sample) {
  return `
    <div class="code-block">
      <p class="code-title">${sample.title}</p>
      <pre><code>${escapeHtml(sample.code)}</code></pre>
      <p class="muted">${sample.frameworkHint} — ${sample.versionNote}</p>
    </div>`;
}

function escapeHtml(str) {
  return str.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}

function wireCodeSamplePanel(root) {
  root.querySelectorAll(".code-sample-panel").forEach((panel) => {
    const dialog = panel.querySelector("dialog");
    let pendingBlock = null;

    panel.querySelectorAll(".lang-tabs button").forEach((tab) => {
      tab.addEventListener("click", () => {
        panel.querySelectorAll(".lang-tabs button").forEach((b) => b.classList.toggle("active", b === tab));
        panel.querySelectorAll(".lang-panel").forEach((p) => {
          p.hidden = p.dataset.lang !== tab.dataset.lang;
        });
      });
    });

    panel.querySelectorAll(".attack-demo-reveal-button").forEach((button) => {
      button.addEventListener("click", () => {
        pendingBlock = button.closest(".attack-demo-block");
        dialog.showModal();
      });
    });

    dialog.querySelector('[data-action="confirm"]').addEventListener("click", () => {
      if (pendingBlock) {
        pendingBlock.querySelector(".attack-demo-hidden").hidden = true;
        pendingBlock.querySelector(".attack-demo-revealed").hidden = false;
      }
      dialog.close();
      pendingBlock = null;
    });

    dialog.querySelector('[data-action="cancel"]').addEventListener("click", () => {
      dialog.close();
      pendingBlock = null;
    });
  });
}

export async function render(container, params) {
  const threatCode = decodeURIComponent(params.code);
  container.innerHTML = "<p>Loading…</p>";

  let threat;
  try {
    threat = await api.threat(threatCode);
  } catch (err) {
    container.innerHTML = `<p class="error">${err.message}</p>`;
    return;
  }

  const locale = getLocale();
  const description = locale === "pl" && threat.descriptionPl ? threat.descriptionPl : threat.descriptionEn;

  const mitigationsHtml = threat.mitigations.length
    ? threat.mitigations
        .map(
          (m) => `
        <div class="mitigation">
          <h3>${m.title}</h3>
          <p>${m.description}</p>
          <p class="muted">${m.mitigationType} · ${m.effort} · ${m.effectiveness}</p>
          ${renderCodeSamplePanel(m.slug, m.codeSamples)}
        </div>`
        )
        .join("")
    : `<p class="muted">${t("detail.mitigations.empty")}</p>`;

  const crossRefsHtml = threat.crossReferences.length
    ? threat.crossReferences
        .map((r) => `<div><strong>${r.relationshipType.toUpperCase()} — ${r.targetThreatCode}</strong>: ${r.targetThreatTitle}<p>${r.description}</p></div>`)
        .join("")
    : `<p class="muted">${t("detail.crossReferences.empty")}</p>`;

  container.innerHTML = `
    <div class="threat-detail">
      <header>
        <span class="code">${threat.code}</span>
        <h1>${threat.title}</h1>
        <span class="badge severity-${threat.severity}">${threat.severity}</span>
      </header>
      <section><h2>${t("detail.overview")}</h2><p>${description}</p></section>
      <section>
        <h2>${t("detail.attackVectors")}</h2>
        <p>${threat.attackVector}</p>
        <h3>${t("detail.attackSurface")}</h3>
        <p>${threat.attackSurface}</p>
      </section>
      <section><h2>${t("detail.mitigations")}</h2>${mitigationsHtml}</section>
      <section><h2>${t("detail.crossReferences")}</h2>${crossRefsHtml}</section>
    </div>`;

  wireCodeSamplePanel(container);
}
