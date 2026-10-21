package com.hoptales.reading

import com.hoptales.content.Mood
import com.hoptales.content.Progress
import com.hoptales.content.Sentence
import com.hoptales.content.Story
import com.hoptales.content.Word
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
    val bigWords: Set<HopTarget> = emptySet(),
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

class Reading(story: Story, strictness: Strictness = Strictness.GENTLE, bigWords: Set<HopTarget> = emptySet()) {
    var state = ReadingState(story, strictness = strictness, bigWords = bigWords)
        private set

    private val debouncer = PartialDebouncer()
    private var savedStars = 0

    fun heard(tokens: List<String>, isFinal: Boolean): WordMatcher.Match? {
        if (state.isSpeaking) return null
        val eligible = debouncer.confirm(tokens, isFinal)
        val current = state.currentWord ?: return null
        val match = WordMatcher.match(eligible, current, state.nextWord, state.strictness) ?: return null
        val before = state
        val count = if (match.target == WordMatcher.Target.NEXT) 2 else 1
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
        state = ReadingState(state.story, strictness = state.strictness, bigWords = state.bigWords)
        savedStars = 0
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
}
