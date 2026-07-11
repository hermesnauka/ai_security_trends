import { t } from "../i18n.js";

export function render(container) {
  container.innerHTML = `
    <h1>${t("about.title")}</h1>
    <p>RubyGuard 2026 — Ruby (Grape) backend + a framework-free vanilla JS frontend.</p>
    <p>${t("about.frameworkFree")}</p>
  `;
}
