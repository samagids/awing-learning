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
subprojects {
    project.evaluationDependsOn(":app")
}

// Force all subprojects (including plugins) to use Java 17 source/target
// to eliminate "source value 8 is obsolete" warnings AND fix the
// "Inconsistent JVM-target compatibility" error between Java (default
// JVM 11 from plugins like tflite_flutter) and Kotlin (JVM 17 from
// project). Uses afterEvaluate so this runs AFTER each plugin's own
// configuration overrides.
subprojects {
    afterEvaluate {
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
        }
        tasks.withType<
            org.jetbrains.kotlin.gradle.tasks.KotlinCompile
        >().configureEach {
            kotlinOptions.jvmTarget = JavaVersion.VERSION_17.toString()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
