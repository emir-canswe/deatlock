# Flutter engine & embedding
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Keep annotations and native method bindings
-keepattributes *Annotation*
-keepclasseswithmembernames class * {
    native <methods>;
}
