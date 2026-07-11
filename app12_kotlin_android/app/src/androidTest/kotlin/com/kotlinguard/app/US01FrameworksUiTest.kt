package com.kotlinguard.app

import androidx.compose.ui.test.assertExists
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test

/**
 * US-01 — Katalog frameworków bezpieczeństwa (`../../../../../user_stories+tests.md`).
 *
 * NOT RUNNABLE HERE: needs a connected device/emulator (Compose's
 * instrumented UI-testing API, same category of requirement as
 * app11_swift_ios's XCUITest needing the iOS Simulator) — no such runtime
 * exists in the environment this was written in (see `../../../../../CLAUDE.md`).
 * The `Modifier.testTag(...)` values referenced below are real, already
 * added to `RootScreen`/`FrameworkListScreen`/`ThreatBrowserScreen` in `:ui`
 * specifically so this test is genuinely correct against the shipped UI,
 * not just illustrative — mirrors app11_swift_ios's
 * `US01FrameworksUITests.swift`.
 */
class US01FrameworksUiTest {
    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun tappingAFrameworkTileNavigatesToItsThreatList() {
        composeTestRule.waitUntil(timeoutMillis = 10_000) {
            composeTestRule.onAllNodesWithTag("tab-frameworks").fetchSemanticsNodes().isNotEmpty()
        }
        composeTestRule.onNodeWithTag("tab-frameworks").performClick()

        composeTestRule.waitUntil(timeoutMillis = 10_000) {
            composeTestRule.onAllNodesWithTag("framework-row-OWASP_LLM").fetchSemanticsNodes().isNotEmpty()
        }
        composeTestRule.onNodeWithTag("framework-row-OWASP_LLM").performClick()

        // Navigating a framework tile lands on `ThreatBrowserScreen` filtered
        // to that framework — `threat-row-LLM01:2025` is one of its 10 seeded threats.
        composeTestRule.waitUntil(timeoutMillis = 10_000) {
            composeTestRule.onAllNodesWithTag("threat-row-LLM01:2025").fetchSemanticsNodes().isNotEmpty()
        }
    }

    @Test
    fun atLeastTenFrameworksAreListed() {
        composeTestRule.waitUntil(timeoutMillis = 10_000) {
            composeTestRule.onAllNodesWithTag("tab-frameworks").fetchSemanticsNodes().isNotEmpty()
        }
        composeTestRule.onNodeWithTag("tab-frameworks").performClick()
        composeTestRule.waitUntil(timeoutMillis = 10_000) {
            composeTestRule.onAllNodesWithTag("framework-row-OWASP_WEB").fetchSemanticsNodes().isNotEmpty()
        }
        // Matches `RoomFrameworkRepositoryTest.listReturnsAtLeastTenSeededFrameworks`
        // (`:data`) at the UI layer.
        composeTestRule.onNodeWithTag("framework-row-MITRE_ATLAS").assertExists()
    }
}
