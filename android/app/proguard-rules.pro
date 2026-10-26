# AGP requires optimize defaults; temporarily disable aggressive opts so Flutter
# plugins (shared_preferences / WorkManager) are not broken by R8.
-dontoptimize

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# shared_preferences (Pigeon / Kotlin coroutines — R8 strips getAll without this)
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** {
    <methods>;
    <fields>;
}
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Kotlin / coroutines (Pigeon suspend methods)
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keep class kotlinx.coroutines.** { *; }
-keepclassmembers class **$Continuation {
    <fields>;
    <methods>;
}
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations,AnnotationDefault

# App package
-keep class com.smart.printer.app.wireless.android.** { *; }

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
-keepattributes SourceFile,LineNumberTable
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations

# Play Core / deferred components (safe no-ops if unused).
-dontwarn com.google.android.play.core.**

# ---- WorkManager + Room (required by google_mobile_ads) ----
# Without these, release minify crashes at startup:
# Failed to create an instance of androidx.work.impl.WorkDatabase
-keep class androidx.work.** { *; }
-keep interface androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.InputMerger
-keep public class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-dontwarn androidx.room.paging.**
-dontwarn androidx.work.**

# Google Mobile Ads / Play Services
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Play Billing / IAP
-keep class com.android.vending.billing.** { *; }
-keep class com.android.billingclient.** { *; }
-keep class com.google.android.apps.common.proguard.UsedBy.*
-dontwarn com.android.billingclient.**

# Firebase / Remote Config
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.internal.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.internal.**
