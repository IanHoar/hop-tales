package com.hoptales.android.speech

object Grammar {
    fun of(sentence: List<String>, decoys: List<String>): List<String> {
        val phrases = sentence.indices.map { sentence.drop(it).joinToString(" ") }
        val words = sentence.distinct()
        val others = decoys.distinct().filter { decoy -> words.none { overlaps(decoy, it) } }
        return phrases + words + others
    }

    private fun overlaps(decoy: String, word: String): Boolean =
        decoy == word || decoy.startsWith(word) || decoy.endsWith(word) || word.startsWith(decoy) || word.endsWith(decoy)
}
