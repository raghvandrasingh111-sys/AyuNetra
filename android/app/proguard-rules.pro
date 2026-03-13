####################################
# Flutter
####################################
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

####################################
# Google ML Kit – Core
####################################
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

####################################
# ML Kit Text Recognition Languages
####################################
-keep class com.google.mlkit.vision.text.latin.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

####################################
# Google Play Services
####################################
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

####################################
# Google Play Core (Flutter)
####################################
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

####################################
# Flutter deferred components
####################################
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
