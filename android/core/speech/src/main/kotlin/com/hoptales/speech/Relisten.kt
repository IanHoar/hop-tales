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
    const val FALLBACK_TAG = "en-US"

    fun listeningTag(accentTag: String, installed: Collection<String>): String? {
        val english = installed.filter { normalized(it).substringBefore('-') == "en" }
        return english.firstOrNull { normalized(it) == normalized(accentTag) }
            ?: english.firstOrNull { normalized(it) == normalized(FALLBACK_TAG) }
            ?: english.minByOrNull { normalized(it) }
    }

    private fun normalized(tag: String) = tag.replace('_', '-').lowercase()
}
