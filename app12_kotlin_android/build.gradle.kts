// Root build file — per-module plugin versions declared here, applied `false`
// at the root and enabled in each module's own build.gradle.kts, the
// standard Android Gradle Plugin convention.
plugins {
    id("com.android.application") version "8.6.0" apply false
    id("com.android.library") version "8.6.0" apply false
    id("org.jetbrains.kotlin.android") version "2.0.20" apply false
    id("com.google.devtools.ksp") version "2.0.20-1.0.25" apply false
    id("org.jetbrains.kotlin.plugin.serialization") version "2.0.20" apply false
    // Kotlin 2.0+ moved the Compose compiler out of AGP and into its own
    // Kotlin plugin, matched to the Kotlin version above rather than to a
    // separate "Compose compiler extension version" the way Kotlin 1.9 did.
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.20" apply false
    id("io.gitlab.arturbosch.detekt") version "1.23.6" apply false
}
