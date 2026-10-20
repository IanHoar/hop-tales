package com.hoptales.android.design

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.world.Sticker

@Composable
fun PaperChip(modifier: Modifier = Modifier, onClick: (() -> Unit)? = null, content: @Composable () -> Unit) {
    val palette = LocalPalette.current
    if (onClick != null) {
        Surface(
            onClick = onClick,
            modifier = modifier.heightIn(min = 48.dp),
            shape = CircleShape,
            color = palette.parchment,
            border = BorderStroke(3.dp, palette.outline),
            shadowElevation = 2.dp,
            content = content,
        )
    } else {
        Surface(
            modifier = modifier.heightIn(min = 48.dp),
            shape = CircleShape,
            color = palette.parchment,
            border = BorderStroke(3.dp, palette.outline),
            shadowElevation = 2.dp,
            content = content,
        )
    }
}

@Composable
fun StarChip(stars: Int, modifier: Modifier = Modifier) {
    val palette = LocalPalette.current
    PaperChip(modifier) {
        Row(Modifier.padding(horizontal = 14.dp), verticalAlignment = Alignment.CenterVertically) {
            Sticker("collect-star", Modifier.size(24.dp))
            Spacer(Modifier.width(6.dp))
            Text("$stars", style = LocalTypography.current.display(18.sp), color = palette.ink)
        }
    }
}
