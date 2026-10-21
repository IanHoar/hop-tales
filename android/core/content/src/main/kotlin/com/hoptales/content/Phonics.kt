package com.hoptales.content

import kotlinx.serialization.Serializable

data class SoundMark(val start: Int, val end: Int, val kind: Kind) {
    enum class Kind { BUTTON, BAR, SPLIT }
}

class Phonics(table: Table) {
    @Serializable
    data class Level(
        val level: Int,
        val phase: String,
        val graphemes: List<String>,
        val endGraphemes: List<String>,
        val heartWords: List<String>,
    )

    @Serializable
    data class Rules(val clusters: Int, val splitDigraphs: Int, val endings: Int, val syllables: Int, val vowelY: Int)

    @Serializable
    data class Table(val names: List<String>, val rules: Rules, val levels: List<Level>)

    internal data class Token(val grapheme: String, val level: Int, val isVowel: Boolean)

    internal data class Placed(val token: Token, val start: Int)

    val levels: List<Level> = table.levels
    val names: List<String> = table.names
    private val rules = table.rules
    private val graphemes = table.levels.flatMap { level -> level.graphemes.map { it to level.level } }.toMap()
    private val ends = table.levels.flatMap { level -> level.endGraphemes.map { it to level.level } }.toMap()
    internal val heart: Map<String, Int> =
        table.levels.flatMap { level -> level.heartWords.map { it to level.level } }.toMap() + table.names.associate { it.lowercase() to 1 }
    private val byLength = graphemes.keys.sortedWith(longestFirst)
    private val endsByLength = ends.keys.sortedWith(longestFirst)

    fun phase(level: Int): String? = levels.firstOrNull { it.level == level }?.phase

    fun level(word: String): Int? {
        val lower = word.lowercase()
        return listOfNotNull(heart[lower], decoded(lower)).minOrNull()
    }

    fun soundMarks(word: String): List<SoundMark>? {
        val lower = word.lowercase()
        if (heart[lower] != null || level(lower) == null) return null
        if (lower.endsWith("ed") && endingBases(lower) != null) {
            val base = lower.dropLast(2)
            val marks = marks(base) ?: return null
            return marks + SoundMark(base.length, lower.length, SoundMark.Kind.BAR)
        }
        return marks(lower)
    }

    private fun marks(word: String): List<SoundMark>? = tokens(word)?.map { (token, start) ->
        when {
            token.grapheme.endsWith("_e") -> SoundMark(start, start + 3, SoundMark.Kind.SPLIT)
            token.grapheme.length == 1 -> SoundMark(start, start + 1, SoundMark.Kind.BUTTON)
            else -> SoundMark(start, start + token.grapheme.length, SoundMark.Kind.BAR)
        }
    }

    private fun decoded(word: String): Int? {
        val bases = endingBases(word) ?: return segmented(word)
        val base = bases.mapNotNull { level(it) }.minOrNull() ?: return null
        return maxOf(rules.endings, base)
    }

    internal fun endingBases(word: String): List<String>? {
        for (suffix in listOf("ing", "ed")) {
            if (!word.endsWith(suffix)) continue
            val base = word.dropLast(suffix.length)
            if (base.none { it in VOWELS } || base.endsWith("e")) continue
            val bases = when {
                base.endsWith("c") || base.endsWith("dg") || base.endsWith("v") -> mutableListOf(base + "e")
                split(base + "e") != null -> mutableListOf(base, base + "e")
                else -> mutableListOf(base)
            }
            if (base.length > 2 && base[base.length - 1] == base[base.length - 2]) bases += base.dropLast(1)
            return bases
        }
        val base = word.dropLast(2)
        if (word.endsWith("es") && listOf("ss", "x", "z", "ch", "sh").any { base.endsWith(it) }) return listOf(base)
        return null
    }

    private fun split(word: String): Int? {
        if (word.length <= 2) return null
        for (index in 0 until word.length - 2) {
            val vowel = word[index]
            val consonant = word[index + 1]
            val before = word.getOrNull(index - 1)
            val afterQu = index >= 2 && word.substring(index - 2, index) == "qu"
            val opens = (before?.let { it !in VOWELS } ?: true) || afterQu
            val tail = word.substring(index + 3)
            if (vowel in VOWELS && opens && consonant !in VOWELS && consonant !in "rwxy" && word[index + 2] == 'e' &&
                tail in SILENT_E_TAILS
            ) {
                return index
            }
        }
        return null
    }

    internal fun tokens(word: String): List<Placed>? {
        val split = split(word)
        val tokens = mutableListOf<Placed>()
        var position = 0
        while (position < word.length) {
            if (position == split) {
                tokens += Placed(Token("${word[position]}_e", rules.splitDigraphs, isVowel = true), position)
                position += 1
                continue
            }
            if (split != null && position == split + 2) {
                position += 1
                continue
            }
            val rest = word.substring(position)
            var token = endToken(rest, position, word, split) ?: graphemeToken(rest, position, split) ?: return null
            if (token.grapheme == "y" && position > 0 && tokens.lastOrNull()?.token?.isVowel == false) {
                token = Token("y", rules.vowelY, isVowel = true)
            }
            tokens += Placed(token, position)
            position += token.grapheme.length
        }
        return tokens
    }

    private fun segmented(word: String): Int? {
        val tokens = tokens(word)?.map { it.token } ?: return null
        var level = tokens.maxOfOrNull { it.level } ?: return null
        val pairs = tokens.zipWithNext().toMutableList()
        if (pairs.isNotEmpty() && word.endsWith("s") && tokens.last().grapheme == "s") pairs.removeAt(pairs.lastIndex)
        if (pairs.any { (first, second) -> !first.isVowel && !second.isVowel }) level = maxOf(level, rules.clusters)
        if (tokens.count { it.isVowel } > 1) level = maxOf(level, rules.syllables)
        return level
    }

    private fun endToken(rest: String, position: Int, word: String, split: Int?): Token? {
        if (position <= 0 || split != null) return null
        for (grapheme in endsByLength) {
            if (!rest.startsWith(grapheme)) continue
            val follows = grapheme != "le" || word[position - 1] !in VOWELS
            val tail = rest.substring(grapheme.length)
            val level = ends[grapheme]
            if (follows && tail in END_TAILS && level != null) return Token(grapheme, level, isVowel = grapheme == "le")
        }
        return null
    }

    private fun graphemeToken(rest: String, position: Int, split: Int?): Token? {
        for (grapheme in byLength) {
            if (!rest.startsWith(grapheme)) continue
            val end = position + grapheme.length
            if (split != null && position <= split + 2 && split + 2 < end) continue
            val level = graphemes[grapheme] ?: continue
            val isVowel = grapheme.any { it in VOWELS } && grapheme !in CONSONANT_UNITS
            return Token(grapheme, level, isVowel)
        }
        return null
    }

    companion object {
        const val STANDARD = "Reading levels are based on the UFLI Foundations phonics sequence."

        private val VOWELS = setOf('a', 'e', 'i', 'o', 'u')
        private val SILENT_E_TAILS = setOf("", "s", "d", "r", "ly", "ful", "less", "ment", "ness", "st")
        private val END_TAILS = setOf("", "s", "d")
        private val CONSONANT_UNITS = setOf("qu", "dge", "ce", "ge", "ve")
        private val longestFirst = compareByDescending<String> { it.length }.thenByDescending { it }

        fun decode(json: String): Phonics = Phonics(StoryLibrary.json.decodeFromString(Table.serializer(), json))
    }
}
