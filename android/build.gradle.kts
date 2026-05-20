allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Force all subprojects (including plugins) to use Java 17 / Kotlin
// JVM 17 to fix "Inconsistent JVM-target compatibility" errors
// between Java (some plugins default to 1.8 or 11) and Kotlin (17).
//
// CRITICAL ORDERING: This block MUST be registered BEFORE the
// `subprojects { evaluationDependsOn(":app") }` block below — once
// :app is evaluated, registering afterEvaluate on it throws
// "Cannot run Project.afterEvaluate when the project is already
// evaluated".
//
// THREE-LAYER OVERRIDE (each layer needed because AGP/KGP have
// changed how settings propagate over recent versions):
//   1. Android extension compileOptions — what AGP uses to CREATE
//      JavaCompile tasks. Without this, the plugin's own build.gradle
//      that sets compileOptions to 1.8 wins.
//   2. KotlinCompile compilerOptions — new DSL (KGP 2.0+ made the
//      old `kotlinOptions { jvmTarget = ... }` a hard error).
//   3. JavaCompile sourceCompatibility/targetCompatibility — final
//      defensive override on any tasks that escaped layer 1.
subprojects {
    afterEvaluate {
        // Layer 1: Configure the Android plugin extension if present.
        // This is the source of truth AGP uses to create JavaCompile tasks.
        extensions.findByName("android")?.let { ext ->
            if (ext is com.android.build.gradle.BaseExtension) {
                ext.compileOptions.apply {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }

        // Layer 2: Kotlin compile tasks (uses new compilerOptions DSL).
        tasks.withType<
            org.jetbrains.kotlin.gradle.tasks.KotlinCompile
        >().configureEach {
            compilerOptions {
                jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                )
            }
        }

        // Layer 3: Defensive override on JavaCompile tasks.
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
