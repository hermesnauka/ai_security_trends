package com.kotlinguard.ui.locale

import androidx.compose.runtime.Stable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.kotlinguard.data.model.AppLocale

/**
 * D-05-equivalent: an in-app language switch independent of the device's
 * system language, layered on top of (not a replacement for) Android's own
 * resource-qualifier i18n (`values-pl/strings.xml`) — the same "use the
 * platform's mature i18n system rather than reinventing it" decision app09
 * made with WordPress's gettext and app11 made with Apple's String Catalog,
 * applied here to Android's resource system.
 *
 * Scope note, matching app11's D-05 caveat: every model's
 * `localizedDescription(locale)` (ThreatEntity/CornucopiaCardEntity) already
 * switches CONTENT correctly via this holder. UI-CHROME strings (the ones in
 * `strings.xml`/`values-pl/strings.xml`) still follow the device's system
 * locale, not this in-app toggle, because Android has no equivalent of
 * runtime `Bundle.setLanguage` swizzling without an `AppCompatDelegate`
 * per-app-locale API wired into `AndroidManifest.xml` — not done yet.
 */
@Stable
class LocaleManager(initialLocale: AppLocale = AppLocale.POLISH) {
    var currentLocale by mutableStateOf(initialLocale)
        private set

    fun setLocale(locale: AppLocale) {
        currentLocale = locale
    }

    /** SR-13.1-equivalent: only "pl"/"en" are ever accepted; anything else is ignored. */
    fun setLocale(rawValue: String) {
        AppLocale.fromCode(rawValue)?.let { setLocale(it) }
    }
}

val LocalLocaleManager = compositionLocalOf<LocaleManager> {
    error("LocaleManager not provided — wrap the composition root in CompositionLocalProvider(LocalLocaleManager provides ...)")
}
