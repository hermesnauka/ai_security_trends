import { api } from "../api-client.js";
import { t, getLocale } from "../i18n.js";

export async function render(container) {
  container.innerHTML = `
    <h1>${t("nav.search")}</h1>
    <input type="search" id="search-input" placeholder="${t("search.placeholder")}" data-testid="search-input" />
    <ul id="search-results"></ul>
  `;

  const input = container.querySelector("#search-input");
  const results = container.querySelector("#search-results");
  let debounceTimer = null;

  input.addEventListener("input", () => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(async () => {
      const q = input.value.trim();
      if (!q) {
        results.innerHTML = "";
        return;
      }
      const items = await api.search(q, getLocale());
      results.innerHTML = items.length
        ? items
            .map(
              (item) => `
              <li>
                <a href="${item.kind === "threat" ? `/threats/${encodeURIComponent(item.code)}` : "#"}" data-nav>
                  <strong>${item.title}</strong> <span class="muted">(${item.kind})</span>
                  <p>${item.excerpt}</p>
                </a>
              </li>`
            )
            .join("")
        : `<li>${t("search.empty")}</li>`;
    }, 300);
  });
}
