// @ts-check
import { test, expect } from "@playwright/test";

// US-03 — D-09 attack-demo gate. See us01-frameworks.spec.js for why this
// can't run here (no docker-compose stack in this environment).
test("does not show attack-demo code before confirmation", async ({ page }) => {
  await page.goto("/threats/LLM01:2025");

  const revealButton = page.getByTestId("attack-demo-reveal-button").first();
  await expect(revealButton).toBeVisible();
  await expect(page.getByTestId("attack-demo-code-body").first()).toBeHidden();

  await revealButton.click();
  await page.getByTestId("attack-demo-confirm-button").click();

  await expect(page.getByTestId("attack-demo-code-body").first()).toBeVisible();
});

test("cancelling the dialog leaves the code hidden", async ({ page }) => {
  await page.goto("/threats/LLM01:2025");
  await page.getByTestId("attack-demo-reveal-button").first().click();
  await page.getByText("Anuluj").click();
  await expect(page.getByTestId("attack-demo-code-body").first()).toBeHidden();
});
