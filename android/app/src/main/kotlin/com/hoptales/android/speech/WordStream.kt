package com.hoptales.android.speech

class WordStream {
    private var sent: List<String> = emptyList()
    private var previous: List<String> = emptyList()

    fun partial(tokens: List<String>): List<String> {
        val stable = tokens.filterIndexed { index, word -> previous.getOrNull(index) == word }
        previous = tokens
        return fresh(stable)
    }

    fun result(tokens: List<String>): List<String> {
        val words = fresh(tokens)
        sent = emptyList()
        previous = emptyList()
        return words
    }

    private fun fresh(tokens: List<String>): List<String> {
        if (tokens.isEmpty()) return emptyList()
        val prefix = sent.size.takeIf { tokens.size >= it && tokens.take(it) == sent } ?: 0
        if (tokens.size > sent.size || prefix == 0) sent = tokens
        return tokens.drop(prefix)
    }
}
