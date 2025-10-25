// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.5.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
}


allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🧩 Bổ sung build directory tuỳ chỉnh (giữ nguyên code cũ của bạn)
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

// 🧹 Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ⚙️ Thêm cấu hình SDK/NDK chuẩn (đảm bảo Gradle nhận đúng version)
gradle.afterProject {
    if (project.name == "app") {
        project.extensions.findByName("android")?.let {
            val androidExtension = it as com.android.build.gradle.BaseExtension
            androidExtension.apply {
                compileSdkVersion(34)
                ndkVersion = "26.1.10909125" // ✅ Dùng NDK ổn định thay cho 27
            }
        }
    }
}
