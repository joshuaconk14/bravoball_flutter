# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.

# Keep Flutter plugin classes
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Google Play Core classes (fixes R8 error)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep RiveAsset and Rive related classes
-keep class app.rive.runtime.kotlin.** { *; }

# Keep AudioPlayer related classes
-keep class xyz.luan.audioplayers.** { *; }

# Keep HTTP and networking classes
-keep class org.apache.http.** { *; }
-keep class com.android.volley.** { *; }

# Keep SharedPreferences
-keep class android.content.SharedPreferences** { *; }

# Standard Android rules
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** v(...);
    public static *** d(...);
} 