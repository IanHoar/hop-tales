package com.hoptales.android.speech

import org.junit.Assert.assertEquals
import org.junit.Test

class WordStreamTest {
    @Test fun aWordHeardInOneChunkIsIgnored() {
        val stream = WordStream()
        assertEquals(emptyList<String>(), stream.partial(listOf("hops")))
        assertEquals(emptyList<String>(), stream.partial(emptyList()))
    }

    @Test fun aWordHeardInTwoChunksCountsOnce() {
        val stream = WordStream()
        stream.partial(listOf("bob"))
        assertEquals(listOf("bob"), stream.partial(listOf("bob")))
        assertEquals(emptyList<String>(), stream.partial(listOf("bob")))
    }

    @Test fun onlyNewWordsArePassedOn() {
        val stream = WordStream()
        stream.partial(listOf("he"))
        stream.partial(listOf("he"))
        stream.partial(listOf("he", "can"))
        assertEquals(listOf("can"), stream.partial(listOf("he", "can")))
    }

    @Test fun aResultRepeatingWhatWasPassedOnAddsNothing() {
        val stream = WordStream()
        stream.partial(listOf("to"))
        stream.partial(listOf("to"))
        assertEquals(emptyList<String>(), stream.result(listOf("to")))
    }

    @Test fun aResultCountsWordsThePartialsMissed() {
        val stream = WordStream()
        stream.partial(listOf("red"))
        assertEquals(listOf("red", "bug"), stream.result(listOf("red", "bug")))
    }

    @Test fun theNextUtteranceStartsFresh() {
        val stream = WordStream()
        stream.partial(listOf("hop"))
        stream.partial(listOf("hop"))
        stream.result(listOf("hop"))
        stream.partial(listOf("hop"))
        assertEquals(listOf("hop"), stream.partial(listOf("hop")))
    }

    @Test fun aRevisedWordIsPassedOn() {
        val stream = WordStream()
        stream.partial(listOf("bob"))
        stream.partial(listOf("bob"))
        stream.partial(listOf("bug"))
        assertEquals(listOf("bug"), stream.partial(listOf("bug")))
    }
}
