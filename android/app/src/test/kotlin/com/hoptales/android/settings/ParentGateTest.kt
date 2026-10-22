package com.hoptales.android.settings

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ParentGateTest {
    @Test
    fun theQuestionIsATimesTableInWords() {
        val question = GateQuestion(7, 8)
        assertEquals("What is seven times eight?", question.words)
        assertEquals(56, question.answer)
        assertTrue(question.accepts("56"))
        assertFalse(question.accepts("65"))
        assertFalse(question.accepts(""))
    }

    @Test
    fun everyDrawStaysInTheTimesTables() {
        for (seed in 0L until 200L) {
            for (round in 0 until 4) {
                val question = GateQuestion.drawn(seed, round)
                assertTrue(question.left in GateQuestion.FACTORS)
                assertTrue(question.right in GateQuestion.FACTORS)
                assertTrue(question.answer.toString().length <= GateQuestion.ANSWER_DIGITS)
            }
        }
    }

    @Test
    fun aRedrawIsNeverTheSameQuestion() {
        for (seed in 0L until 200L) {
            for (round in 1 until 6) {
                assertNotEquals(GateQuestion.drawn(seed, round - 1), GateQuestion.drawn(seed, round))
            }
        }
    }

    @Test
    fun theSameSeedDrawsTheSameQuestionsAsIOS() {
        val drawn = (0 until 4).map { GateQuestion.drawn(1, it) }
        assertEquals(listOf(GateQuestion(5, 3), GateQuestion(4, 3), GateQuestion(8, 5), GateQuestion(3, 6)), drawn)
        assertEquals(GateQuestion(8, 8), GateQuestion.drawn(42, 0))
    }

    @Test
    fun theRightAnswerContinues() {
        val gate = ParentGateState(seed = 1)
        assertEquals("What is five times three?", gate.question.words)
        val answered = gate.digit(1).digit(5)
        assertEquals("15", answered.entry)
        assertTrue(answered.checked().passed)
    }

    @Test
    fun aWrongAnswerDrawsANewQuestion() {
        val wrong = ParentGateState(seed = 1).digit(5).digit(3).checked()
        assertFalse(wrong.passed)
        assertEquals(1, wrong.round)
        assertEquals("", wrong.entry)
        assertEquals("What is four times three?", wrong.question.words)
        assertTrue(wrong.digit(1).digit(2).checked().passed)
    }

    @Test
    fun theAnswerHoldsTwoDigitsAndDeletes() {
        val gate = ParentGateState(seed = 1).digit(4).digit(2).digit(7)
        assertEquals("42", gate.entry)
        assertEquals("4", gate.delete().entry)
        assertEquals("", gate.delete().delete().delete().entry)
    }

    @Test
    fun anEmptyAnswerIsNotChecked() {
        val gate = ParentGateState(seed = 1)
        assertEquals(gate, gate.checked())
    }
}
