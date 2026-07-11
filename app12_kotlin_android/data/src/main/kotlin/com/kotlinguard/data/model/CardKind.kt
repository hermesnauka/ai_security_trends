package com.kotlinguard.data.model

import kotlinx.serialization.Serializable

/**
 * D-03: an unconditional compile-time guarantee, the strongest tier in this
 * series alongside Rust/Haskell/Swift — Kotlin's exhaustive `when` over a
 * `sealed interface` is a hard compiler error with no configuration flag
 * able to disable it. It is structurally impossible to construct
 * `DesignHarm` carrying a `Severity` — there is no such constructor.
 *
 * Stored on `CornucopiaCardEntity` via a Room `@TypeConverter`
 * (`db/Converters.kt`) that serializes this to a small JSON string — Room
 * has no native column type for a sealed interface, so encoding to/from a
 * single TEXT column is how PLAN.md §5.4's "one `kind` field" ergonomic is
 * actually achieved in Room, rather than splitting it into two nullable
 * columns.
 */
@Serializable
sealed interface CardKind {
    @Serializable
    data class TechnicalThreat(val severity: Severity) : CardKind

    @Serializable
    data object DesignHarm : CardKind

    /** FR-19.2(b) equivalent: the only way to read a severity at all. */
    fun severityOrNull(): Severity? = when (this) {
        is TechnicalThreat -> severity
        is DesignHarm -> null
    }

    val isDesignHarm: Boolean
        get() = when (this) {
            is TechnicalThreat -> false
            is DesignHarm -> true
        }
}
