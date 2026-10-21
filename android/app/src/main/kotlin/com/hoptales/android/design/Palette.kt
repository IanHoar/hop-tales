package com.hoptales.android.design

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

@Immutable
data class Palette(
    val outline: Color,
    val ink: Color,
    val parchment: Color,
    val parchmentLip: Color,
    val paper: Color,
    val page: Color,
    val muted: Color,
    val faint: Color,
    val heardBg: Color,
    val heardText: Color,
    val highlight: Color,
) {
    val red = Color(0xFFDB2A2E)
    val gold = Color(0xFFF6BB3E)
    val goldShade = Color(0xFFC7861A)
    val goldLight = Color(0xFFFFE39A)
    val teal = Color(0xFF1E8C8C)
    val tealShade = Color(0xFF136066)
    val onAccent = Color(0xFF1D1A2C)
    val onTeal = Color(0xFFFFF6E2)
    val pillText = Color(0xFF7A4A0C)
    val done = Color(0xFF8BD06A)
    val duskRoot = Color(0xFF1B1738)
    val duskShadow = Color(0x520C0A1E)

    companion object {
        val light = Palette(
            outline = Color(0xFF1D1A2C),
            ink = Color(0xFF1D1A2C),
            parchment = Color(0xFFFFF6E2),
            parchmentLip = Color(0xFFEBD5A6),
            paper = Color(0xFFFFFBF1),
            page = Color(0xFFF7E9C8),
            muted = Color(0xFF665F78),
            faint = Color(0xFF8A8499),
            heardBg = Color(0xFFE4F6D2),
            heardText = Color(0xFF1D1A2C),
            highlight = Color(0xD9FFFFFF),
        )

        val dark = Palette(
            outline = Color(0xFF07060D),
            ink = Color(0xFFFFF3D6),
            parchment = Color(0xFF2E2844),
            parchmentLip = Color(0xFF1C1729),
            paper = Color(0xFF352E4E),
            page = Color(0xFF1B1728),
            muted = Color(0xFFB9B2CB),
            faint = Color(0xFF918AA6),
            heardBg = Color(0xFF27402A),
            heardText = Color(0xFFE4F6D2),
            highlight = Color(0x29FFFFFF),
        )
    }
}

val LocalPalette = staticCompositionLocalOf { Palette.light }
