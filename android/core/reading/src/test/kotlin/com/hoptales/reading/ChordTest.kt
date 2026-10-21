package com.hoptales.reading

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

class ChordTest {
    @Test
    fun rendersTheWholeChordWithoutClipping() {
        val samples = Chord.samples()
        assertEquals((Chord.LENGTH * Chord.SAMPLE_RATE).toInt(), samples.size)
        val peak = samples.maxOf { abs(it) }
        assertTrue(peak > 0.1f)
        assertTrue(peak < 1f)
    }

    @Test
    fun eachNoteComesInAfterTheOneBelow() {
        assertEquals(0f, Chord.sample(0.0))
        val early = (0 until 40).map { abs(Chord.sample(it.toDouble() / Chord.SAMPLE_RATE * 40)) }
        assertTrue(early.any { it > 0 })
    }

    @Test
    fun diesAwayBeforeItEnds() {
        val tail = generateSequence(Chord.LENGTH - 0.05) { it + 0.001 }
            .takeWhile { it < Chord.LENGTH }
            .map { abs(Chord.sample(it)) }
        assertTrue(tail.max() < 0.02f)
    }

    @Test
    fun matchesTheSwiftChordEveryNineHundredNinetySeventhFrame() {
        val swift = "0.0,-0.16337655,-0.14453085,0.092191204,0.089841336,0.06943636,-0.41020685,-0.10739356," +
            "-0.017579805,-0.13743298,0.21204679,0.23021041,0.060971495,0.00017333636,-0.1549302,-0.001946824," +
            "0.121075444,-0.17446974,-0.11393167,0.100196175,-0.08322998,-0.0028898828,0.23861375,0.052604407," +
            "-0.08590524,-0.020185295,-0.051904537,-0.02768583,0.0038527537,-0.029541587,0.027129812,0.007709236," +
            "-0.039373167,0.085736,0.07895877,-0.06413424,-0.02686046,0.0023173054,-0.060560137,-0.006243795," +
            "0.041451767,0.0033143356,0.0007667367,0.0010536534,0.004274467,0.012899846,-0.002496665," +
            "-0.0051563564,0.0002692857"
        val samples = Chord.samples()
        val kotlin = (samples.indices step 997).map { samples[it] }
        swift.split(",").map(String::toFloat).zip(kotlin).forEach { (expected, actual) ->
            assertEquals(expected, actual, 1e-6f)
        }
        assertEquals(swift.split(",").size, kotlin.size)
    }
}
