plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bravoball.app.bravoball_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bravoball.app.bravoball_flutter"
        // Optimized for maximum compatibility and Play Store compliance
        minSdk = 23  // Android 6.0 (API 23) - Covers ~98% of active Android devices
        targetSdk = 35  // Required for Google Play Store submission (Android 14)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = findProperty("keyAlias") as String? ?: System.getenv("KEY_ALIAS")
            keyPassword = findProperty("keyPassword") as String? ?: System.getenv("KEY_PASSWORD")
            storeFile = findProperty("storeFile")?.let { file(it) } ?: System.getenv("STORE_FILE")?.let { file(it) }
            storePassword = findProperty("storePassword") as String? ?: System.getenv("STORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false  // Temporarily disabled to fix R8 issues
            isShrinkResources = false  // Must be false when minification is disabled
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
