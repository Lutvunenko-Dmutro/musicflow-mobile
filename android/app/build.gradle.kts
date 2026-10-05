import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.music_flow_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.music_flow_mobile"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: "musicflow"
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "release.keystore")
            storePassword = keystoreProperties.getProperty("storePassword") ?: ""
        }
    }

    buildTypes {
        debug {
            // Підписуємо офіційним ключем MusicFlow (CN=MusicFlow, Kyiv, UA)
            signingConfig = signingConfigs.getByName("release")
        }
        release {
            // Підписуємо тим самим ключем MusicFlow для 100% сумісності та відсутності конфліктів
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
