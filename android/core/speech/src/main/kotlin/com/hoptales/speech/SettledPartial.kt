package com.hoptales.speech

class SettledPartial(private val settledAfterMillis: Long = SETTLED_AFTER_MILLIS) {
    private var latest: List<String> = emptyList()
    private var changedAt = 0L
    private var repeated: List<String> = emptyList()

    fun heard(tokens: List<String>, now: Long) {
        if (tokens != latest) changedAt = now
        latest = tokens
    }

    fun settled(now: Long): List<String>? {
        if (latest.isEmpty() || latest == repeated || now - changedAt < settledAfterMillis) return null
        repeated = latest
        return latest
    }

    companion object {
        const val SETTLED_AFTER_MILLIS = 250L
        const val STABILITY_TICK_MILLIS = 50L
    }
}
