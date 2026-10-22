package com.hoptales.android.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.Glyphs
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.Press
import com.hoptales.android.design.paperChip
import com.hoptales.android.design.paperField
import com.hoptales.android.design.pressable
import com.hoptales.android.home.DoneChip
import com.hoptales.android.home.PaperTitle
import kotlin.random.Random

data class GateQuestion(val left: Int, val right: Int) {
    val answer: Int get() = left * right

    val words: String get() = "What is ${NAMES[left]} times ${NAMES[right]}?"

    fun accepts(entry: String): Boolean = entry.toIntOrNull() == answer

    companion object {
        val FACTORS = 3..9
        const val ANSWER_DIGITS = 2

        private val NAMES = listOf("zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine")

        fun drawn(seed: Long, round: Int): GateQuestion {
            val draw = GateDraw(seed.toULong())
            var question = draw.question(after = null)
            repeat(round) { question = draw.question(after = question) }
            return question
        }
    }
}

private class GateDraw(private var state: ULong) {
    fun next(): ULong {
        state += 0x9E3779B97F4A7C15uL
        var mixed = state
        mixed = (mixed xor (mixed shr 30)) * 0xBF58476D1CE4E5B9uL
        mixed = (mixed xor (mixed shr 27)) * 0x94D049BB133111EBuL
        return mixed xor (mixed shr 31)
    }

    fun factor(): Int {
        val span = (GateQuestion.FACTORS.last - GateQuestion.FACTORS.first + 1).toULong()
        return GateQuestion.FACTORS.first + (next() % span).toInt()
    }

    fun question(after: GateQuestion?): GateQuestion {
        while (true) {
            val question = GateQuestion(factor(), factor())
            if (question != after) return question
        }
    }
}

data class ParentGateState(val seed: Long, val round: Int = 0, val entry: String = "", val passed: Boolean = false) {
    val question: GateQuestion get() = GateQuestion.drawn(seed, round)

    val canAnswer: Boolean get() = entry.isNotEmpty()

    fun digit(digit: Int): ParentGateState =
        if (digit in 0..9 && entry.length < GateQuestion.ANSWER_DIGITS) copy(entry = entry + digit) else this

    fun delete(): ParentGateState = copy(entry = entry.dropLast(1))

    fun checked(): ParentGateState = when {
        !canAnswer -> this
        question.accepts(entry) -> copy(passed = true)
        else -> copy(round = round + 1, entry = "")
    }

    companion object {
        fun drawing(): ParentGateState = ParentGateState(Random.nextLong())
    }
}

@Composable
fun ParentGate(onPassed: () -> Unit, onClose: () -> Unit, initial: ParentGateState = remember { ParentGateState.drawing() }) {
    var gate by remember { mutableStateOf(initial) }
    val paper = LocalPaper.current
    val type = LocalTypography.current
    Column(Modifier.fillMaxSize().background(paper.page)) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PaperTitle("For grown-ups")
            Spacer(Modifier.weight(1f))
            DoneChip(onClose, label = "Close")
        }
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(start = 24.dp, end = 24.dp, top = 8.dp, bottom = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(
                Modifier.widthIn(max = 420.dp).fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(18.dp),
            ) {
                Text(
                    "Ask a grown-up to answer this.",
                    style = type.ui(16.sp, FontWeight.Medium),
                    color = paper.muted,
                    textAlign = TextAlign.Center,
                )
                Text(
                    gate.question.words,
                    style = type.ui(26.sp, FontWeight.Bold),
                    color = paper.ink,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.semantics {
                        heading()
                        liveRegion = LiveRegionMode.Polite
                    },
                )
                Answer(gate.entry)
                Text(
                    "Here's a new one.",
                    style = type.ui(15.sp, FontWeight.Medium),
                    color = paper.muted,
                    modifier = Modifier.alpha(if (gate.round > 0) 1f else 0f).then(
                        if (gate.round > 0) Modifier else Modifier.clearAndSetSemantics {},
                    ),
                )
                Keypad(
                    canAnswer = gate.canAnswer,
                    onDigit = { gate = gate.digit(it) },
                    onDelete = { gate = gate.delete() },
                    onAnswer = {
                        val next = gate.checked()
                        if (next.passed) onPassed() else gate = next
                    },
                )
            }
        }
    }
}

@Composable
private fun Answer(entry: String) {
    val paper = LocalPaper.current
    Box(
        Modifier
            .width(150.dp)
            .clearAndSetSemantics {
                contentDescription = "Your answer"
                stateDescription = entry.ifEmpty { "Empty" }
            }.paperField(selected = false)
            .heightIn(min = 68.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            entry.ifEmpty { "?" },
            style = LocalTypography.current.ui(36.sp, FontWeight.Bold),
            color = if (entry.isEmpty()) paper.muted.copy(alpha = 0.5f) else paper.ink,
        )
    }
}

@Composable
private fun Keypad(canAnswer: Boolean, onDigit: (Int) -> Unit, onDelete: () -> Unit, onAnswer: () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        for (row in listOf(listOf(1, 2, 3), listOf(4, 5, 6), listOf(7, 8, 9))) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                for (digit in row) DigitKey(digit, onDigit)
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            GlyphKey(Glyphs.backspace, "Delete", onDelete)
            DigitKey(0, onDigit)
            GlyphKey(Glyphs.check, "Check answer", onAnswer, primary = true, enabled = canAnswer)
        }
    }
}

@Composable
private fun RowScope.DigitKey(digit: Int, onDigit: (Int) -> Unit) {
    Key("$digit", { onDigit(digit) }) {
        Text("$digit", style = LocalTypography.current.ui(28.sp), color = LocalPaper.current.ink)
    }
}

@Composable
private fun RowScope.GlyphKey(
    glyph: ImageVector,
    description: String,
    onClick: () -> Unit,
    primary: Boolean = false,
    enabled: Boolean = true,
) {
    val paper = LocalPaper.current
    Key(description, onClick, primary, enabled) {
        Icon(glyph, contentDescription = null, tint = if (primary) paper.onRed else paper.ink, modifier = Modifier.size(28.dp))
    }
}

@Composable
private fun RowScope.Key(
    description: String,
    onClick: () -> Unit,
    primary: Boolean = false,
    enabled: Boolean = true,
    face: @Composable () -> Unit,
) {
    val paper = LocalPaper.current
    Box(
        Modifier
            .weight(1f)
            .alpha(if (enabled) 1f else 0.5f)
            .semantics { contentDescription = description }
            .pressable(onClick, enabled = enabled, press = Press.PAPER)
            .heightIn(min = 60.dp)
            .paperChip(RoundedCornerShape(18.dp), fill = if (primary) paper.red else paper.paper, rim = 3.dp),
        contentAlignment = Alignment.Center,
    ) { face() }
}
