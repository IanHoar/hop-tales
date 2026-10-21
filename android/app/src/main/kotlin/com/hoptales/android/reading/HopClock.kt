package com.hoptales.android.reading

class HopClock {
    private var started = 0.0
    private var lost = 0.0
    private var awaitingFirstFrame = false

    fun began(time: Double) {
        started = time
        lost = 0.0
        awaitingFirstFrame = true
    }

    fun time(now: Double): Double {
        if (awaitingFirstFrame) {
            awaitingFirstFrame = false
            lost = maxOf(0.0, now - started - FRAME_BUDGET)
        }
        return now - lost
    }

    companion object {
        const val FRAME_BUDGET = 1.0 / 30
    }
}
