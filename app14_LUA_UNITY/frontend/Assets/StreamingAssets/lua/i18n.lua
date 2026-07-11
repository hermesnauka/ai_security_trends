-- D-05: a hand-written i18n store, mirroring app13_ruby_FastApi's i18n.js —
-- loaded independently from the backend's own i18n error-message table
-- (PLAN.md D-05). PL default, instant switch, no scene reload needed.
-- NFR-06: every key below MUST exist in both locales — enforced by
-- Tests/Lua/spec/i18n_spec.lua diffing the two tables' key sets.

local STRINGS = {
  pl = {
    ["nav.threats"] = "Zagrożenia",
    ["nav.cards"] = "Karty",
    ["nav.game"] = "Gra",
    ["nav.settings"] = "Ustawienia",
    ["login.title"] = "Logowanie",
    ["login.username"] = "Nazwa użytkownika",
    ["login.password"] = "Hasło",
    ["login.submit"] = "Zaloguj",
    ["login.error"] = "Nieprawidłowa nazwa użytkownika lub hasło.",
    ["threats.title"] = "Zagrożenia",
    ["threats.filter.severity"] = "Poziom istotności",
    ["threats.filter.all"] = "Wszystkie",
    ["threats.empty"] = "Brak wyników dla podanych filtrów.",
    ["detail.overview"] = "Przegląd",
    ["detail.attackVectors"] = "Wektory ataku",
    ["detail.mitigations"] = "Mitigacje",
    ["codeSample.attackDemo.label"] = "ATTACK DEMO — kod podatny, nie używać w produkcji",
    ["codeSample.attackDemo.reveal"] = "Pokaż kod (PODATNY)",
    ["codeSample.attackDemo.confirmTitle"] = "Ten kod celowo demonstruje podatność.",
    ["codeSample.attackDemo.confirm"] = "Rozumiem",
    ["codeSample.attackDemo.cancel"] = "Anuluj",
    ["game.mode.regular"] = "Tryb Regularny",
    ["game.mode.shiftLeft"] = "Tryb Shift Left",
    ["game.mode.workshop"] = "Warsztat Modelowania Zagrożeń",
    ["game.reputation"] = "Reputacja",
    ["game.turn"] = "Tura",
    ["game.victory"] = "Zwycięstwo!",
    ["game.defeat"] = "Porażka."
  },
  en = {
    ["nav.threats"] = "Threats",
    ["nav.cards"] = "Cards",
    ["nav.game"] = "Game",
    ["nav.settings"] = "Settings",
    ["login.title"] = "Login",
    ["login.username"] = "Username",
    ["login.password"] = "Password",
    ["login.submit"] = "Log in",
    ["login.error"] = "Invalid username or password.",
    ["threats.title"] = "Threats",
    ["threats.filter.severity"] = "Severity",
    ["threats.filter.all"] = "All",
    ["threats.empty"] = "No results for the current filters.",
    ["detail.overview"] = "Overview",
    ["detail.attackVectors"] = "Attack Vectors",
    ["detail.mitigations"] = "Mitigations",
    ["codeSample.attackDemo.label"] = "ATTACK DEMO — vulnerable code, do not use in production",
    ["codeSample.attackDemo.reveal"] = "Show code (VULNERABLE)",
    ["codeSample.attackDemo.confirmTitle"] = "This code deliberately demonstrates a vulnerability.",
    ["codeSample.attackDemo.confirm"] = "I understand",
    ["codeSample.attackDemo.cancel"] = "Cancel",
    ["game.mode.regular"] = "Regular Mode",
    ["game.mode.shiftLeft"] = "Shift Left Mode",
    ["game.mode.workshop"] = "Threat Modeling Workshop",
    ["game.reputation"] = "Reputation",
    ["game.turn"] = "Turn",
    ["game.victory"] = "Victory!",
    ["game.defeat"] = "Defeat."
  }
}

local i18n = {}
local current_locale = "pl"
local listeners = {}

function i18n.get_locale()
  return current_locale
end

function i18n.set_locale(locale)
  if locale ~= "pl" and locale ~= "en" then return end -- unknown codes are ignored
  current_locale = locale
  for _, listener in ipairs(listeners) do listener(locale) end
end

function i18n.on_locale_change(listener)
  table.insert(listeners, listener)
end

function i18n.t(key)
  local table_for_locale = STRINGS[current_locale] or STRINGS.pl
  return table_for_locale[key] or STRINGS.pl[key] or key
end

-- Test-only accessor (Tests/Lua/spec/i18n_spec.lua) — not called by any
-- gameplay code.
function i18n._key_set(locale)
  local keys = {}
  for k in pairs(STRINGS[locale] or {}) do keys[k] = true end
  return keys
end

return i18n
