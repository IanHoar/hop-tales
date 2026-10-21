package com.hoptales.content

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class WordRef(val sentence: Int, val word: Int)

data class StoryResult(
    val storyID: String,
    val wordsRead: Int,
    val bigWordsRead: Int = 0,
    val helpedWords: Int = 0,
    val treat: CollectedTreat? = null,
) {
    val helpRate: Double get() = if (wordsRead > 0) helpedWords.toDouble() / wordsRead else 0.0
}

@Serializable
enum class LevelUp {
    @SerialName("bigStory")
    BIG_STORY,

    @SerialName("sustainedReading")
    SUSTAINED_READING,

    @SerialName("trail")
    TRAIL,
}

sealed interface JourneyMoment {
    data class Tally(val steps: Double, val total: Double, val goal: Double, val bigWords: Int, val next: Friend, val storiesLeft: Int) :
        JourneyMoment

    data class BigStoryReady(val friend: Friend) : JourneyMoment

    data class NotYet(val friend: Friend) : JourneyMoment

    data class NewFriend(val friend: Friend, val via: LevelUp) : JourneyMoment

    data class TreatFound(val treat: CollectedTreat, val trail: Int) : JourneyMoment

    data class BasketFull(val friend: Friend, val number: Int) : JourneyMoment

    val isCallout: Boolean get() = this !is Tally && this !is TreatFound

    fun story(library: StoryLibrary): Story? = when (this) {
        is BigStoryReady -> library.bigStory(friend.level)
        is NewFriend -> library.stories(friend.level).firstOrNull()
        else -> null
    }
}

data class Recorded<T>(val value: T, val moments: List<JourneyMoment>)

@Serializable
data class Journey(
    val level: Int = Friend.BUNNY.level,
    val steps: Double = 0.0,
    val met: Set<Friend> = setOf(Friend.BUNNY),
    val activeFriend: Friend = Friend.BUNNY,
    val bigStoryAttempts: Int = 0,
    val trail: Int = 0,
    val storiesReadWell: Int = 0,
    val recentHelpRates: List<Double> = emptyList(),
    val cleanStreak: Int = 0,
    val storiesRead: Set<String> = emptySet(),
) {
    val nextFriend: Friend? get() = if (level < Levels.top) Friend.at(level + 1) else null

    fun goal(library: StoryLibrary): Double = (library.levels.stepsToNextFriend[level] ?: 0).toDouble()

    fun fill(library: StoryLibrary): Double {
        val goal = goal(library)
        return if (goal > 0) minOf(steps / goal, 1.0) else 1.0
    }

    fun storiesLeft(library: StoryLibrary): List<Story> = library.stories(level).filter { it.id !in storiesRead }

    fun isPathFull(library: StoryLibrary): Boolean {
        if (nextFriend == null || storiesLeft(library).isNotEmpty()) return false
        val share = if (cleanStreak >= 3) Levels.EARLY_BIG_STORY_SHARE else 1.0
        return steps >= goal(library) * share
    }

    fun bigStory(library: StoryLibrary): Story? = if (isPathFull(library)) library.bigStory(level + 1) else null

    fun bigWordShare(library: StoryLibrary): Double {
        val struggling = recentHelpRates.size == 3 && recentHelpRates.sum() / 3 > Levels.BIG_WORDS_BACK_OFF_HELP_RATE
        if (struggling) return Levels.BIG_WORD_RATE_EARLY
        val boost = if (bigStoryAttempts > 0) 1.0 else fill(library)
        return Levels.BIG_WORD_RATE_EARLY + (Levels.BIG_WORD_RATE_LATE - Levels.BIG_WORD_RATE_EARLY) * boost
    }

    fun bigWords(story: Story, library: StoryLibrary): Set<WordRef> {
        if (story.isBigStory || story.level < level) return emptySet()
        val marked = story.sentences.flatMapIndexed { sentence, words ->
            words.words.mapIndexedNotNull { index, word -> if (word.big) WordRef(sentence, index) else null }
        }
        val wanted = Math.round(story.wordCount * bigWordShare(library)).toInt()
        if (wanted >= marked.size) return marked.toSet()
        if (wanted <= 0) return emptySet()
        val stride = marked.size.toDouble() / wanted
        return (0 until wanted).map { marked[(it * stride).toInt()] }.toSet()
    }

    fun stepsEarned(result: StoryResult, story: Story): Double {
        if (story.isBigStory || nextFriend == null) return 0.0
        val atLevel = story.level >= level
        val perWord = if (atLevel) Levels.STEPS_PER_WORD else Levels.STEPS_PER_EASIER_WORD
        val plain = (result.wordsRead - result.bigWordsRead) * perWord
        val big = result.bigWordsRead * Levels.STEPS_PER_BIG_WORD
        val bonus = if (atLevel && result.helpRate <= Levels.STORY_BONUS_HELP_RATE) Levels.STORY_BONUS else 0.0
        return plain + big + bonus
    }

    fun recording(result: StoryResult, library: StoryLibrary): Recorded<Journey> {
        val story = library[result.storyID] ?: return Recorded(this, emptyList())
        if (story.isBigStory) return recordingBigStory(result, story)
        var journey = copy(
            recentHelpRates = (recentHelpRates + result.helpRate).takeLast(3),
            cleanStreak = if (result.helpedWords == 0) cleanStreak + 1 else 0,
        )
        val next = journey.nextFriend ?: return Recorded(journey, emptyList())

        if (story.level == journey.level) journey = journey.copy(storiesRead = journey.storiesRead + story.id)
        val earned = journey.stepsEarned(result, story)
        val goal = journey.goal(library)
        journey = journey.copy(steps = minOf(journey.steps + earned, goal))
        val moments = mutableListOf<JourneyMoment>(
            JourneyMoment.Tally(
                steps = earned,
                total = journey.steps,
                goal = goal,
                bigWords = result.bigWordsRead,
                next = next,
                storiesLeft = journey.storiesLeft(library).size,
            ),
        )

        val readWell = result.helpRate <= Levels.SUSTAINED_HELP_RATE
        if (story.level >= journey.level && readWell) journey = journey.copy(storiesReadWell = journey.storiesReadWell + 1)
        if (result.treat?.isTrail == true) journey = journey.copy(trail = journey.trail + 1)
        result.treat?.let { moments += JourneyMoment.TreatFound(it, if (it.isTrail) journey.trail else 0) }

        val arrival = journey.arrival(library)
        arrival.moments.firstOrNull()?.let { moments += it }
        return Recorded(arrival.value, moments)
    }

    private fun arrival(library: StoryLibrary): Recorded<Journey> {
        val next = nextFriend
        if (storiesLeft(library).isNotEmpty() || next == null) return Recorded(this, emptyList())
        if (trail >= Levels.trailGoal(level)) return Recorded(levelledUp(), listOf(JourneyMoment.NewFriend(next, LevelUp.TRAIL)))
        if (storiesReadWell >= Levels.SUSTAINED_STORIES) {
            return Recorded(levelledUp(), listOf(JourneyMoment.NewFriend(next, LevelUp.SUSTAINED_READING)))
        }
        if (isPathFull(library)) return Recorded(this, listOf(JourneyMoment.BigStoryReady(next)))
        return Recorded(this, emptyList())
    }

    private fun recordingBigStory(result: StoryResult, story: Story): Recorded<Journey> {
        val friend = nextFriend
        if (story.level != level + 1 || friend == null) return Recorded(this, emptyList())
        if (result.helpRate > 1 - Levels.BIG_STORY_BAR) {
            return Recorded(copy(bigStoryAttempts = bigStoryAttempts + 1), listOf(JourneyMoment.NotYet(friend)))
        }
        return Recorded(levelledUp(), listOf(JourneyMoment.NewFriend(friend, LevelUp.BIG_STORY)))
    }

    private fun levelledUp(): Journey {
        val friend = nextFriend ?: return this
        return copy(
            level = level + 1,
            met = met + friend,
            activeFriend = friend,
            steps = 0.0,
            trail = 0,
            storiesReadWell = 0,
            bigStoryAttempts = 0,
            storiesRead = emptySet(),
        )
    }

    fun readingWith(friend: Friend): Journey = if (friend in met) copy(activeFriend = friend) else this

    fun grownUpMovedTo(friend: Friend): Journey = when {
        friend !in met && friend !in Friend.starters -> this
        friend.level > level -> starting(friend)
        else -> copy(activeFriend = friend)
    }

    companion object {
        fun starting(friend: Friend = Friend.BUNNY): Journey = Journey(
            level = friend.level,
            met = Friend.entries.filter { it.level <= friend.level }.toSet(),
            activeFriend = friend,
        )

        val everything: Journey get() = starting(Friend.GRASSHOPPER).copy(met = Friend.entries.toSet())
    }
}
