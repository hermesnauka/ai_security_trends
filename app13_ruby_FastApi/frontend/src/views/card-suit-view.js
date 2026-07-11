import { api } from "../api-client.js";
import { getLocale } from "../i18n.js";

// Generic, parameterized by suit OR edition — the same "one view, many
// routes" pattern every sibling's CardSuitView/CardSuitScreen uses (US-05–US-12).
export async function render(container, params) {
  const query = new URLSearchParams(window.location.search);
  const suit = query.get("suit");
  const edition = query.get("edition") || params.edition;

  container.innerHTML = "<p>Loading…</p>";
  const cards = await api.cards({ suit, edition });
  const locale = getLocale();

  container.innerHTML = `
    <h1>${suit || edition}</h1>
    <ul class="card-list">
      ${cards
        .map((card) => {
          const description = locale === "pl" && card.descriptionPl ? card.descriptionPl : card.descriptionEn;
          const severityBadge = card.severity ? `<span class="badge severity-${card.severity}">${card.severity}</span>` : "";
          return `
            <li data-testid="card-row-${card.cardId}">
              <strong>${card.cardId} (${card.value})</strong> ${severityBadge}
              <p>${description}</p>
              ${card.owaspRefs.length || card.mitreRefs.length ? `<p class="muted">${[...card.owaspRefs, ...card.mitreRefs].join(", ")}</p>` : ""}
            </li>`;
        })
        .join("")}
    </ul>`;
}
