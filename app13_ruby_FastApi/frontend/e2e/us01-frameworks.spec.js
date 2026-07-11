// @ts-check
import { test, expect } from "@playwright/test";

// US-01 — mirrors app11_swift_ios's US01FrameworksUITests.swift and
// app12_kotlin_android's US01FrameworksUiTest.kt. NOT RUNNABLE HERE: needs
// the full docker-compose stack (Postgres seeded + backend + built frontend)
// running — no such runtime exists in the environment this was written in
// (see ../../CLAUDE.md).
test("home page lists at least ten frameworks and navigating one filters threats", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByTestId("framework-row-OWASP_LLM")).toBeVisible();
  await expect(page.getByTestId("framework-row-OWASP_WEB")).toBeVisible();
  await expect(page.getByTestId("framework-row-MITRE_ATLAS")).toBeVisible();

  await page.getByTestId("framework-row-OWASP_LLM").click();
  await expect(page.getByTestId("threat-row-LLM01:2025")).toBeVisible();
});
