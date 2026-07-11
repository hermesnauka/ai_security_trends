import { route, initRouter, render } from "./router.js";
import { getLocale, setLocale, applyStaticBindings, onLocaleChange } from "./i18n.js";
import * as indexView from "./views/index-view.js";
import * as threatBrowserView from "./views/threat-browser-view.js";
import * as threatDetailView from "./views/threat-detail-view.js";
import * as cardSuitView from "./views/card-suit-view.js";
import * as digitalHarmsView from "./views/digital-harms-view.js";
import * as matrixView from "./views/matrix-view.js";
import * as searchView from "./views/search-view.js";
import * as loginView from "./views/login-view.js";
import * as aboutView from "./views/about-view.js";

route("/", indexView);
route("/threats", threatBrowserView);
route("/threats/:code", threatDetailView);
route("/cards/:edition", cardSuitView);
route("/digital-harms", digitalHarmsView);
route("/matrix", matrixView);
route("/search", searchView);
route("/login", loginView);
route("/about", aboutView);

function wireLanguageToggle() {
  const toggle = document.getElementById("lang-toggle");
  const buttons = toggle.querySelectorAll("button[data-locale]");

  function syncActiveButton() {
    const current = getLocale();
    buttons.forEach((b) => b.classList.toggle("active", b.dataset.locale === current));
  }

  toggle.addEventListener("click", (event) => {
    const button = event.target.closest("button[data-locale]");
    if (!button) return;
    setLocale(button.dataset.locale);
  });

  onLocaleChange(() => {
    syncActiveButton();
    applyStaticBindings();
    render(); // instant client-side re-render, no page reload (D-05)
  });

  syncActiveButton();
}

document.addEventListener("DOMContentLoaded", () => {
  applyStaticBindings();
  wireLanguageToggle();
  initRouter();
  render();
});
