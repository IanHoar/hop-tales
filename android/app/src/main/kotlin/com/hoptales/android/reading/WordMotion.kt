package com.hoptales.android.reading

import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import com.hoptales.reading.HopTarget
import kotlin.math.floor

data class WordMove(val from: HopTarget, val to: HopTarget, val at: Double)

data class WordSpeech(val speaking: Boolean, val at: Double)

class WordMoves(position: HopTarget, speaking: Boolean) {
    var move = WordMove(position, position, Double.NEGATIVE_INFINITY)
        private set
    var speech = WordSpeech(speaking, Double.NEGATIVE_INFINITY)
        private set

    fun moved(position: HopTarget, now: Double): WordMove {
        if (position != move.to) move = WordMove(move.to, position, now)
        return move
    }

    fun spoke(speaking: Boolean, now: Double): WordSpeech {
        if (speaking != speech.speaking) speech = WordSpeech(speaking, now)
        return speech
    }
}

data class WordLook(
    val state: WordState,
    val ink: Color,
    val chalk: Color,
    val scale: Float,
    val wash: Float,
    val star: Float,
    val pop: Float,
    val rise: Float,
    val solidUnderline: Boolean,
)

object WordMotion {
    const val STATE_SECONDS = 0.3
    const val WASH_DELAY = 0.25
    const val WASH_SECONDS = 0.35
    const val PULSE_SCALE = 1.08f
    const val PULSE_SECONDS = 0.28
    const val PULSES = 3
    const val BIG_WORD_SCALE = 1.08f
    const val PUNCTUATION_ALPHA = 0.7f
    const val POP_SECONDS = 0.3
    const val FLOAT_DELAY = 0.1
    const val FLOAT_SECONDS = 0.9
    const val POP_FROM = 0.2f
    const val POP_TO = 0.9f
    const val SETTLE = FLOAT_DELAY + FLOAT_SECONDS

    val easeInOut = CubicBezierEasing(0.42f, 0f, 0.58f, 1f)
    val easeOut = CubicBezierEasing(0f, 0f, 0.58f, 1f)

    fun state(stop: HopTarget, position: HopTarget): WordState = when {
        stop < position -> WordState.READ
        stop == position -> WordState.CURRENT
        else -> WordState.UPCOMING
    }

    fun baseScale(state: WordState, isBig: Boolean): Float =
        (if (state == WordState.CURRENT) 1f else PathGeometry.SIDE_SCALE) * if (isBig) BIG_WORD_SCALE else 1f

    fun pulse(elapsed: Double): Float {
        if (elapsed >= PULSE_SECONDS * PULSES) return 1f
        val leg = floor(elapsed.coerceAtLeast(0.0) / PULSE_SECONDS)
        val eased = easeInOut.transform(((elapsed - leg * PULSE_SECONDS) / PULSE_SECONDS).toFloat().coerceIn(0f, 1f))
        return if (leg.toInt() % 2 == 0) eased else 1f - eased
    }

    fun look(stop: HopTarget, isBig: Boolean, move: WordMove, speech: WordSpeech, now: Double?): WordLook {
        val from = state(stop, move.from)
        val to = state(stop, move.to)
        val sinceMove = now?.let { (it - move.at).coerceAtLeast(0.0) } ?: Double.POSITIVE_INFINITY
        val sinceSpeech = now?.let { (it - speech.at).coerceAtLeast(0.0) } ?: Double.POSITIVE_INFINITY
        val change = easeInOut.transform(progress(sinceMove, 0.0, STATE_SECONDS))
        val washing = easeOut.transform(progress(sinceMove, WASH_DELAY, WASH_SECONDS))
        val pulsing = if (to == WordState.CURRENT) {
            val (start, end) = if (speech.speaking) 1f to PULSE_SCALE else PULSE_SCALE to 1f
            start + (end - start) * pulse(sinceSpeech)
        } else {
            1f
        }
        val scale = mix(baseScale(from, isBig), baseScale(to, isBig), change) * pulsing
        val wash = mix(if (from == WordState.READ) 1f else 0f, if (to == WordState.READ) 1f else 0f, washing)
        val popping = isBig && now != null && from != WordState.READ && to == WordState.READ
        val floated = easeOut.transform(progress(sinceMove, FLOAT_DELAY, FLOAT_SECONDS))
        val pop = if (popping) easeOut.transform(progress(sinceMove, 0.0, POP_SECONDS)) * (1f - floated) else 0f
        return WordLook(
            state = to,
            ink = lerp(from.ink, to.ink, change),
            chalk = lerp(from.chalk, to.chalk, change),
            scale = scale,
            wash = wash,
            star = if (to == WordState.READ) 0f else 1f,
            pop = pop,
            rise = POP_FROM + (POP_TO - POP_FROM) * floated,
            solidUnderline = to == WordState.READ && now == null,
        )
    }

    fun isSettled(move: WordMove, speech: WordSpeech, now: Double): Boolean =
        now - move.at >= SETTLE && now - speech.at >= PULSE_SECONDS * PULSES

    private fun progress(elapsed: Double, delay: Double, length: Double): Float = ((elapsed - delay) / length).toFloat().coerceIn(0f, 1f)

    private fun mix(start: Float, end: Float, fraction: Float) = start + (end - start) * fraction
}
