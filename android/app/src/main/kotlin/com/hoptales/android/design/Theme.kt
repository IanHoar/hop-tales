package com.hoptales.android.design

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import com.hoptales.content.Profile

@Composable
fun HopTalesTheme(dark: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val palette = if (dark) Palette.dark else Palette.light
    val paper = if (dark) Paper.dark else Paper.light
    val assets = LocalContext.current.assets
    val density = LocalDensity.current
    val typography = remember(assets, density) { Typography(assets, density) }
    val colors = if (dark) {
        darkColorScheme(primary = palette.teal, background = palette.page, surface = palette.parchment, onSurface = palette.ink)
    } else {
        lightColorScheme(primary = palette.teal, background = palette.page, surface = palette.parchment, onSurface = palette.ink)
    }
    CompositionLocalProvider(LocalPalette provides palette, LocalPaper provides paper, LocalTypography provides typography) {
        MaterialTheme(colorScheme = colors, content = content)
    }
}

@Composable
fun HopTalesTheme(theme: Profile.Theme, content: @Composable () -> Unit) {
    HopTalesTheme(dark = theme.isDark(isSystemInDarkTheme()), content = content)
}
