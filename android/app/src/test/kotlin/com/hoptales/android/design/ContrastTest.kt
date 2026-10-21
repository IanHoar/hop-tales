package com.hoptales.android.design

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.graphics.luminance
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ContrastTest {
    private val palette = Palette.dark
    private val paper = Paper.dark
    private val storyRow = paper.rim.copy(alpha = 0.55f).compositeOver(paper.paper)

    private val pairs = listOf(
        Pair("ink on page", palette.ink to palette.page),
        Pair("ink on paper", palette.ink to palette.paper),
        Pair("ink on parchment", palette.ink to palette.parchment),
        Pair("muted on page", palette.muted to palette.page),
        Pair("muted on paper", palette.muted to palette.paper),
        Pair("muted on parchment", palette.muted to palette.parchment),
        Pair("heard word", palette.heardText to palette.heardBg),
        Pair("paper ink on paper", paper.ink to paper.paper),
        Pair("paper ink on page", paper.ink to paper.page),
        Pair("paper ink on shade", paper.ink to paper.shade),
        Pair("paper ink on a card", paper.ink to paper.rim),
        Pair("paper ink on a story row", paper.ink to storyRow),
        Pair("paper muted on paper", paper.muted to paper.paper),
        Pair("paper muted on page", paper.muted to paper.page),
        Pair("paper muted on a card", paper.muted to paper.rim),
        Pair("paper muted on a story row", paper.muted to storyRow),
        Pair("New on a story row", paper.redInk to storyRow),
        Pair("white on red", paper.onRed to paper.red),
        Pair("next tag", paper.ink to paper.wash),
        Pair("microphone allowed", paper.sageDeep to palette.paper),
    )

    @Test
    fun darkTextMeetsAA() {
        val failures = pairs.map { (name, colours) -> name to ratio(colours.first, colours.second) }.filter { it.second < AA }
        assertTrue("Below 4.5:1 — $failures", failures.isEmpty())
    }

    @Test
    fun ratioFollowsWcag() {
        assertEquals(21.0, ratio(Color.Black, Color.White), 0.01)
        assertEquals(4.48, ratio(Color(0xFF777777), Color.White), 0.01)
    }

    private fun ratio(foreground: Color, background: Color): Double {
        val front = foreground.compositeOver(background).luminance() + 0.05
        val back = background.luminance() + 0.05
        return (maxOf(front, back) / minOf(front, back)).toDouble()
    }

    private companion object {
        const val AA = 4.5
    }
}
