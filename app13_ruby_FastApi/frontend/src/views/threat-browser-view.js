import { api } from "../api-client.js";
import { t } from "../i18n.js";

const SEVERITIES = ["critical", "high", "medium", "low", "info"];

export async function render(container) {
  const query = new URLSearchParams(window.location.search);
  const frameworkCode = query.get("frameworkCode") || "";
  let selectedSeverity = query.get("severity") || "";
  let searchText = query.get("q") || "";
  let debounceTimer = null;

  container.innerHTML = `
    <h1>${t("threats.title")}</h1>
    <input type="search" id="threat-search" placeholder="${t("search.placeholder")}" value="${searchText}" />
    <div class="chip-row" id="severity-chips">
      <button data-severity="" class="${selectedSeverity === "" ? "active" : ""}">${t("threats.filter.all")}</button>
      ${SEVERITIES.map((s) => `<button data-severity="${s}" class="${selectedSeverity === s ? "active" : ""}">${s}</button>`).join("")}
    </div>
    <ul class="threat-list" id="threat-list"></ul>
  `;

  const list = container.querySelector("#threat-list");
  const searchInput = container.querySelector("#threat-search");
  const chips = container.querySelector("#severity-chips");

  async function load() {
    let body;
    try {
      body = await api.threats({ frameworkCode, severity: selectedSeverity, q: searchText, size: 50 });
    } catch (err) {
      list.innerHTML = `<li class="error">${err.message}</li>`;
      return;
    }

    if (body.content.length === 0) {
      list.innerHTML = `<li>${t("threats.empty")}</li>`;
      return;
    }

    list.innerHTML = body.content
      .map(
        (threat) => `
          <li>
            <a href="/threats/${encodeURIComponent(threat.code)}" data-nav data-testid="threat-row-${threat.code}">
              <span class="badge severity-${threat.severity}">${threat.severity}</span>
              <span class="code">${threat.code}</span>
              <span class="title">${threat.title}</span>
            </a>
          </li>`
      )
      .join("");
  }

  // FR-02.4-equivalent: debounce free-text search at ~300ms — the same
  // interval every sibling's threat-browser search debounces at.
  searchInput.addEventListener("input", () => {
    searchText = searchInput.value;
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(load, 300);
  });

  chips.addEventListener("click", (event) => {
    const button = event.target.closest("button[data-severity]");
    if (!button) return;
    selectedSeverity = button.dataset.severity;
    chips.querySelectorAll("button").forEach((b) => b.classList.toggle("active", b === button));
    load(); // severity applies immediately — no debounce, unlike free-text search
  });

  await load();
}
