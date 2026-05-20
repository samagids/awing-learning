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

// Force all subprojects (including plugins) to use Java 17 source/target
// to eliminate "source value 8 is obsolete" warnings AND fix the
// "Inconsistent JVM-target compatibility" error between Java (default
// JVM 11 from plugins like tflite_flutter) and Kotlin (JVM 17 from
// project). Uses afterEvaluate so this runs AFTER each plugin's own
// configuration overrides.
//
// CRITICAL ORDERING: This block MUST be registered BEFORE the
// `subprojects { evaluationDependsOn(":app") }` block below, because
// evaluationDependsOn forces synchronous evaluation of :app — once
// that happens, registering afterEvaluate on it throws
// "Cannot run Project.afterEvaluate when the project is already
// evaluated".
//
// Note: uses the new `compilerOptions` DSL on KotlinCompile tasks —
// the older `kotlinOptions { jvmTarget = ... }` form is a hard error
// in newer Kotlin Gradle Plugin versions.
subprojects {
    afterEvaluate {
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
        }
        tasks.withType<
            org.jetbrains.kotlin.gradle.tasks.KotlinCompile
        >().configureEach {
            compilerOptions {
                jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                )
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
