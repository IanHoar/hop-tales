package com.hoptales.android.design

import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.addOutline
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp

fun Modifier.bevel(
    fill: Color,
    lip: Color,
    shape: Shape,
    outline: Color,
    highlight: Color,
    border: Dp = 3.dp,
    drop: Dp = 4.dp,
    lipHeight: Dp? = null,
    highlightInset: Dp = 16.dp,
    pressed: Boolean = false,
    rimShadow: Painter? = null,
): Modifier = offset(y = if (pressed) drop - 1.dp else 0.dp).drawWithContent {
    val path = Path().apply { addOutline(shape.createOutline(size, layoutDirection, this@drawWithContent)) }
    val border = border.toPx()
    val lipHeight = (lipHeight ?: (drop + 2.dp)).toPx()
    val inset = highlightInset.toPx()
    translate(top = if (pressed) 1.dp.toPx() else drop.toPx()) { drawPath(path, outline) }
    clipPath(path) {
        drawRect(fill)
        drawRect(lip, topLeft = Offset(0f, size.height - lipHeight), size = Size(size.width, lipHeight))
        drawRoundRect(
            highlight,
            topLeft = Offset(inset, border + 2.dp.toPx()),
            size = Size(size.width - inset * 2, 3.dp.toPx()),
            cornerRadius = CornerRadius(1.5.dp.toPx()),
        )
    }
    drawContent()
    if (rimShadow != null) drawShadow(rimShadow)
    clipPath(path) { drawPath(path, outline, style = Stroke(border * 2)) }
}

enum class InkKind { PRIMARY, SECONDARY, TERTIARY }

@Composable
fun InkButton(text: String, kind: InkKind, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val palette = LocalPalette.current
    val (fill, lip, label) = when (kind) {
        InkKind.PRIMARY -> Triple(palette.gold, palette.goldShade, palette.onAccent)
        InkKind.SECONDARY -> Triple(palette.teal, palette.tealShade, palette.onTeal)
        InkKind.TERTIARY -> Triple(palette.parchment, palette.parchmentLip, palette.ink)
    }
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    Box(
        modifier
            .heightIn(min = 58.dp)
            .bevel(fill, lip, CircleShape, palette.outline, palette.highlight, drop = 5.dp, pressed = pressed)
            .clickable(interaction, indication = null, role = Role.Button, onClick = onClick)
            .padding(horizontal = 22.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(text, style = LocalTypography.current.display(19.sp).copy(letterSpacing = 0.03.em), color = label)
    }
}
