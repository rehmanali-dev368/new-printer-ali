# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep native / JNI bridges used by PDF and scan plugins.
-keep class com.github.krosuperior.** { *; }
-keep class io.scer.** { *; }
-keep class dev.dart.jni.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}

# Gson / JSON reflective models if any plugins use them.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Play Core / deferred components (safe no-ops if unused).
-dontwarn com.google.android.play.core.**
