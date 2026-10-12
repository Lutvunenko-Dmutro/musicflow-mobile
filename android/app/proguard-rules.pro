# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Just Audio & Audio Service
-keep class com.ryanheise.** { *; }
-dontwarn com.ryanheise.**

# Native Crash Handler & App
-keep class com.example.music_flow_mobile.** { *; }

# Play Core / Deferred Components
-dontwarn com.google.android.play.core.**

# OkHttp & Third-party
-dontwarn okhttp3.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn sun.misc.Unsafe
