package com.hoptales.content

enum class Friend(
    val key: String,
    val friendName: String,
    val world: String,
    val place: String,
    val treat: Treat,
    val examples: List<String>,
) {
    BUNNY("bunny", "Bob", "Bluebell Wood", "the wood", Treat("strawberry", "strawberries", "strawberry"), listOf("sat", "hop", "red")),
    HARE("hare", "Skip", "The Meadow", "the meadow", Treat("carrot", "carrots", "carrot"), listOf("ship", "duck", "frog")),
    FROG("frog", "Oggy", "Willow Pond", "the pond", Treat("water lily", "water lilies", "lily"), listOf("lake", "kite", "home")),
    CROW("crow", "Button", "Harvest Field", "the field", Treat("button", "buttons", "button"), listOf("jumped", "farm", "garden")),
    CAT("cat", "Marmalade", "Cottage Garden", "the garden", Treat("ball of wool", "balls of wool", "yarn"), listOf("rain", "boat", "moon")),
    CRAB("crab", "Barnacle", "Rock Pools", "the rock pools", Treat("shell", "shells", "shell"), listOf("knock", "tiny", "bottle")),
    GRASSHOPPER("grasshopper", "Bartholomew", "Tall Grass", "the tall grass", Treat("clover leaf", "clover leaves", "clover"), listOf("station", "adventure", "enormous")),
    ;

    val level: Int get() = ordinal + 1

    companion object {
        val starters = listOf(BUNNY, HARE, FROG)

        fun at(level: Int): Friend = entries[level.coerceIn(1, entries.size) - 1]
    }
}

data class Treat(val one: String, val many: String, val art: String)
