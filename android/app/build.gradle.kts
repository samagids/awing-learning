import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load signing key from key.properties if it exists
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.awing.awing_ai_learning"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // v1.15.0 — required by flutter_local_notifications 17.x because it
        // uses java.time APIs that need backporting on minSdk 26+.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.awing.learning"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing config — uses key.properties if available
    if (keystorePropertiesFile.exists()) {
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    assetPacks += listOf(":install_time_assets")

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Session 61 — G1 security hardening.
            //
            // R8 minification. Obfuscates class/method names so reverse
            // engineering the APK (e.g. our platform channel name
            // "com.awing.learning/asset_pack" or the dev-mode 2FA path)
            // requires deobfuscation rather than `apktool + strings`.
            //
            // Session 63: AGP 9 forced the base file to
            // `proguard-android-optimize.txt`. Do not "fix" this back to
            // proguard-android.txt — AGP 9 rejects that file outright.
            //
            // v1.23.5 (Session 64d): the optimization pass is now ON.
            // `-dontoptimize` was removed from proguard-rules.pro after
            // Play Console flagged release 140 (1.23.4) with "DEX code
            // optimization is below our threshold — Optimization (0%)",
            // deadline Feb 2027. See the long note at the top of
            // proguard-rules.pro for the reasoning, the safety net, and
            // the real-device test matrix that MUST pass before tagging.
            // If release-only breakage appears, restoring the single line
            // `-dontoptimize` reverts this completely.
            //
            // Resource shrinking is intentionally DISABLED. The Google
            // Services Gradle plugin (`com.google.gms.google-services`)
            // auto-generates string resources at build time
            // (default_web_client_id, firebase_app_id, gcm_defaultSenderId,
            // …) that Google Sign-In + Firebase reach via Resources.
            // getString(). R8's shrinker can't see those references and
            // strips the strings, causing GoogleSignatureVerifier to log
            // "package info is not set correctly" and the OneGoogle
            // account picker to fail with ApiException-38003 right after
            // the user taps their account. Confirmed by test on
            // emulator-5556 in Session 61.
            // Session 61 G1 hardening — restored after sign-in diagnostic.
            // Diagnostic confirmed R8 minify was NOT causing the emulator
            // OneGoogle ApiException-38003 — that turned out to be an
            // emulator OS-level Google account issue.
            //
            // Resource shrinking stays OFF: the google-services Gradle
            // plugin generates string resources (default_web_client_id,
            // firebase_app_id, …) that R8's resource shrinker cannot
            // trace, and stripping them silently breaks Firebase + Google
            // Sign-In. The minor APK-size win is not worth the risk.
            isMinifyEnabled = true
            isShrinkResources = false
            // Session 63 — AGP 9 removed support for "proguard-android.txt"
            // because it bakes in -dontoptimize. We keep the SAME effective
            // behavior by using the -optimize base and re-adding -dontoptimize
            // in proguard-rules.pro (the two default files are otherwise
            // identical). This is a no-op vs. what shipped in v1.23.0+136 —
            // the Session 61 reasoning against R8's optimization pass
            // (inlining methods that Firebase / Google Sign-In /
            // tflite_flutter reach by reflection) is unchanged.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

}

// Session 63 — AGP 9 removed the `android { kotlinOptions { } }` block.
// The KGP-native equivalent is this top-level `kotlin { compilerOptions }`.
kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

// Explicit dependency for `enableEdgeToEdge()` (androidx.activity 1.8.0+).
// Required for the Android 15 (SDK 35) edge-to-edge fix in MainActivity.
// Flutter's transitive activity dep may be older.
dependencies {
    implementation("androidx.activity:activity-ktx:1.9.2")
    // v1.15.0 — pairs with isCoreLibraryDesugaringEnabled = true above.
    // Backports java.time / java.util.stream / etc. so flutter_local_notifications
    // 17.x can run on the full minSdk range.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

