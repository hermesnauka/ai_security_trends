import { api } from "../api-client.js";
import { t } from "../i18n.js";

export async function render(container) {
  container.innerHTML = `<h1>${t("home.title")}</h1><ul class="tile-list" id="frameworks"></ul>`;
  const list = container.querySelector("#frameworks");

  let frameworks = [];
  try {
    frameworks = await api.frameworks();
  } catch (err) {
    container.innerHTML += `<p class="error">${err.message}</p>`;
    return;
  }

  list.innerHTML = frameworks
    .map(
      (framework) => `
        <li>
          <a href="/threats?frameworkCode=${encodeURIComponent(framework.code)}" data-nav
             data-testid="framework-row-${framework.code}">
            <strong>${framework.name}</strong>
            <span>${framework.code} · v${framework.version}</span>
          </a>
        </li>`
    )
    .join("");
}
