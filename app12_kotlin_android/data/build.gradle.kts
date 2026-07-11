plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("com.google.devtools.ksp")
    id("org.jetbrains.kotlin.plugin.serialization")
}

android {
    namespace = "com.kotlinguard.data"
    compileSdk = 35

    defaultConfig {
        minSdk = 26 // Android 8.0 — matches app11_swift_ios's iOS 17.0+ modernity bar
        consumerProguardFiles("consumer-rules.pro")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // Room fundamentally needs an Android runtime (unlike SwiftData, a pure
    // Swift/Foundation library app11_swift_ios's equivalent tests run under
    // plain `swift test`) — `isIncludeAndroidResources` is required for
    // Robolectric to resolve the module's manifest/resources from a plain
    // JVM unit test, no emulator/device involved.
    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            isReturnDefaultValues = true
        }
    }
}

dependencies {
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")

    // D-06: kotlinx.serialization's Json/Kaml decoders reject unrecognized
    // keys by default (isLenient = false, the opposite default from
    // app11_swift_ios's Codable) — no hand-written DynamicKey-style
    // unknown-key check is needed here the way Swift/PHP required one.
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")
    implementation("com.charleskorn.kaml:kaml:0.61.0")

    // JUnit4, not JUnit5 — Robolectric's `@RunWith(RobolectricTestRunner::class)`
    // is a JUnit4 `Runner`; this is Robolectric's canonical, officially
    // supported integration, so pure-logic tests (no Room) and Room-backed
    // tests (Robolectric) share one consistent test framework rather than
    // mixing JUnit4 and JUnit5 in the same module.
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.13")
    testImplementation("androidx.test:core:1.6.1")
    testImplementation("androidx.test.ext:junit:1.2.1")
    testImplementation("androidx.room:room-testing:2.6.1")
    // Used as a plain library (`Arb`/`checkAll` inside ordinary JUnit4 `@Test`
    // methods), not via Kotest's own Spec/JUnit5 runner — see
    // `CodeSampleCompletenessPropertyTest.kt`.
    testImplementation("io.kotest:kotest-property:5.9.1")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.9.0")
}
