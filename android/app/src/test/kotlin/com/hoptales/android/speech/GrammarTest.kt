package com.hoptales.android.speech

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class GrammarTest {
    private val sentence = listOf("hop", "in", "the", "sun")

    @Test fun theSentenceAndItsEndingsComeFirst() =
        assertEquals(listOf("hop in the sun", "in the sun", "the sun", "sun"), Grammar.of(sentence, emptyList()).take(4))

    @Test fun everyWordIsListedOnItsOwn() = assertTrue(Grammar.of(sentence, emptyList()).containsAll(sentence))

    @Test fun decoysThatOverlapASentenceWordAreDropped() {
        val grammar = Grammar.of(sentence, listOf("into", "hops", "then", "bug"))
        assertFalse("into" in grammar)
        assertFalse("hops" in grammar)
        assertFalse("then" in grammar)
        assertTrue("bug" in grammar)
    }
}
