import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.bravoball.app.bravoball_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"  // Updated for 16 KB page size support (matches rive.ndk.version)

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
        minSdk = flutter.minSdkVersion  // Android 6.0 (API 23) - Covers ~98% of active Android devices
        targetSdk = 35  // Required for Google Play Store submission (Android 14)
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Support for multiple CPU architectures including 64-bit devices
        // Note: x86_64 excluded from production builds as it's only needed for emulators
        // and Rive's x86_64 libraries don't support 16 KB page sizes yet
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            // x86_64 removed: only needed for emulators, not production devices
            // Re-add when Rive updates librive_text.so with 16 KB support for x86_64
        }
        
        // Support for 16 KB page sizes - NDK r27+ configuration
        // This ensures native libraries built with CMake are 16KB-aligned
        externalNativeBuild {
            cmake {
                // Enable 16 KB page size support for native libraries
                arguments += listOf("-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON")
            }
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
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

    // Support for 16 KB page sizes - required by Google Play (Nov 2025+)
    packaging {
        jniLibs {
            useLegacyPackaging = false  // Use uncompressed, 16KB-aligned libraries
            // Ensure native libraries are stored uncompressed for proper alignment
            pickFirsts += listOf("**/libc++_shared.so")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
