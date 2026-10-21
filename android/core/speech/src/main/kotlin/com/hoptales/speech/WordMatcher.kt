package com.hoptales.speech

import com.hoptales.content.Word

enum class Strictness { GENTLE, STANDARD }

object WordMatcher {
    enum class Target { CURRENT, NEXT }

    data class Match(val target: Target, val token: String)

    internal val soundsAlike: Map<String, Set<String>> = mapOf(
        "the" to setOf("a", "uh", "duh", "da", "de", "dee", "thee", "thuh", "they", "then"),
        "a" to setOf("ay", "ah", "eh", "uh", "ea", "ear", "eara", "era", "hey", "oh", "o"),
        "bee" to setOf("be", "bea"),
        "on" to setOf("oh", "awn", "ahn", "own"),
    )

    internal val letterNames: Map<String, Set<String>> = mapOf(
        "a" to setOf("a"), "b" to setOf("bee", "be"), "c" to setOf("see", "sea"), "d" to setOf("dee"),
        "g" to setOf("gee"), "i" to setOf("i", "eye"), "j" to setOf("jay"), "k" to setOf("kay"),
        "o" to setOf("oh", "owe"), "p" to setOf("pea", "pee"), "q" to setOf("queue"), "r" to setOf("are"),
        "t" to setOf("tea", "tee"), "u" to setOf("you"), "y" to setOf("why"),
    )

    private val vowels = "aeiouy".toSet()

    private val voicing = mapOf(
        't' to 'd',
        'd' to 't',
        'p' to 'b',
        'b' to 'p',
        'k' to 'g',
        'g' to 'k',
        's' to 'z',
        'z' to 's',
    )

    private val spelledNumbers = mapOf(
        "0" to "zero", "1" to "one", "2" to "two", "3" to "three", "4" to "four", "5" to "five",
        "6" to "six", "7" to "seven", "8" to "eight", "9" to "nine", "10" to "ten",
    )

    fun normalize(transcript: String): List<String> = transcript
        .lowercase()
        .replace("’", "")
        .replace("'", "")
        .split(Regex("\\s+"))
        .map { it.trim { character -> !character.isLetterOrDigit() } }
        .filter { it.isNotEmpty() }
        .map { spelledNumbers[it] ?: it }

    fun match(tokens: List<String>, current: Word, next: Word?, strictness: Strictness = Strictness.GENTLE): Match? {
        val tail = tokens.takeLast(3)
        if (tail.isEmpty()) return null

        if (next != null) {
            tail.asReversed().firstOrNull { accepts(it, next, strictness) }
                ?.let { return Match(Target.NEXT, it) }
        }
        return tail.asReversed().firstOrNull { accepts(it, current, strictness) }
            ?.let { Match(Target.CURRENT, it) }
    }

    internal fun collapsed(token: String): String {
        val result = StringBuilder()
        for (character in token) if (result.lastOrNull() != character) result.append(character)
        return result.toString()
    }

    internal fun accepts(token: String, target: Word, strictness: Strictness): Boolean {
        val text = normalize(target.text).joinToString("")
        if (token.isEmpty() || text.isEmpty()) return false
        val heard = if (token.length > 1 && collapsed(token).length == 1) collapsed(token) else token
        if (letterNames[heard]?.contains(text) == true) return true

        if (heard == text) return true
        if (text.length >= 4 && levenshtein(heard, text) <= 1) return true
        if (strictness != Strictness.GENTLE) return false

        val squeezed = collapsed(heard)
        for (candidate in setOf(heard, squeezed)) {
            if (candidate.length == text.length && candidate.take(2) == text.take(2)) return true
        }
        if (target.homophones.any { it.lowercase() == heard }) return true
        if (soundsAlike[text]?.contains(heard) == true) return true
        if (soundsAlike[text]?.contains(collapsed(heard)) == true) return true
        return soundsLikeShortWord(heard, text) || soundsLikeShortWord(squeezed, text)
    }

    internal fun soundsLikeShortWord(token: String, text: String): Boolean {
        if (text.length != 3) return false
        val opens = text[0] == 'y' || text[0] !in vowels
        if (!opens || text[1] !in vowels || text[2] in vowels) return false
        if (token.length !in 3..4) return false
        if (token.first() != text[0]) return false
        if (token.last() != text[2] && token.last() != voicing[text[2]]) return false
        return token.drop(1).dropLast(1).all { it in vowels }
    }

    internal fun levenshtein(lhs: String, rhs: String): Int {
        if (lhs.isEmpty()) return rhs.length
        if (rhs.isEmpty()) return lhs.length
        var previous = IntArray(rhs.length + 1) { it }
        var current = IntArray(rhs.length + 1)
        for (i in 1..lhs.length) {
            current[0] = i
            for (j in 1..rhs.length) {
                val substitution = previous[j - 1] + if (lhs[i - 1] == rhs[j - 1]) 0 else 1
                current[j] = minOf(previous[j] + 1, current[j - 1] + 1, substitution)
            }
            previous = current.also { current = previous }
        }
        return previous[rhs.length]
    }
}
