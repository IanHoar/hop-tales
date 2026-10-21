package com.hoptales.speech

enum class ListenEnd { FINISHED, INTERRUPTED, FAILED }

object Relisten {
    const val AFTER_END_MILLIS = 150L
    const val AFTER_FAILURE_MILLIS = 1_000L
    const val RELEASE_AUDIO_AFTER_MILLIS = 3_000L

    fun after(end: ListenEnd): Long = when (end) {
        ListenEnd.FINISHED, ListenEnd.INTERRUPTED -> AFTER_END_MILLIS
        ListenEnd.FAILED -> AFTER_FAILURE_MILLIS
    }
}

object OnDeviceSupport {
    fun supports(localeTag: String, installed: Collection<String>): Boolean {
        val wanted = normalized(localeTag)
        return installed.any { normalized(it) == wanted }
    }

    private fun normalized(tag: String) = tag.replace('_', '-').lowercase()
}
