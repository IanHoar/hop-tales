package com.hoptales.speech

class PartialDebouncer {
    private var previousTail: List<String> = emptyList()

    fun confirm(tokens: List<String>, isFinal: Boolean): List<String> {
        val tail = tokens.takeLast(3)
        val seenBefore = previousTail.toSet()
        previousTail = tail
        return if (isFinal) tail else tail.filter { it in seenBefore }
    }

    fun reset() {
        previousTail = emptyList()
    }
}
