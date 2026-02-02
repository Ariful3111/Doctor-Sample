# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Google Play Core Library (required for Flutter)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep your app's packages
-keep class com.example.doctor_app.** { *; }

# GetX State Management
-keep class com.getx.** { *; }
-keep class get.** { *; }
-keepclasseswithmembers class * {
    @* <fields>;
}

# Socket.io
-keep class io.socket.** { *; }
-dontwarn io.socket.**

# Mobile Scanner
-keep class xyz.belvi.** { *; }
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep custom application classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Optimization
-optimizationpasses 5
-dontusemixedcaseclassnames
-verbose

# Allow unused code removal
-dontshrink
-dontoptimize
-dontwarn **
