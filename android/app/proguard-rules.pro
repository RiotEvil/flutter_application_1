# ProGuard rules for Detailing Pro
# Preserve Firebase rules
-keepattributes Signature
-keepattributes *Annotation*

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Hive
-keep class com.detailing.business.app.** { *; }
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep interface com.google.android.gms.auth.api.signin.** { *; }

# Keep model classes (for Hive/serialization)
-keep class com.detailing.business.app.models.** { *; }

# Keep enums (important for Dart enums used in Hive)
-keepclassmembers enum * {
  public static **[] values();
  public static ** valueOf(java.lang.String);
}

# Keep Enum values() method for Dart interop
-keepclassmembers class * {
  static *** values();
}

# Preserve line numbers for crash reporting
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# flutter_local_notifications - Gson TypeToken fix
# Gson uses generic type information stored in class files when working with
# TypeToken. R8 removes such information by default, causing the crash:
# "TypeToken must be created with a type argument"
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep Gson classes used for serialization of scheduled notifications
-keep class com.google.gson.** { *; }
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# flutter_local_notifications plugin classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
