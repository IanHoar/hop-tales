-keepclassmembers @kotlinx.serialization.Serializable class com.hoptales.** {
    *** Companion;
    kotlinx.serialization.KSerializer serializer(...);
}

-keep class * extends androidx.room.RoomDatabase {
    <init>();
}

-keep class com.sun.jna.** { *; }
-keepclassmembers class * extends com.sun.jna.** { public *; }
-keep class org.vosk.** { *; }
-dontwarn java.awt.**
