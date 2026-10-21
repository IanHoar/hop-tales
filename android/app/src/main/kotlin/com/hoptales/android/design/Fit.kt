package com.hoptales.android.design

import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.foundation.text.modifiers.TextAutoSizeLayoutScope
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp

@Composable
fun FitText(text: String, style: TextStyle, color: Color, minimumScale: Float, modifier: Modifier = Modifier) {
    BasicText(
        text,
        modifier,
        style = style.copy(color = color),
        maxLines = 1,
        overflow = TextOverflow.Clip,
        softWrap = false,
        autoSize = ShrinkToFit(style.fontSize, minimumScale),
    )
}

private data class ShrinkToFit(val largest: TextUnit, val minimumScale: Float) : TextAutoSize {
    override fun TextAutoSizeLayoutScope.getFontSize(constraints: Constraints, text: AnnotatedString): TextUnit {
        if (!performLayout(constraints, text, largest).didOverflowWidth) return largest
        var fits = largest.toPx() * minimumScale
        var overflows = largest.toPx()
        repeat(SEARCH_STEPS) {
            val middle = (fits + overflows) / 2
            if (performLayout(constraints, text, middle.toSp()).didOverflowWidth) overflows = middle else fits = middle
        }
        return fits.toSp()
    }
}

@Composable
fun ChoicePair(modifier: Modifier = Modifier, spacing: Dp = 10.dp, content: @Composable () -> Unit) {
    Layout(content, modifier) { measurables, constraints ->
        val gap = spacing.roundToPx()
        val gaps = gap * (measurables.size - 1).coerceAtLeast(0)
        val ideal = measurables.sumOf { it.maxIntrinsicWidth(Constraints.Infinity) } + gaps
        val width = constraints.maxWidth
        if (ideal <= width && measurables.isNotEmpty()) {
            val each = (width - gaps) / measurables.size
            val placeables = measurables.map { it.measure(Constraints.fixedWidth(each)) }
            val height = placeables.maxOf { it.height }
            layout(width, height) {
                placeables.forEachIndexed { index, placeable -> placeable.place(index * (each + gap), 0) }
            }
        } else {
            val placeables = measurables.map { it.measure(Constraints.fixedWidth(width)) }
            val height = placeables.sumOf { it.height } + gaps
            layout(width, height) {
                var y = 0
                for (placeable in placeables) {
                    placeable.place(0, y)
                    y += placeable.height + gap
                }
            }
        }
    }
}

private const val SEARCH_STEPS = 8
