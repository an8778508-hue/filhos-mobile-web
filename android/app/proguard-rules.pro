# Keep Firebase + Crashlytics reflection
-keep class com.google.firebase.** { *; }
-keep class com.crashlytics.** { *; }

# Hive uses reflective lookup for adapter registration
-keep class hive.** { *; }
-keep class hivedb.** { *; }

# just_audio / flutter_sound / record native bridges
-keep class com.ryanheise.** { *; }
-keep class com.dooboolab.** { *; }

# alarm package runs in background isolate; entry-points must survive shrinking
-keep class com.gdelataillade.alarm.** { *; }

# Flutter standard rules (added defensively; some plugins still expect these)
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Suppress notes about missing optional classes
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
