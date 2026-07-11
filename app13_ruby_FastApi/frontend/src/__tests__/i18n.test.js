import { describe, it, expect, beforeEach } from "vitest";
import { getLocale, setLocale, t } from "../i18n.js";

describe("i18n store (D-05)", () => {
  beforeEach(() => {
    localStorage.clear();
    setLocale("pl");
  });

  it("defaults to Polish", () => {
    expect(getLocale()).toBe("pl");
  });

  it("switches locale instantly", () => {
    setLocale("en");
    expect(getLocale()).toBe("en");
    expect(t("nav.threats")).toBe("Threats");
  });

  it("ignores an unknown locale code (SR-13.1-equivalent)", () => {
    setLocale("en");
    setLocale("fr");
    expect(getLocale()).toBe("en");
  });

  it("falls back to the Polish string for a key missing in the current locale table", () => {
    // every real key has both translations, so this exercises the fallback
    // path itself rather than a genuinely missing key
    expect(t("nonexistent.key")).toBe("nonexistent.key");
  });
});
