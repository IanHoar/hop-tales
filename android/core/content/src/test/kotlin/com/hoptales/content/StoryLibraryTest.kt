package com.hoptales.content

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class StoryLibraryTest {
    private val library = StoryLibrary.decode(
        File(System.getProperty("hoptales.resources"), "stories.json").readText(),
    )

    @Test
    fun decodesTheSharedStories() {
        assertTrue(library.all.isNotEmpty())
        assertTrue(library.all.all { it.sentences.isNotEmpty() && it.title.isNotBlank() })
    }

    @Test
    fun everyLevelHasAShelf() {
        for (friend in Friend.entries) {
            assertFalse("level ${friend.level} has stories", library.stories(friend.level).isEmpty())
        }
    }

    @Test
    fun firstStoryStartsWithBob() {
        val story = library["meadow-walk"]
        assertNotNull(story)
        assertEquals("Bob", story!!.sentences[0].words[0].text)
        assertEquals(".", story.sentences[0].words.last().trailing)
    }

    @Test
    fun moodChangesAfterTheNamedWord() {
        val story = Story(
            id = "s",
            title = "S",
            sentences = listOf(
                Sentence(words = listOf(Word("a"))),
                Sentence(words = listOf(Word("b"), Word("c")), sky = Sky.DUSK, moodAfter = 0),
            ),
        )
        assertEquals(Sky.DAY, story.mood(sentence = 1, word = 0).sky)
        assertEquals(Sky.DUSK, story.mood(sentence = 1, word = 1).sky)
        assertEquals(Sky.DUSK, story.finalMood.sky)
    }

    @Test
    fun progressKeepsTheFurthestRead() {
        val progress = Progress()
            .recording("s", sentences = 3, words = 12, newStars = 10)
            .recording("s", sentences = 1, words = 4, newStars = 2)
        assertEquals(3, progress.completedSentences["s"])
        assertEquals(12, progress.wordsRead["s"])
        assertEquals(12, progress.stars)
    }
}
