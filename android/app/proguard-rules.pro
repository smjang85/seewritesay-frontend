# 기본 Flutter 및 plugin 보호
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# App entry point 보호
-keep class com.seewritesay.app.MainActivity { *; }

# Google Play Core 관련
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# Google Play Tasks (꼭 추가)
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.gms.tasks.**

# google_sign_in
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**