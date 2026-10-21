package com.hoptales.content

import kotlin.math.ceil

class Levels(private val library: StoryLibrary) {
    val stepsToNextFriend: Map<Int, Int> = GOOD_READS_TO_NEXT_FRIEND.mapValues { (level, reads) ->
        Math.round(goodRead(level) * reads / 10).toInt() * 10
    }

    fun goodRead(level: Int): Double {
        val stories = library.stories(level)
        if (stories.isEmpty()) return 0.0
        val words = stories.sumOf { it.wordCount }
        return words.toDouble() / stories.size * STEPS_PER_WORD + STORY_BONUS
    }

    companion object {
        val GOOD_READS_TO_NEXT_FRIEND: Map<Int, Double> = mapOf(1 to 3.5, 2 to 3.5, 3 to 4.0, 4 to 4.5, 5 to 5.0, 6 to 5.5)
        val SENTENCE_WORDS: Map<Int, IntRange> = mapOf(1 to 3..5, 2 to 5..7, 3 to 6..8, 4 to 7..9, 5 to 8..10, 6 to 9..12, 7 to 10..14)

        const val STEPS_PER_WORD = 1.0
        const val STEPS_PER_EASIER_WORD = 0.5
        const val STEPS_PER_BIG_WORD = 5.0
        const val STORY_BONUS = 20.0
        const val STORY_BONUS_HELP_RATE = 0.1

        const val BIG_WORD_RATE_EARLY = 1.0 / 20
        const val BIG_WORD_RATE_LATE = 1.0 / 8
        const val BIG_WORDS_BACK_OFF_HELP_RATE = 0.2
        const val EARLY_BIG_STORY_SHARE = 0.9

        const val BIG_STORY_BAR = 0.85
        const val SUSTAINED_STORIES = 8
        const val SUSTAINED_HELP_RATE = 0.1

        const val GOLDEN_TREAT_WORTH = 3
        const val GOLDEN_HELP_RATE = 0.1

        val top: Int get() = Friend.entries.size

        fun trailGoal(level: Int): Int = ceil(GOOD_READS_TO_NEXT_FRIEND[level] ?: 0.0).toInt()

        fun treatsForBasket(number: Int): Int = 3 + number
    }
}
