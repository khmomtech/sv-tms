allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fallback Flutter extension values for plugins that read `flutter.*`
// from Gradle extra properties (e.g., flutter_plugin_android_lifecycle).
extra["flutter"] =
    mapOf(
        "compileSdkVersion" to 36,
        "minSdkVersion" to 24,
        "targetSdkVersion" to 36,
        "ndkVersion" to "28.2.13676358",
    )

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
