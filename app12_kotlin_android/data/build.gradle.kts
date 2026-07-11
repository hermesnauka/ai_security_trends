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

    testImplementation("org.junit.jupiter:junit-jupiter:5.11.0")
    testImplementation("io.kotest:kotest-runner-junit5:5.9.1")
    testImplementation("io.kotest:kotest-property:5.9.1")
    testImplementation("androidx.room:room-testing:2.6.1")
}
