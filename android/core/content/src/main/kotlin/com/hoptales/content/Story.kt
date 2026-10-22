package com.hoptales.content

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class Sky {
    @SerialName("day")
    DAY,

    @SerialName("golden")
    GOLDEN,

    @SerialName("dusk")
    DUSK,

    @SerialName("night")
    NIGHT,
}

@Serializable
enum class Weather {
    @SerialName("clear")
    CLEAR,

    @SerialName("clouds")
    CLOUDS,

    @SerialName("storm")
    STORM,

    @SerialName("rain")
    RAIN,

    @SerialName("snow")
    SNOW,
}

@Serializable
data class Mood(val sky: Sky = Sky.DAY, val weather: Weather = Weather.CLEAR)

@Serializable
data class Word(
    val text: String,
    val homophones: List<String> = emptyList(),
    val big: Boolean = false,
    val leading: String = "",
    val trailing: String = "",
)

@Serializable
data class StoryEvent(
    val prop: String,
    val count: Int = 1,
    val after: Int? = null,
    val place: Place? = null,
    val companion: Boolean? = null,
    val thought: Boolean? = null,
) {
    val isCompanion: Boolean get() = companion ?: false

    val isThought: Boolean get() = thought ?: false

    @Serializable
    enum class Place {
        @SerialName("ground")
        GROUND,

        @SerialName("near")
        NEAR,

        @SerialName("sky")
        SKY,
    }
}

@Serializable
data class Sentence(
    val words: List<Word>,
    val newWord: String? = null,
    val sky: Sky? = null,
    val weather: Weather? = null,
    val moodAfter: Int? = null,
    val events: List<StoryEvent> = emptyList(),
)

@Serializable
data class Story(
    val id: String,
    val title: String,
    val sentences: List<Sentence>,
    val mood: Mood = Mood(),
    val level: Int = 1,
    val stretch: Boolean = false,
    val isBigStory: Boolean = false,
) {
    val friend: Friend get() = Friend.at(level)

    val isFree: Boolean get() = level == Plus.FREE_LEVEL

    val wordCount: Int get() = sentences.sumOf { it.words.size }

    fun mood(sentence: Int, word: Int = Int.MAX_VALUE): Mood {
        var mood = mood
        for ((position, step) in sentences.take(maxOf(0, sentence) + 1).withIndex()) {
            val after = step.moodAfter
            if (position == sentence && after != null && word <= after) break
            step.sky?.let { mood = mood.copy(sky = it) }
            step.weather?.let { mood = mood.copy(weather = it) }
        }
        return mood
    }

    val finalMood: Mood get() = mood(sentence = sentences.size - 1)

    companion object {
        const val STEP_PER_WORD = 140.0
    }
}
