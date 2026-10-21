package com.hoptales.content

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Profile(
    val childName: String = "",
    val startingFriend: Friend = Friend.BUNNY,
    val accent: Accent = Accent.CANADIAN,
    val voiceID: String? = null,
    val soundButtons: Boolean = false,
) {
    @Serializable
    enum class Accent(val tag: String, val accentName: String) {
        @SerialName("en-CA")
        CANADIAN("en-CA", "Canadian"),

        @SerialName("en-US")
        AMERICAN("en-US", "American"),

        @SerialName("en-GB")
        BRITISH("en-GB", "British"),

        @SerialName("en-AU")
        AUSTRALIAN("en-AU", "Australian"),
        ;

        companion object {
            fun of(region: String?): Accent = when (region?.uppercase()) {
                "US" -> AMERICAN
                "GB" -> BRITISH
                "AU" -> AUSTRALIAN
                else -> CANADIAN
            }
        }
    }

    companion object {
        const val NAME_LIMIT = 24

        fun trimmedName(name: String): String = name.take(NAME_LIMIT)
    }
}

@Serializable
data class ProfileDraft(
    val childName: String = "",
    val startingFriend: Friend? = null,
    val accent: Profile.Accent? = null,
    val voiceID: String? = null,
    val soundButtons: Boolean? = null,
    val step: Int,
)

fun greeting(hour: Int, childName: String?): String {
    val time = when (hour) {
        in 4 until 12 -> "Good morning"
        in 12 until 17 -> "Good afternoon"
        else -> "Good evening"
    }
    return if (childName.isNullOrBlank()) "$time!" else "$time, $childName!"
}
