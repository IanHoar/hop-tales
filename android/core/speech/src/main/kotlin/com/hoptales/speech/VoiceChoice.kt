package com.hoptales.speech

data class VoiceCandidate(val id: String, val languageTag: String, val quality: Int, val latency: Int)

object VoiceChoice {
    fun best(candidates: List<VoiceCandidate>, accentTag: String): VoiceCandidate? {
        val accent = normalized(accentTag)
        return candidates
            .filter { normalized(it.languageTag).substringBefore('-') == "en" }
            .sortedWith(
                compareByDescending<VoiceCandidate> { normalized(it.languageTag) == accent }
                    .thenByDescending { it.quality }
                    .thenBy { it.latency }
                    .thenBy { it.id },
            )
            .firstOrNull()
    }

    private fun normalized(tag: String) = tag.replace('_', '-').lowercase()
}
