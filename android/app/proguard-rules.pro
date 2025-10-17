# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt

# Keep MQTT client classes
-keep class org.eclipse.paho.** { *; }
-dontwwarn org.eclipse.paho.**

# Keep mqtt_client package
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**

# Keep all classes that are referenced by native code
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Suppress warnings for missing classes
-dontwarn io.flutter.embedding.**
