
// Top-level build file where you can add configuration options common to all sub-projects/modules.

plugins {
    id("com.android.application") version "8.7.0" apply false // Versiyon sizde farklı olabilir
  //  id("com.android.library") version "8.4.1" apply false // Eğer kütüphane modülünüz varsa

    // Google Services Gradle plugin'ini buraya ekleyin
    id("com.google.gms.google-services") version "4.3.15" apply false // Versiyonu kontrol edin

    id("org.jetbrains.kotlin.android") version "1.8.22" apply false // Versiyon sizde farklı olabilir
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Build dizinini değiştirme (mevcut kodunuzdaki gibi)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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