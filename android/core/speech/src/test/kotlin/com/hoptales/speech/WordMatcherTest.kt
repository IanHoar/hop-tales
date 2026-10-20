package com.hoptales.speech

import com.hoptales.content.StoryLibrary
import com.hoptales.content.Word
import com.hoptales.speech.WordMatcher.Target
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WordMatcherTest {
    private val sat = Word("sat")
    private val knight = Word("knight", homophones = listOf("night"))
    private val mat = Word("mat")

    private fun target(vararg tokens: String, current: Word, next: Word? = null, strictness: Strictness = Strictness.GENTLE) =
        WordMatcher.match(tokens.toList(), current, next, strictness)?.target

    @Test fun exactMatch() = assertEquals(Target.CURRENT, target("the", "cat", "sat", current = sat, next = mat))

    @Test fun onlyTheLastThreeTokensCount() = assertNull(target("sat", "a", "b", "c", current = sat, next = mat))

    @Test fun levenshteinOneIsAcceptedForLongerWords() = assertEquals(Target.CURRENT, target("knigh", current = knight))

    @Test fun levenshteinIsNotAppliedToShortWords() =
        assertNull(target("sad", current = sat, strictness = Strictness.STANDARD))

    @Test fun droppedFinalConsonantIsForgivenWhenGentle() {
        assertEquals(Target.CURRENT, target("sap", current = sat))
        assertNull(target("sap", current = sat, strictness = Strictness.STANDARD))
    }

    @Test fun aDoubledFinalLetterIsForgivenWhenGentle() =
        assertEquals(Target.CURRENT, target("bob", "sapp", current = sat))

    @Test fun onIsHeardWithoutItsN() {
        val on = Word("on")
        for (token in listOf("oh", "awn")) {
            assertEquals(token, Target.CURRENT, target(token, current = on))
            assertNull(token, target(token, current = on, strictness = Strictness.STANDARD))
        }
    }

    @Test fun aShortWordStartingWithYIsHeardThroughItsVowel() {
        for (token in listOf("yep", "yup", "yipp")) assertEquals(token, Target.CURRENT, target(token, current = Word("Yip")))
    }

    @Test fun aSaidAsUhIsHeardEvenWhenTheRecogniserWritesOh() =
        assertEquals(Target.CURRENT, target("oh", current = Word("a")))

    @Test fun aShortWordWithAnotherVowelIsHeardWhenGentle() {
        for (token in listOf("set", "sit", "said", "sed")) assertEquals(token, Target.CURRENT, target(token, current = sat))
    }

    @Test fun hidIsHeardThroughItsCommonMishearings() {
        for (token in listOf("had", "head", "hed")) assertEquals(token, Target.CURRENT, target(token, current = Word("hid")))
    }

    @Test fun aShortWordStillNeedsItsOwnConsonants() {
        for (token in listOf("cat", "hat", "sun", "seats")) assertNull(token, target(token, current = sat))
    }

    @Test fun theShortWordRuleStaysOffWhenStandard() =
        assertNull(target("set", current = sat, strictness = Strictness.STANDARD))

    @Test fun aWordThatSoundsLikeALetterIsHeardAsThatLetter() {
        for (token in listOf("b", "bb", "be")) assertEquals(token, Target.CURRENT, target(token, current = Word("bee")))
    }

    @Test fun aOnItsOwnIsHeardThroughItsLetterName() {
        for (token in listOf("ea", "ear", "eara", "earaa", "a")) assertEquals(token, Target.CURRENT, target(token, current = Word("A")))
    }

    @Test fun aLetterOnlyStandsForItsOwnName() = assertNull(target("b", current = Word("sun")))

    @Test fun homophonesAreAcceptedWhenGentle() {
        val would = Word("would", homophones = listOf("wood"))
        assertEquals(Target.CURRENT, target("wood", current = would))
        assertNull(target("wood", current = would, strictness = Strictness.STANDARD))
        assertEquals(Target.CURRENT, target("night", current = knight))
    }

    @Test fun theIsForgivenWhenGentle() {
        val the = Word("The")
        for (token in listOf("a", "uh", "duh", "da", "de", "dee", "thee", "thuh", "they", "then")) {
            assertEquals("$token was not accepted for the", Target.CURRENT, target(token, current = the))
        }
        assertNull(target("cat", current = the))
    }

    @Test fun theStaysExactWhenStandard() {
        val the = Word("the")
        assertEquals(Target.CURRENT, target("the", current = the, strictness = Strictness.STANDARD))
        assertNull(target("duh", current = the, strictness = Strictness.STANDARD))
    }

    @Test fun readingAheadMarksTheCurrentWordReadToo() = assertEquals(Target.NEXT, target("mat", current = sat, next = mat))

    @Test fun normalizeStripsPunctuationAndCase() =
        assertEquals(listOf("the", "cat", "sat"), WordMatcher.normalize("The cat, SAT!"))

    @Test fun partialsMustRepeatBeforeTheyCount() {
        val debouncer = PartialDebouncer()
        assertTrue(debouncer.confirm(listOf("sat"), isFinal = false).isEmpty())
        assertEquals(listOf("sat"), debouncer.confirm(listOf("sat"), isFinal = false))
    }

    @Test fun finalResultsCountImmediately() =
        assertEquals(listOf("sat"), PartialDebouncer().confirm(listOf("sat"), isFinal = true))

    @Test fun aWordFromTheStoryMatchesItselfOnceNormalised() {
        val library = StoryLibrary.decode(File(System.getProperty("hoptales.resources"), "stories.json").readText())
        for (story in library.all) {
            for (sentence in story.sentences) {
                for ((index, word) in sentence.words.withIndex()) {
                    val match = WordMatcher.match(WordMatcher.normalize(word.text), word, sentence.words.getOrNull(index + 1))
                    assertNotNull("${word.text} in ${story.id} did not match itself", match)
                }
            }
        }
    }

    @Test fun digitsAreHeardAsTheirWords() {
        assertEquals(listOf("i", "want", "two", "go"), WordMatcher.normalize("I want 2 go"))
        val to = Word("to", homophones = listOf("two", "too"))
        assertNotNull(WordMatcher.match(WordMatcher.normalize("ran 2"), to, null))
    }

    @Test fun apostrophesDoNotStopAMatch() {
        assertEquals(listOf("its", "big"), WordMatcher.normalize("It’s big"))
        assertNotNull(WordMatcher.match(listOf("its"), Word("Its"), null))
    }

    @Test fun capitalsAndPunctuationInTheStoryDoNotMatter() =
        assertNotNull(WordMatcher.match(WordMatcher.normalize("MAT"), Word("Mat."), null))
}
