package com.hoptales.android.design

import android.content.res.AssetManager
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp

@Immutable
class Typography(assets: AssetManager, private val density: Density = Density(1f)) {
    val wordFamily = FontFamily(Font("Fonts/YoungSerif-Regular.ttf", assets))
    val displayFamily = FontFamily(Font("Fonts/Fraunces-Bold.ttf", assets, FontWeight.Bold))
    val uiFamily = FontFamily(
        Font("Fonts/Fredoka-Medium.ttf", assets, FontWeight.Medium),
        Font("Fonts/Fredoka-SemiBold.ttf", assets, FontWeight.SemiBold),
        Font("Fonts/Fredoka-Bold.ttf", assets, FontWeight.Bold),
    )

    fun fixed(size: TextUnit): TextUnit = with(density) { size.value.dp.toSp() }

    fun word(size: TextUnit) = TextStyle(fontFamily = wordFamily, fontSize = fixed(size), letterSpacing = (-0.01).em)

    fun display(size: TextUnit) = TextStyle(fontFamily = displayFamily, fontWeight = FontWeight.Bold, fontSize = fixed(size))

    fun ui(size: TextUnit, weight: FontWeight = FontWeight.SemiBold) =
        TextStyle(fontFamily = uiFamily, fontWeight = weight, fontSize = size)

    fun caps(size: TextUnit) =
        TextStyle(fontFamily = uiFamily, fontWeight = FontWeight.SemiBold, fontSize = fixed(size), letterSpacing = 0.16.em)

    companion object {
        val body = 17.sp
    }
}

val LocalTypography = staticCompositionLocalOf<Typography> { error("No Typography provided") }
