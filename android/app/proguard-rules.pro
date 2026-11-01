-keepclassmembers @kotlinx.serialization.Serializable class com.hoptales.** {
    *** Companion;
    kotlinx.serialization.KSerializer serializer(...);
}

-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
