package com.kotlinguard.ui.locale

import com.kotlinguard.data.model.AppLocale
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * D-05: `LocaleManager` tracks only the in-app CONTENT locale — see the
 * scope note in the source file for what it deliberately does NOT do
 * (UI-chrome resource-qualifier switching). Compose Runtime's snapshot state
 * (`mutableStateOf`) is plain-JVM testable — no Robolectric needed here
 * either.
 */
class LocaleManagerTest {
    @Test
    fun defaultsToPolish() {
        val manager = LocaleManager()
        assertEquals(AppLocale.POLISH, manager.currentLocale)
    }

    @Test
    fun setLocaleChangesTheCurrentLocale() {
        val manager = LocaleManager()
        manager.setLocale(AppLocale.ENGLISH)
        assertEquals(AppLocale.ENGLISH, manager.currentLocale)
    }

    @Test
    fun setLocaleFromRawValueAcceptsKnownCodes() {
        val manager = LocaleManager(AppLocale.POLISH)
        manager.setLocale("en")
        assertEquals(AppLocale.ENGLISH, manager.currentLocale)
    }

    /** SR-13.1-equivalent: an unrecognized raw value must fall back to the current locale. */
    @Test
    fun setLocaleFromRawValueIgnoresUnknownCodes() {
        val manager = LocaleManager(AppLocale.ENGLISH)
        manager.setLocale("fr")
        assertEquals(AppLocale.ENGLISH, manager.currentLocale)
    }
}
