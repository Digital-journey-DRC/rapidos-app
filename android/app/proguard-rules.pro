# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Mapbox classes
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**

# Keep Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepclassmembernames class kotlinx.**$Volatile { *; }

# Keep Hive
-keep class hive.** { *; }
-keep class hive_flutter.** { *; }

# Keep model classes (adjust package name as needed)
-keep class com.rapidosdrc.app.models.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve line numbers for stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ===== Keep Play Core classes for Flutter Deferred Components =====
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
