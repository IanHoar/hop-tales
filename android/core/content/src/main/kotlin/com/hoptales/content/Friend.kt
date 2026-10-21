package com.hoptales.content

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class Friend(
    val key: String,
    val friendName: String,
    val world: String,
    val place: String,
    val treat: Treat,
    val examples: List<String>,
    val gift: String,
) {
    @SerialName("bunny")
    BUNNY(
        "bunny",
        "Bob",
        "Bluebell Wood",
        "the wood",
        Treat("strawberry", "strawberries", "strawberry"),
        listOf("sat", "hop", "red"),
        "a bluebell crown",
    ),

    @SerialName("hare")
    HARE("hare", "Skip", "The Meadow", "the meadow", Treat("carrot", "carrots", "carrot"), listOf("ship", "duck", "frog"), "a straw hat"),

    @SerialName("frog")
    FROG(
        "frog",
        "Oggy",
        "Willow Pond",
        "the pond",
        Treat("water lily", "water lilies", "lily"),
        listOf("lake", "kite", "home"),
        "a lily-pad hat",
    ),

    @SerialName("crow")
    CROW(
        "crow",
        "Button",
        "Harvest Field",
        "the field",
        Treat("button", "buttons", "button"),
        listOf("jumped", "farm", "garden"),
        "a tweed flat cap",
    ),

    @SerialName("cat")
    CAT(
        "cat",
        "Marmalade",
        "Cottage Garden",
        "the garden",
        Treat("ball of wool", "balls of wool", "yarn"),
        listOf("rain", "boat", "moon"),
        "a gardening hat",
    ),

    @SerialName("crab")
    CRAB(
        "crab",
        "Barnacle",
        "Rock Pools",
        "the rock pools",
        Treat("shell", "shells", "shell"),
        listOf("knock", "tiny", "bottle"),
        "a sailor cap",
    ),

    @SerialName("grasshopper")
    GRASSHOPPER(
        "grasshopper",
        "Bartholomew",
        "Tall Grass",
        "the tall grass",
        Treat("clover leaf", "clover leaves", "clover"),
        listOf("station", "adventure", "enormous"),
        "an acorn cap",
    ),
    ;

    val level: Int get() = ordinal + 1

    val stage: String
        get() = when (this) {
            BUNNY -> "Short vowels"
            HARE -> "Digraphs and blends"
            FROG -> "Magic e"
            CROW -> "Endings and ar, or, er"
            CAT -> "Vowel teams"
            CRAB -> "Silent letters"
            GRASSHOPPER -> "Longer words"
        }

    companion object {
        val starters = listOf(BUNNY, HARE, FROG)

        const val PHONICS_STANDARD = "Reading levels are based on the UFLI Foundations phonics sequence."

        fun at(level: Int): Friend = entries[level.coerceIn(1, entries.size) - 1]
    }
}

data class Treat(val one: String, val many: String, val art: String)
