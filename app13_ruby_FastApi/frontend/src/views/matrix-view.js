import { api } from "../api-client.js";
import { t } from "../i18n.js";

export async function render(container) {
  container.innerHTML = `<h1>${t("nav.matrix")}</h1><div id="llm-matrix"></div><div id="stride-heatmap"></div>`;

  const [llmMatrix, heatmap] = await Promise.all([api.llmMatrix(), api.strideHeatmap()]);

  container.querySelector("#llm-matrix").innerHTML = `
    <h2>LLM ↔ MITRE ATLAS</h2>
    <table>
      <thead><tr><th>Threat</th><th>Cards</th></tr></thead>
      <tbody>
        ${llmMatrix.rows
          .map((row) => `<tr><td>${row.threatCode} — ${row.threatTitle}</td><td>${row.cardIds.join(", ") || "—"}</td></tr>`)
          .join("")}
      </tbody>
    </table>`;

  container.querySelector("#stride-heatmap").innerHTML = `
    <h2>STRIDE Heatmap</h2>
    <ul>
      ${Object.entries(heatmap.categoryCounts)
        .map(([category, count]) => `<li>${category}: ${count}</li>`)
        .join("")}
    </ul>`;
}
