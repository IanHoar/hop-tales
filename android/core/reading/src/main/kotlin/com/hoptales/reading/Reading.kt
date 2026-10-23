package com.hoptales.reading

import com.hoptales.content.CollectedTreat
import com.hoptales.content.JourneyMoment
import com.hoptales.content.Levels
import com.hoptales.content.Mood
import com.hoptales.content.Progress
import com.hoptales.content.Sentence
import com.hoptales.content.Story
import com.hoptales.content.StoryLibrary
import com.hoptales.content.StoryResult
import com.hoptales.content.StoryTreat
import com.hoptales.content.Word
import com.hoptales.content.WordRef
import com.hoptales.content.celebratingLevelOne
import com.hoptales.content.collecting
import com.hoptales.speech.PartialDebouncer
import com.hoptales.speech.Strictness
import com.hoptales.speech.WordMatcher

data class ReadingState(
    val story: Story,
    val sentenceIndex: Int = 0,
    val wordIndex: Int = 0,
    val stars: Int = 0,
    val usedHelp: Boolean = false,
    val completed: Completed? = null,
    val completionCount: Int = 0,
    val recognised: Recognised? = null,
    val isSpeaking: Boolean = false,
    val isConfirmingStop: Boolean = false,
    val strictness: Strictness = Strictness.GENTLE,
    val bigWords: Set<WordRef> = emptySet(),
    val treat: StoryTreat? = null,
    val journeyMoments: List<JourneyMoment> = emptyList(),
    val hasTriedItOn: Boolean = false,
) {
    sealed interface Completed {
        data class Sentence(val index: Int) : Completed
        data class Story(val stars: Int) : Completed
    }

    data class Recognised(val count: Int, val sentenceIndex: Int, val wordIndex: Int, val stars: Int)

    val sentence: Sentence? get() = story.sentences.getOrNull(sentenceIndex)
    val currentWord: Word? get() = sentence?.words?.getOrNull(wordIndex)
    val nextWord: Word? get() = sentence?.words?.getOrNull(wordIndex + 1)
    val isFinished: Boolean get() = completed is Completed.Story

    val endedASentence: Boolean get() = completionCount > 0 && completed is Completed.Sentence

    val tally: JourneyMoment.Tally? get() = journeyMoments.firstNotNullOfOrNull { it as? JourneyMoment.Tally }

    val collectedTreat: JourneyMoment.TreatFound? get() = journeyMoments.firstNotNullOfOrNull { it as? JourneyMoment.TreatFound }

    val callout: JourneyMoment? get() = journeyMoments.firstOrNull { it.isCallout }

    fun isBig(sentence: Int, word: Int): Boolean = WordRef(sentence, word) in bigWords

    val wordsCompleted: Int
        get() = story.sentences.take(sentenceIndex).sumOf { it.words.size } + wordIndex

    val worldProgress: Double get() = wordsCompleted * Story.STEP_PER_WORD

    val mood: Mood get() = story.mood(sentenceIndex, wordIndex)

    val wordCardLabel: String
        get() = currentWord?.let { "Current word: ${it.text}. Say it out loud." } ?: "Reading"

    fun advanced(count: Int): ReadingState {
        val sentence = sentence ?: return this
        val read = minOf(count, sentence.words.size - wordIndex)
        if (read <= 0) return this
        var next = copy(stars = stars + read, wordIndex = wordIndex + read)
        if (next.wordIndex < sentence.words.size) return next
        next = next.copy(
            stars = next.stars + if (usedHelp) 0 else SENTENCE_BONUS,
            sentenceIndex = sentenceIndex + 1,
            wordIndex = 0,
            usedHelp = false,
            completionCount = completionCount + 1,
        )
        return if (next.sentenceIndex >= story.sentences.size) {
            val stars = next.stars + STORY_BONUS
            next.copy(stars = stars, completed = Completed.Story(stars))
        } else {
            next.copy(completed = Completed.Sentence(sentenceIndex))
        }
    }

    companion object {
        const val SENTENCE_BONUS = 5
        const val STORY_BONUS = 20
        const val OFFER_HELP_AFTER_MILLIS = 6_000L
        const val SETTLE_AFTER_SPEAKING_MILLIS = 300L
    }
}

enum class Heard(val label: String) {
    CURRENT("current"),
    NEXT("next"),
    WAITING("waiting"),
    NONE("none"),
    SPEAKING("speaking"),
}

class Reading(story: Story, strictness: Strictness = Strictness.GENTLE, bigWords: Set<WordRef> = emptySet(), treat: StoryTreat? = null) {
    var state = ReadingState(story, strictness = strictness, bigWords = bigWords, treat = treat)
        private set

    private val debouncer = PartialDebouncer()
    private var savedStars = 0
    private val wordsRead = mutableSetOf<WordRef>()
    private val wordsHelped = mutableSetOf<WordRef>()

    var lastHeard: Heard = Heard.WAITING
        private set

    fun heard(tokens: List<String>, isFinal: Boolean): WordMatcher.Match? {
        if (state.isSpeaking) {
            lastHeard = Heard.SPEAKING
            return null
        }
        val eligible = debouncer.confirm(tokens, isFinal)
        val current = state.currentWord
        val match = current?.let { WordMatcher.match(eligible, it, state.nextWord, state.strictness) }
        lastHeard = when {
            match?.target == WordMatcher.Target.NEXT -> Heard.NEXT
            match != null -> Heard.CURRENT
            eligible.isEmpty() -> Heard.WAITING
            else -> Heard.NONE
        }
        if (match == null) return null
        val before = state
        val count = if (match.target == WordMatcher.Target.NEXT) 2 else 1
        for (offset in 0 until count) wordsRead += WordRef(before.sentenceIndex, before.wordIndex + offset)
        state = state.advanced(count).copy(
            recognised = ReadingState.Recognised(
                count = (before.recognised?.count ?: 0) + 1,
                sentenceIndex = before.sentenceIndex,
                wordIndex = before.wordIndex,
                stars = 0,
            ),
        )
        state = state.copy(recognised = state.recognised?.copy(stars = state.stars - before.stars))
        if (state.sentenceIndex != before.sentenceIndex) debouncer.reset()
        return match
    }

    fun helpRequested(): String? {
        val word = state.currentWord?.text ?: return null
        if (state.isSpeaking) return null
        wordsHelped += WordRef(state.sentenceIndex, state.wordIndex)
        state = state.copy(usedHelp = true, isSpeaking = true)
        return word
    }

    fun speechFinished() {
        state = state.copy(isSpeaking = false)
        debouncer.reset()
    }

    fun backTapped(): Boolean {
        if (state.isFinished) return true
        state = state.copy(isConfirmingStop = true)
        return false
    }

    fun keepReading() {
        state = state.copy(isConfirmingStop = false)
    }

    fun readAgain() {
        state = ReadingState(state.story, strictness = state.strictness, bigWords = state.bigWords, treat = state.treat)
        savedStars = 0
        wordsRead.clear()
        wordsHelped.clear()
        debouncer.reset()
    }

    fun skipWord() {
        val word = state.currentWord ?: return
        heard(listOf(WordMatcher.normalize(word.text).joinToString("")), isFinal = true)
    }

    fun recordedIn(progress: Progress): Progress {
        val recorded = progress.recording(
            storyID = state.story.id,
            sentences = state.sentenceIndex,
            words = state.wordsCompleted,
            newStars = state.stars - savedStars,
        )
        savedStars = state.stars
        return recorded
    }

    fun finishing(progress: Progress, library: StoryLibrary, isPlus: Boolean = false, locksStories: Boolean = false): Progress {
        val helped = (wordsHelped intersect wordsRead).size
        val helpRate = if (wordsRead.isEmpty()) 0.0 else helped.toDouble() / wordsRead.size
        val collected = state.treat?.takeIf { it.word in wordsRead }?.let {
            CollectedTreat(it.friend, it.isTrail, isGolden = !it.isTrail && helpRate <= Levels.GOLDEN_HELP_RATE)
        }
        val result = StoryResult(
            storyID = state.story.id,
            wordsRead = wordsRead.size,
            bigWordsRead = (wordsRead intersect state.bigWords).size,
            helpedWords = helped,
            treat = collected,
        )
        val journey = progress.journey.recording(result, library)
        val walked = progress.copy(journey = journey.value)
        val basket = collected?.let(walked::collecting)
        val celebrated = (basket?.value ?: walked).celebratingLevelOne(
            state.story,
            journey.moments + basket?.moments.orEmpty(),
            library,
            isPlus,
            locksStories,
        )
        state = state.copy(journeyMoments = celebrated.moments)
        return celebrated.value
    }

    fun backToMyStories(): Boolean {
        momentDismissed()
        return state.callout == null
    }

    fun tryItOn() {
        state = state.copy(hasTriedItOn = true)
    }

    fun momentDismissed() {
        state = state.copy(hasTriedItOn = false)
        val index = state.journeyMoments.indexOfFirst { it.isCallout }
        if (index < 0) return
        state = state.copy(journeyMoments = state.journeyMoments.filterIndexed { position, _ -> position != index })
    }
}
