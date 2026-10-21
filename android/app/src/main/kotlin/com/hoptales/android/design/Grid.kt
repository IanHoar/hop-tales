package com.hoptales.android.design

import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp

private fun adaptiveColumns(available: Int, minimum: Int, maximum: Int, spacing: Int): Pair<Int, Int> {
    val count = maxOf(1, (available + spacing) / (minimum + spacing))
    val width = ((available - spacing * (count - 1)) / count).coerceIn(minimum.coerceAtMost(available), maxOf(minimum, maximum))
    return count to width
}

class AdaptiveCells(private val minimum: Dp, private val maximum: Dp = Dp.Infinity) : GridCells {
    override fun Density.calculateCrossAxisCellSizes(availableSize: Int, spacing: Int): List<Int> {
        val top = if (maximum == Dp.Infinity) Int.MAX_VALUE else maximum.roundToPx()
        val (count, width) = adaptiveColumns(availableSize, minimum.roundToPx(), top, spacing)
        return List(count) { width }
    }

    override fun equals(other: Any?) = other is AdaptiveCells && other.minimum == minimum && other.maximum == maximum

    override fun hashCode() = minimum.hashCode() * 31 + maximum.hashCode()
}

@Composable
fun AdaptiveGrid(minimum: Dp, spacing: Dp, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Layout(content, modifier) { measurables, constraints ->
        val gap = spacing.roundToPx()
        val available = constraints.maxWidth
        val (count, width) = adaptiveColumns(available, minimum.roundToPx(), Int.MAX_VALUE, gap)
        val placeables = measurables.map { it.measure(Constraints(maxWidth = width)) }
        val rows = placeables.chunked(count)
        val heights = rows.map { row -> row.maxOf { it.height } }
        val height = heights.sum() + gap * (rows.size - 1).coerceAtLeast(0)
        val used = width * count + gap * (count - 1)
        val inset = ((available - used) / 2).coerceAtLeast(0)
        layout(available, height) {
            var y = 0
            rows.forEachIndexed { index, row ->
                row.forEachIndexed { column, placeable ->
                    val x = inset + column * (width + gap) + (width - placeable.width) / 2
                    placeable.place(x, y + (heights[index] - placeable.height) / 2)
                }
                y += heights[index] + gap
            }
        }
    }
}
