package com.kotlinguard.ui.viewmodel

import com.kotlinguard.data.model.CardKind
import com.kotlinguard.data.model.CornucopiaCardEntity
import com.kotlinguard.data.model.Severity
import com.kotlinguard.ui.support.FakeCardRepository
import com.kotlinguard.ui.support.MainDispatcherRule
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class CardSuitViewModelTest {
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private val llm2 = CornucopiaCardEntity(
        cardId = "LLM2", suitCode = "LLM", suitName = "Large Language Models", edition = "companion",
        value = "2", kind = CardKind.TechnicalThreat(Severity.HIGH),
        descriptionEn = "LLM2 description.", descriptionPl = "", miscNote = null, sourceUrl = null,
        owaspRefs = listOf("LLM10:2025"), mitreRefs = emptyList(), contentSha256 = "deadbeef", isCritical = false
    )
    private val sco2 = CornucopiaCardEntity(
        cardId = "SCO2", suitCode = "SCO", suitName = "Socioeconomic", edition = "dbd",
        value = "2", kind = CardKind.DesignHarm,
        descriptionEn = "SCO2 description.", descriptionPl = "", miscNote = null, sourceUrl = null,
        owaspRefs = emptyList(), mitreRefs = emptyList(), contentSha256 = "cafebabe", isCritical = false
    )

    @Test
    fun loadSuitReturnsOnlyThatSuitsCards() = runTest(mainDispatcherRule.testDispatcher) {
        val viewModel = CardSuitViewModel(FakeCardRepository(listOf(llm2, sco2)))
        viewModel.loadSuit("LLM")
        assertEquals(listOf("LLM2"), viewModel.cards.map { it.cardId })
    }

    @Test
    fun loadEditionReturnsOnlyThatEditionsCards() = runTest(mainDispatcherRule.testDispatcher) {
        val viewModel = CardSuitViewModel(FakeCardRepository(listOf(llm2, sco2)))
        viewModel.loadEdition("dbd")
        assertEquals(listOf("SCO2"), viewModel.cards.map { it.cardId })
        assertTrue(viewModel.cards.all { it.kind.isDesignHarm })
    }
}
