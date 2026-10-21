package com.hoptales.android.design

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

@Immutable
data class Paper(
    val ink: Color,
    val paper: Color,
    val shade: Color,
    val page: Color,
    val sage: Color,
    val sageDeep: Color,
    val wash: Color,
    val washRing: Color,
    val muted: Color,
    val rim: Color,
    val redInk: Color,
) {
    val red = Color(0xFFB8423A)
    val onRed = Color(0xFFFFFFFF)
    val night = Color(0xFF1E2A4E)
    val shadow = Color(0x423C2814)

    companion object {
        val light = Paper(
            ink = Color(0xFF3B2A20),
            paper = Color(0xFFFBF4E4),
            shade = Color(0xFFEFE3C8),
            page = Color(0xFFF4EBD8),
            sage = Color(0xFFA6BA92),
            sageDeep = Color(0xFF7E9A6A),
            wash = Color(0xFFF7D774),
            washRing = Color(0xFFB8862E),
            muted = Color(0xFF9C8B78),
            rim = Color(0xFFFFFFFF),
            redInk = Color(0xFFB8423A),
        )

        val dark = Paper(
            ink = Color(0xFFF4EBD8),
            paper = Color(0xFF25305A),
            shade = Color(0xFF1B2448),
            page = Color(0xFF161E3A),
            sage = Color(0xFF5E7A58),
            sageDeep = Color(0xFF8FAE7A),
            wash = Color(0xFF7A6326),
            washRing = Color(0xFFD9A94A),
            muted = Color(0xFFC4BDD6),
            rim = Color(0xFF3A4674),
            redInk = Color(0xFFF59A90),
        )
    }
}

val LocalPaper = staticCompositionLocalOf { Paper.light }
