package com.hoptales.content

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class StoryProp(val motion: Motion, val place: StoryEvent.Place, val height: Double, val sticker: Boolean? = null) {
    @Serializable
    enum class Motion {
        @SerialName("walk")
        WALK,

        @SerialName("swim")
        SWIM,

        @SerialName("fly")
        FLY,

        @SerialName("perch")
        PERCH,

        @SerialName("swoop")
        SWOOP,

        @SerialName("pop")
        POP,

        @SerialName("burst")
        BURST,

        @SerialName("drift")
        DRIFT,

        @SerialName("sway")
        SWAY,

        @SerialName("roll")
        ROLL,

        @SerialName("bob")
        BOB,

        @SerialName("fade")
        FADE,
        ;

        val frames: Int
            get() = when (this) {
                WALK, SWIM, FLY, PERCH, SWOOP -> 2
                else -> 1
            }
    }

    val isSticker: Boolean get() = sticker ?: true

    fun height(world: Friend): Double = if (isSticker) minOf(height * world.propScale, LARGEST) else height

    companion object {
        const val LARGEST = 260.0
    }
}

class StoryProps(val all: Map<String, StoryProp>) {
    fun named(name: String): StoryProp? = all[name]

    fun place(event: StoryEvent): StoryEvent.Place = event.place ?: named(event.prop)?.place ?: StoryEvent.Place.GROUND

    companion object {
        val none = StoryProps(emptyMap())

        fun decode(props: String): StoryProps = StoryProps(StoryLibrary.json.decodeFromString(props))
    }
}

val Friend.propScale: Double
    get() = when (this) {
        Friend.BUNNY -> 1.2
        Friend.HARE, Friend.CROW, Friend.CAT -> 1.0
        Friend.FROG -> 2.0
        Friend.CRAB -> 2.2
        Friend.GRASSHOPPER -> 4.0
    }
