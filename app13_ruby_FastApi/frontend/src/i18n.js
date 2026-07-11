// D-05: a small hand-written i18n store, not a library (PLAN.md §4) — the
// surface area (a few dozen UI strings, two locales) doesn't justify
// i18next/similar. Threat/card CONTENT i18n (description_en/description_pl)
// is a separate concern, handled by `localizedDescription` calls against
// API response fields directly, not by this string table.

const STRINGS = {
  pl: {
    "nav.threats": "Zagrożenia",
    "nav.search": "Szukaj",
    "nav.matrix": "Macierz",
    "nav.about": "O aplikacji",
    "home.title": "Frameworki Bezpieczeństwa",
    "threats.title": "Zagrożenia",
    "threats.filter.severity": "Severity",
    "threats.filter.all": "Wszystkie",
    "threats.empty": "Brak wyników dla podanych filtrów.",
    "detail.overview": "Przegląd",
    "detail.attackVectors": "Wektory Ataku",
    "detail.attackSurface": "Powierzchnia Ataku",
    "detail.mitigations": "Mitigacje",
    "detail.mitigations.empty": "Brak jeszcze zdefiniowanych mitigacji dla tego zagrożenia.",
    "detail.crossReferences": "Powiązania Cross-Framework",
    "detail.crossReferences.empty": "Brak jeszcze zdefiniowanych powiązań dla tego zagrożenia.",
    "codeSample.empty": "Brak jeszcze próbek kodu dla tej mitigacji.",
    "codeSample.attackDemo.label": "ATTACK DEMO — kod podatny, nie używać w produkcji",
    "codeSample.attackDemo.reveal": "Pokaż kod (VULNERABLE)",
    "codeSample.attackDemo.confirmTitle": "Ten kod celowo demonstruje podatność.",
    "codeSample.attackDemo.confirmBody": "Potwierdź, aby go zobaczyć.",
    "codeSample.attackDemo.confirm": "Rozumiem",
    "codeSample.attackDemo.cancel": "Anuluj",
    "search.placeholder": "Szukaj zagrożeń i kart...",
    "search.empty": "Brak wyników.",
    "about.title": "O aplikacji",
    "about.frameworkFree": "Ten frontend jest celowo napisany bez frameworka JS (PLAN.md D-08) — nie jest to skrót, tylko świadoma decyzja projektowa dla porównania kursu."
  },
  en: {
    "nav.threats": "Threats",
    "nav.search": "Search",
    "nav.matrix": "Matrix",
    "nav.about": "About",
    "home.title": "Security Frameworks",
    "threats.title": "Threats",
    "threats.filter.severity": "Severity",
    "threats.filter.all": "All",
    "threats.empty": "No results for the current filters.",
    "detail.overview": "Overview",
    "detail.attackVectors": "Attack Vectors",
    "detail.attackSurface": "Attack Surface",
    "detail.mitigations": "Mitigations",
    "detail.mitigations.empty": "No mitigations defined for this threat yet.",
    "detail.crossReferences": "Cross-Framework References",
    "detail.crossReferences.empty": "No cross-references defined for this threat yet.",
    "codeSample.empty": "No code samples for this mitigation yet.",
    "codeSample.attackDemo.label": "ATTACK DEMO — vulnerable code, do not use in production",
    "codeSample.attackDemo.reveal": "Show code (VULNERABLE)",
    "codeSample.attackDemo.confirmTitle": "This code deliberately demonstrates a vulnerability.",
    "codeSample.attackDemo.confirmBody": "Confirm to view it.",
    "codeSample.attackDemo.confirm": "I understand",
    "codeSample.attackDemo.cancel": "Cancel",
    "search.placeholder": "Search threats and cards...",
    "search.empty": "No results.",
    "about.title": "About",
    "about.frameworkFree": "This frontend is deliberately written with no JS framework (PLAN.md D-08) — not a shortcut, a stated design decision for the course comparison."
  }
};

const STORAGE_KEY = "rubyguard.locale";
const listeners = new Set();

function readStoredLocale() {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored === "en" ? "en" : "pl";
  } catch {
    return "pl"; // SR-13.1-equivalent: never crash on a blocked/unavailable localStorage
  }
}

let currentLocale = readStoredLocale();

export function getLocale() {
  return currentLocale;
}

export function setLocale(locale) {
  if (locale !== "pl" && locale !== "en") return; // SR-13.1-equivalent: unknown codes are ignored
  currentLocale = locale;
  try {
    localStorage.setItem(STORAGE_KEY, locale);
  } catch {
    /* localStorage unavailable — locale still applies for this page view */
  }
  listeners.forEach((listener) => listener(locale));
}

export function onLocaleChange(listener) {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function t(key) {
  return STRINGS[currentLocale]?.[key] ?? STRINGS.pl[key] ?? key;
}

// Applies `data-i18n="key"` bindings found anywhere under `root` — the
// static-HTML nav links in index.html use this, not JS-rendered views
// (which call `t()` directly inside their own render functions).
export function applyStaticBindings(root = document) {
  root.querySelectorAll("[data-i18n]").forEach((el) => {
    el.textContent = t(el.getAttribute("data-i18n"));
  });
}
