package com.kotlinguard.data.model

// PLAN.md §5.1 — core enums shared across the Room entity model.

enum class Severity { CRITICAL, HIGH, MEDIUM, LOW, INFO }
enum class StrideCategory { S, T, R, I, D, E }
enum class SampleType { ATTACK_DEMO, DEFENSE }
enum class CodeLanguage { PYTHON, JAVA, GO, SCALA, LUA }
enum class MitigationType { PREVENTIVE, DETECTIVE, CORRECTIVE, COMPENSATING }
enum class Effort { LOW, MEDIUM, HIGH }
enum class Effectiveness { PARTIAL, SIGNIFICANT, FULL }
enum class RelationshipType { EQUIVALENT, RELATED, PARENT_CHILD, MAPS_TO }

enum class AppLocale(val code: String) {
    POLISH("pl"),
    ENGLISH("en");

    companion object {
        fun fromCode(code: String): AppLocale? = entries.find { it.code == code }
    }
}
