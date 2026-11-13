import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release-Signatur aus android/key.properties (nie im Repo, siehe README › Android). Ohne die Datei
// signiert Release mit dem Debug-Schlüssel, damit `flutter run --release` lokal geht – ein App Bundle
// für den Play Store (bundleRelease) bricht dann aber ab (siehe unten).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "de.eloayoubi.kostenkurve"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications braucht Desugaring (java.time auf älteren Android-Versionen).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "de.eloayoubi.kostenkurve"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (keystorePropertiesFile.exists()) "release" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Kein Store-Upload mit dem Debug-Schlüssel: Den könnte jeder nachbauen, und Google bindet die App
// dauerhaft an den ersten Upload-Schlüssel.
gradle.taskGraph.whenReady {
    if (!keystorePropertiesFile.exists() && allTasks.any { it.name == "bundleRelease" }) {
        throw GradleException("android/key.properties fehlt – App Bundle nur mit Release-Schlüssel (README › Android).")
    }
}
