pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Session 63 — Play Console flagged "Upgrade your Android Gradle
    // plugin to version 9.0 or higher" as part of the R8 optimization
    // recommendation on production release 136 (1.23.0). Bumping from
    // 8.11.1 -> 9.0.0. If Gradle fails to resolve 9.0.0 (still in
    // preview at time of this bump), one-line rollback: change back to
    // "8.11.1". No other AGP-9-only APIs are used elsewhere in this
    // project, so the rollback is fully safe.
    id("com.android.application") version "9.0.0" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
include(":install_time_assets")
