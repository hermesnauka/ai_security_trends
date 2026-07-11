package com.kotlinguard.app

import androidx.compose.ui.test.assertDoesNotExist
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test

/**
 * US-03 — Szczegóły zagrożenia z mitigacjami i kodem
 * (`../../../../../user_stories+tests.md`). Adapted to the REAL screen
 * structure: code samples render inline per mitigation via
 * `CodeSamplePanel`, gated by a Material `AlertDialog` (D-08). See
 * `US01FrameworksUiTest.kt` for why this can't run here (no device/emulator).
 */
class US03ThreatDetailUiTest {
    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    private fun navigateToLlm01() {
        composeTestRule.waitUntil(timeoutMillis = 10_000) {
            composeTestRule.onAllNodesWithTag("tab-threats").fetchSemanticsNodes().isNotEmpty()
        }
        composeTestRule.onNodeWithTag("tab-threats").performClick()
        composeTestRule.waitUntil(timeoutMillis = 10_000) {
            composeTestRule.onAllNodesWithTag("threat-row-LLM01:2025").fetchSemanticsNodes().isNotEmpty()
        }
        composeTestRule.onNodeWithTag("threat-row-LLM01:2025").performClick()
    }

    /**
     * D-08: the attack-demo code body must not exist before confirming the
     * dialog, and must exist after — `LLM01:2025`'s one real mitigation
     * ("prompt-injection-defense") ships a Python attack-demo sample, the
     * language `CodeSamplePanel` defaults to.
     */
    @Test
    fun doesNotShowAttackDemoCodeBeforeConfirmation() {
        navigateToLlm01()

        composeTestRule.waitUntil(timeoutMillis = 10_000) {
            composeTestRule.onAllNodesWithTag("attack-demo-reveal-button").fetchSemanticsNodes().isNotEmpty()
        }
        composeTestRule.onNodeWithTag("attack-demo-code-body").assertDoesNotExist()

        composeTestRule.onNodeWithTag("attack-demo-reveal-button").performClick()
        composeTestRule.onNodeWithTag("attack-demo-confirm-button").performClick()

        composeTestRule.waitUntil(timeoutMillis = 10_000) {
            composeTestRule.onAllNodesWithTag("attack-demo-code-body").fetchSemanticsNodes().isNotEmpty()
        }
    }

    @Test
    fun cancellingTheDialogLeavesTheCodeHidden() {
        navigateToLlm01()
        composeTestRule.waitUntil(timeoutMillis = 10_000) {
            composeTestRule.onAllNodesWithTag("attack-demo-reveal-button").fetchSemanticsNodes().isNotEmpty()
        }
        composeTestRule.onNodeWithTag("attack-demo-reveal-button").performClick()
        composeTestRule.onNodeWithText("Anuluj / Cancel").performClick()

        composeTestRule.onNodeWithTag("attack-demo-code-body").assertDoesNotExist()
    }
}
