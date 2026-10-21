package com.hoptales.content

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class PhonicsTest {
    private val resources = System.getProperty("hoptales.resources")
    private val phonics = Phonics.decode(File(resources, "phonics.json").readText())
    private val library = StoryLibrary.decode(File(resources, "stories.json").readText())

    @Test
    fun wordsDecodeAtTheLevelThatTeachesThem() {
        val cases = listOf(
            "sat" to 1, "cats" to 1, "the" to 1, "frog" to 2, "ship" to 2, "ducks" to 2,
            "lake" to 3, "homes" to 3, "dance" to 3, "jumped" to 4, "hopping" to 4, "farm" to 4,
            "rabbit" to 4, "rain" to 5, "house" to 5, "bounced" to 5, "tiny" to 6, "climbing" to 6,
            "wedged" to 6, "little" to 6, "station" to 7, "enormous" to 7, "Bartholomew" to 1,
        )
        for ((word, level) in cases) assertEquals(word, level, phonics.level(word))
    }

    @Test
    fun everyStoryDecodesAtItsLevel() {
        for (story in library.all) {
            for (word in story.sentences.flatMap { it.words }) {
                val ceiling = if (word.big) minOf(story.level + 2, Friend.entries.size) else story.level
                val level = phonics.level(word.text)
                assertTrue("${story.id}: ${word.text} decodes at ${level ?: 0}", level != null && level <= ceiling)
            }
        }
    }

    @Test
    fun eachLevelPractisesItsNewPatterns() {
        for (level in 2..7) {
            val words = library.all.filter { it.level == level }.flatMap { it.sentences }.flatMap { it.words }.filter { !it.big }
            assertTrue("level $level", words.any { phonics.level(it.text) == level })
        }
    }

    @Test
    fun sentenceLengthsFitTheTable() {
        for (story in library.all) {
            val range = SENTENCE_WORDS.getValue(story.level)
            for (sentence in story.sentences) {
                assertTrue("${story.id}: ${sentence.words.size} words", sentence.words.size in range)
            }
        }
    }

    @Test
    fun eachFriendIsNamedForTheTableAndTheirExamplesAreTheirLevel() {
        assertEquals(Friend.entries.map { it.friendName }, phonics.names)
        for (friend in Friend.entries) {
            assertEquals(phonics.phase(friend.level), friend.stage)
            for (word in friend.examples) assertEquals("${friend.friendName}: $word", friend.level, phonics.level(word))
        }
    }

    @Test
    fun soundButtonsMarkEachSound() {
        val cat = checkNotNull(phonics.soundMarks("cat"))
        assertEquals(List(3) { SoundMark.Kind.BUTTON }, cat.map { it.kind })
        assertEquals(
            listOf(
                SoundMark(0, 2, SoundMark.Kind.BAR),
                SoundMark(2, 3, SoundMark.Kind.BUTTON),
                SoundMark(3, 4, SoundMark.Kind.BUTTON),
            ),
            phonics.soundMarks("ship"),
        )
        assertTrue(checkNotNull(phonics.soundMarks("Lake")).contains(SoundMark(1, 4, SoundMark.Kind.SPLIT)))
        assertEquals(SoundMark(4, 6, SoundMark.Kind.BAR), checkNotNull(phonics.soundMarks("jumped")).last())
        assertTrue(checkNotNull(phonics.soundMarks("night")).contains(SoundMark(1, 4, SoundMark.Kind.BAR)))
    }

    @Test
    fun heartWordsAndNamesHaveNoSoundButtons() {
        assertNull(phonics.soundMarks("the"))
        assertNull(phonics.soundMarks("Bob"))
        assertNull(phonics.soundMarks("said"))
    }

    private companion object {
        val SENTENCE_WORDS = mapOf(1 to 3..5, 2 to 5..7, 3 to 6..8, 4 to 7..9, 5 to 8..10, 6 to 9..12, 7 to 10..14)
    }
}
