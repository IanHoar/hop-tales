package com.hoptales.android.design

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.toggleableState
import androidx.compose.ui.state.ToggleableState
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

val Palette.field: Color get() = parchmentLip.copy(alpha = 0.6f).compositeOver(paper)

@Composable
fun PaperChoice(title: String, selected: Boolean, modifier: Modifier = Modifier, detail: String? = null, onClick: () -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    ChoiceSurface(selected, modifier, onClick) {
        Text(title, style = type.display(19.sp), color = palette.ink)
        if (detail != null) Text(detail, style = type.ui(14.sp), color = palette.muted)
    }
}

@Composable
fun ChoiceSurface(selected: Boolean, modifier: Modifier = Modifier, onClick: (() -> Unit)?, content: @Composable ColumnScope.() -> Unit) {
    val palette = LocalPalette.current
    val shape = RoundedCornerShape(18.dp)
    val color = if (selected) palette.red.copy(alpha = 0.1f).compositeOver(palette.paper) else palette.field
    val border = BorderStroke(3.dp, if (selected) palette.red else palette.parchmentLip)
    val body: @Composable () -> Unit = {
        Column(Modifier.padding(horizontal = 16.dp, vertical = 14.dp), verticalArrangement = Arrangement.spacedBy(2.dp), content = content)
    }
    if (onClick != null) {
        Surface(
            onClick = onClick,
            modifier = modifier.fillMaxWidth().semantics { this.selected = selected },
            shape = shape,
            color = color,
            border = border,
            shadowElevation = 1.dp,
            content = body,
        )
    } else {
        Surface(modifier.fillMaxWidth(), shape = shape, color = color, border = border, shadowElevation = 1.dp, content = body)
    }
}

@Composable
fun PaperToggle(title: String, detail: String, checked: Boolean, onChange: (Boolean) -> Unit, extra: @Composable () -> Unit = {}) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    ChoiceSurface(
        selected = false,
        modifier = Modifier.semantics(mergeDescendants = true) {
            role = Role.Switch
            toggleableState = ToggleableState(checked)
        },
        onClick = { onChange(!checked) },
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(title, style = type.display(20.sp), color = palette.ink)
                Text(detail, style = type.ui(15.sp, FontWeight.Medium), color = palette.muted)
            }
            Spacer(Modifier.width(12.dp))
            Switch(
                checked = checked,
                onCheckedChange = null,
                colors = SwitchDefaults.colors(
                    checkedThumbColor = palette.onTeal,
                    checkedTrackColor = palette.teal,
                    uncheckedThumbColor = palette.muted,
                    uncheckedTrackColor = palette.paper,
                    uncheckedBorderColor = palette.muted,
                ),
            )
        }
        extra()
    }
}

@Composable
fun ProgressPills(current: Int, count: Int, modifier: Modifier = Modifier) {
    val palette = LocalPalette.current
    Row(
        modifier.semantics(mergeDescendants = true) { contentDescription = "Step ${current + 1} of $count" },
        horizontalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        for (index in 0 until count) {
            Box(
                Modifier
                    .size(width = if (index == current) 22.dp else 8.dp, height = 8.dp)
                    .background(if (index <= current) palette.red else palette.muted.copy(alpha = 0.35f), CircleShape),
            )
        }
    }
}
