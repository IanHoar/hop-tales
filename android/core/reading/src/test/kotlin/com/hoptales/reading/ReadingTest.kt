package com.hoptales.reading

import com.hoptales.content.Progress
import com.hoptales.content.Sentence
import com.hoptales.content.Sky
import com.hoptales.content.Story
import com.hoptales.content.Word
import com.hoptales.content.WordRef
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ReadingTest {
    private val story = Story(
        id = "test",
        title = "Test",
        sentences = listOf(
            Sentence(words = listOf(Word("The"), Word("cat"), Word("sat"))),
            Sentence(words = listOf(Word("It"), Word("ran")), sky = Sky.DUSK),
        ),
    )

    private fun Reading.read(word: String) = heard(listOf(word), isFinal = true)

    @Test fun readingAWordAdvancesAndAwardsAStar() {
        val reading = Reading(story)
        reading.read("the")
        assertEquals(1, reading.state.wordIndex)
        assertEquals(1, reading.state.stars)
        assertEquals(ReadingState.Recognised(1, 0, 0, 1), reading.state.recognised)
    }

    @Test fun partialsMustRepeatBeforeTheyCount() {
        val reading = Reading(story)
        reading.heard(listOf("the"), isFinal = false)
        assertEquals(0, reading.state.wordIndex)
        reading.heard(listOf("the"), isFinal = false)
        assertEquals(1, reading.state.wordIndex)
    }

    @Test fun finishingASentenceWithNoHelpAwardsFiveMoreStars() {
        val reading = Reading(story)
        listOf("the", "cat", "sat").forEach { reading.read(it) }
        assertEquals(1, reading.state.sentenceIndex)
        assertEquals(3 + 5, reading.state.stars)
        assertEquals(ReadingState.Completed.Sentence(0), reading.state.completed)
        assertEquals(1 + 5, reading.state.recognised?.stars)
    }

    @Test fun helpCostsTheSentenceBonus() {
        val reading = Reading(story)
        assertEquals("The", reading.helpRequested())
        reading.speechFinished()
        listOf("the", "cat", "sat").forEach { reading.read(it) }
        assertEquals(3, reading.state.stars)
        assertFalse(reading.state.usedHelp)
    }

    @Test fun theAppDoesNotHearItselfSpeak() {
        val reading = Reading(story)
        reading.helpRequested()
        assertNull(reading.read("the"))
        assertEquals(0, reading.state.wordIndex)
    }

    @Test fun askingToHearAWordTwiceOverDoesNotStack() {
        val reading = Reading(story)
        assertEquals("The", reading.helpRequested())
        assertNull(reading.helpRequested())
    }

    @Test fun readingAheadReadsBothWords() {
        val reading = Reading(story)
        reading.read("cat")
        assertEquals(2, reading.state.wordIndex)
        assertEquals(2, reading.state.stars)
    }

    @Test fun finishingTheLastSentenceEndsTheStory() {
        val reading = Reading(story)
        listOf("the", "cat", "sat", "it", "ran").forEach { reading.read(it) }
        assertEquals(ReadingState.Completed.Story(5 + 5 + 5 + 20), reading.state.completed)
        assertTrue(reading.backTapped())
    }

    @Test fun eachWordReadWalksTheWorldOneStep() {
        val reading = Reading(story)
        listOf("the", "cat", "sat", "it").forEach { reading.read(it) }
        assertEquals(4 * Story.STEP_PER_WORD, reading.state.worldProgress, 0.0)
    }

    @Test fun theWorldMoodFollowsTheSentence() {
        val reading = Reading(story)
        assertEquals(Sky.DAY, reading.state.mood.sky)
        listOf("the", "cat", "sat").forEach { reading.read(it) }
        assertEquals(Sky.DUSK, reading.state.mood.sky)
    }

    @Test fun backAsksBeforeLeavingTheStory() {
        val reading = Reading(story)
        assertFalse(reading.backTapped())
        assertTrue(reading.state.isConfirmingStop)
        reading.keepReading()
        assertFalse(reading.state.isConfirmingStop)
    }

    @Test fun readingAgainStartsTheStoryOver() {
        val reading = Reading(story)
        listOf("the", "cat", "sat").forEach { reading.read(it) }
        reading.readAgain()
        assertEquals(ReadingState(story), reading.state)
    }

    @Test fun readingAgainKeepsTheBigWords() {
        val bigWords = setOf(WordRef(0, 1))
        val reading = Reading(story, bigWords = bigWords)
        listOf("the", "cat", "sat").forEach { reading.read(it) }
        reading.readAgain()
        assertEquals(ReadingState(story, bigWords = bigWords), reading.state)
    }

    @Test fun progressOnlyCountsNewStars() {
        val reading = Reading(story)
        listOf("the", "cat", "sat").forEach { reading.read(it) }
        var progress = reading.recordedIn(Progress())
        reading.read("it")
        progress = reading.recordedIn(progress)
        assertEquals(9, progress.stars)
        assertEquals(1, progress.completedSentences["test"])
        assertEquals(4, progress.wordsRead["test"])
    }
}
