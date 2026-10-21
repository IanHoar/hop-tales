package com.hoptales.android.design

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun Modifier.paperChip(shape: Shape, fill: Color = LocalPaper.current.paper, rim: Dp = 4.dp, shadow: Float = 1f): Modifier {
    val paper = LocalPaper.current
    return dropShadow(shape, Shadow(4.dp * shadow, paper.shadow, offset = DpOffset(0.dp, 3.dp * shadow)))
        .background(fill, shape)
        .border(rim, paper.rim, shape)
}

@Composable
fun Modifier.pressable(onClick: () -> Unit, role: Role = Role.Button, enabled: Boolean = true): Modifier {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    return scale(if (pressed) 0.97f else 1f).clickable(interaction, indication = null, enabled = enabled, role = role, onClick = onClick)
}

@Composable
fun PaperChip(
    modifier: Modifier = Modifier,
    height: Dp = 42.dp,
    rim: Dp = 3.dp,
    onClick: (() -> Unit)? = null,
    content: @Composable RowScope.() -> Unit,
) {
    Row(
        modifier
            .then(if (onClick != null) Modifier.pressable(onClick) else Modifier)
            .height(height)
            .paperChip(CircleShape, rim = rim)
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
        content = content,
    )
}

@Composable
fun BackChip(modifier: Modifier = Modifier, description: String = "Back to stories", onClick: () -> Unit) {
    val paper = LocalPaper.current
    Box(
        modifier
            .size(48.dp)
            .semantics { contentDescription = description }
            .pressable(onClick),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            Modifier.size(40.dp).paperChip(CircleShape, fill = paper.paper.copy(alpha = 0.72f), rim = 3.dp, shadow = 0.67f),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Glyphs.chevronLeft, contentDescription = null, tint = paper.ink, modifier = Modifier.size(19.dp))
        }
    }
}

@Composable
fun PaperStar(size: Dp, modifier: Modifier = Modifier) {
    val paper = LocalPaper.current
    val star = remember { Star() }
    Canvas(modifier.size(size)) {
        val outline = star.createOutline(this.size, layoutDirection, this)
        drawOutline(outline, paper.wash)
        drawOutline(outline, paper.washRing, style = Stroke(maxOf(1.dp.toPx(), this.size.width * 0.07f)))
    }
}

@Composable
fun StarChip(stars: Int, modifier: Modifier = Modifier, prefix: String = "", height: Dp = 48.dp) {
    val paper = LocalPaper.current
    Row(
        modifier
            .clearAndSetSemantics { contentDescription = "$stars stars" }
            .height(height)
            .paperChip(CircleShape)
            .padding(start = 12.dp, end = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(7.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        PaperStar(21.dp)
        Text("$prefix$stars", style = LocalTypography.current.display(18.sp), color = paper.ink)
    }
}

@Composable
fun PaperButton(text: String, modifier: Modifier = Modifier, icon: ImageVector? = null, enabled: Boolean = true, onClick: () -> Unit) {
    val paper = LocalPaper.current
    val shape = RoundedCornerShape(28.dp)
    Box(
        modifier
            .fillMaxWidth()
            .height(56.dp)
            .alpha(if (enabled) 1f else 0.5f)
            .pressable(onClick, enabled = enabled)
            .dropShadow(shape, Shadow(5.dp, paper.shadow, offset = DpOffset(0.dp, 4.dp)))
            .background(paper.rim, shape)
            .padding(4.dp)
            .background(paper.red, RoundedCornerShape(24.dp)),
        contentAlignment = Alignment.Center,
    ) {
        IconLabel(text, icon, paper.onRed)
    }
}

@Composable
fun PaperQuietButton(text: String, modifier: Modifier = Modifier, icon: ImageVector? = null, onClick: () -> Unit) {
    Box(
        modifier
            .fillMaxWidth()
            .height(56.dp)
            .pressable(onClick)
            .paperChip(RoundedCornerShape(28.dp)),
        contentAlignment = Alignment.Center,
    ) {
        IconLabel(text, icon, LocalPaper.current.ink)
    }
}

@Composable
private fun IconLabel(text: String, icon: ImageVector?, colour: Color) {
    Row(
        Modifier.padding(horizontal = 28.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) Icon(icon, contentDescription = null, tint = colour, modifier = Modifier.size(20.dp))
        Text(text, style = LocalTypography.current.ui(18.sp), color = colour)
    }
}
