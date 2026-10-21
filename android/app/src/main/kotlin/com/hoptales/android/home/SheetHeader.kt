package com.hoptales.android.home

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalTypography

@Composable
fun SheetHeader(title: String, done: () -> Unit, accessory: @Composable RowScope.() -> Unit = {}) {
    val palette = LocalPalette.current
    Row(
        Modifier.fillMaxWidth().windowInsetsPadding(WindowInsets.statusBars).padding(horizontal = 20.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            title,
            style = LocalTypography.current.display(26.sp),
            color = palette.ink,
            modifier = Modifier.weight(1f).semantics { heading() },
        )
        accessory()
        HeaderButton(onClick = done) {
            Text(
                "Done",
                style = LocalTypography.current.display(17.sp),
                color = palette.ink,
                modifier = Modifier.padding(horizontal = 16.dp),
            )
        }
    }
}

@Composable
fun HeaderButton(onClick: () -> Unit, modifier: Modifier = Modifier, label: String? = null, content: @Composable () -> Unit) {
    val palette = LocalPalette.current
    Surface(
        onClick = onClick,
        modifier = modifier.height(44.dp).semantics { if (label != null) contentDescription = label },
        shape = CircleShape,
        color = palette.parchment,
        border = BorderStroke(3.dp, palette.outline),
        shadowElevation = 2.dp,
    ) {
        Box(Modifier.padding(horizontal = 2.dp), contentAlignment = Alignment.Center) { content() }
    }
}

@Composable
fun MapButton(onClick: () -> Unit) {
    HeaderButton(onClick, Modifier.size(44.dp), label = "Your journey") { MapGlyph(LocalPalette.current.ink) }
}
