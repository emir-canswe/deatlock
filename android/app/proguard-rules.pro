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

# WorkManager is pulled in by google_mobile_ads. It builds its Room database
# reflectively (Room looks up WorkDatabase_Impl by name and instantiates it),
# which R8 cannot see, so without these rules the release build crashes at
# start-up with "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
