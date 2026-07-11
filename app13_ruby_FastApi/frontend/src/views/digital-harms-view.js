import { api } from "../api-client.js";
import { getLocale } from "../i18n.js";

// US-19/D-03: this view structurally cannot render a severity badge — the
// API's `severity` field is always `null` for `edition=dbd` cards (enforced
// by the database CHECK constraint, PLAN.md §4 D-03), and this template
// simply never references `card.severity` at all, unlike card-suit-view.js.
export async function render(container) {
  container.innerHTML = "<p>Loading…</p>";
  const cards = await api.cards({ edition: "dbd" });
  const locale = getLocale();

  container.innerHTML = `
    <h1>Digital-by-Default Harms</h1>
    <p class="muted">
      Ta talia nie jest listą podatności technicznych z poziomem severity — modeluje harmy
      projektowe (wykluczenie cyfrowe, nieprzejrzyste projektowanie) w usługach publicznych,
      mapowane na OWASP A04:2021 Insecure Design.
    </p>
    <ul class="card-list">
      ${cards
        .map((card) => {
          const description = locale === "pl" && card.descriptionPl ? card.descriptionPl : card.descriptionEn;
          return `
            <li data-testid="card-row-${card.cardId}">
              <strong>${card.cardId}</strong> <span class="badge design-harm">harm projektowy</span>
              <p>${description}</p>
              ${card.owaspRefs.length ? `<p class="muted">${card.owaspRefs.join(", ")}</p>` : ""}
            </li>`;
        })
        .join("")}
    </ul>`;
}
