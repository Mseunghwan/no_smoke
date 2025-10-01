## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**
# Prevent R8 from removing or optimizing SplitCompatApplication
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
# 디버그 기호 유지 설정 추가
-keepattributes SourceFile,LineNumberTable