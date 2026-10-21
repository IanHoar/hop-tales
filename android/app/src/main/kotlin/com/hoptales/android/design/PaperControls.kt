package com.hoptales.android.design

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.toggleableState
import androidx.compose.ui.state.ToggleableState
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

val EaseInOut = CubicBezierEasing(0.42f, 0f, 0.58f, 1f)
val EaseOut = CubicBezierEasing(0f, 0f, 0.58f, 1f)

@Composable
fun Modifier.paperField(
    selected: Boolean = false,
    fill: Float = 0.6f,
    shape: RoundedCornerShape = RoundedCornerShape(18.dp),
    shadowOpacity: Float = 0.5f,
    shadowRadius: Dp = 3.dp,
    shadowY: Dp = 2.dp,
): Modifier {
    val paper = LocalPaper.current
    val colour = if (selected) paper.red.copy(alpha = 0.1f) else paper.rim.copy(alpha = fill)
    val shadow = Shadow(shadowRadius, paper.shadow.copy(alpha = paper.shadow.alpha * shadowOpacity), offset = DpOffset(0.dp, shadowY))
    val rim = if (selected) paper.red else paper.rim
    return paperShading(shape, colour, rim, 3.dp, shadow)
}

@Composable
fun PaperChoice(title: String, selected: Boolean, modifier: Modifier = Modifier, detail: String? = null, onClick: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    ChoiceSurface(selected, modifier, onClick) {
        Text(title, style = type.display(19.sp), color = paper.ink)
        if (detail != null) Text(detail, style = type.ui(14.sp), color = paper.muted)
    }
}

@Composable
fun ChoiceSurface(
    selected: Boolean,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)?,
    label: String? = null,
    role: Role = Role.Button,
    content: @Composable ColumnScope.() -> Unit,
) {
    val action = if (onClick == null) {
        Modifier
    } else {
        Modifier.pressable(onClick, role).semantics {
            this.selected = selected
            if (label != null) contentDescription = label
        }
    }
    Column(
        modifier
            .fillMaxWidth()
            .then(action)
            .paperField(selected)
            .padding(horizontal = 16.dp, vertical = 14.dp),
    ) {
        Column(
            if (label != null) Modifier.clearAndSetSemantics {} else Modifier,
            verticalArrangement = Arrangement.spacedBy(2.dp),
            content = content,
        )
    }
}

@Composable
fun PaperSwitch(checked: Boolean) {
    val paper = LocalPaper.current
    Switch(
        checked = checked,
        onCheckedChange = null,
        colors = SwitchDefaults.colors(
            checkedThumbColor = paper.onRed,
            checkedTrackColor = paper.sageDeep,
            checkedBorderColor = Color.Transparent,
            uncheckedThumbColor = paper.onRed,
            uncheckedTrackColor = paper.muted.copy(alpha = 0.35f),
            uncheckedBorderColor = Color.Transparent,
        ),
    )
}

@Composable
fun PaperToggle(title: String, detail: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    PaperToggleField(title, detail, checked, onChange) {}
}

@Composable
fun PaperToggleField(
    title: String,
    detail: String,
    checked: Boolean,
    onChange: (Boolean) -> Unit,
    below: @Composable ColumnScope.() -> Unit,
) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    Column(
        Modifier
            .fillMaxWidth()
            .paperField()
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Row(
            Modifier
                .semantics(mergeDescendants = true) { toggleableState = ToggleableState(checked) }
                .pressable({ onChange(!checked) }, Role.Switch, press = Press.NONE),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(title, style = type.display(20.sp), color = paper.ink)
                Text(detail, style = type.ui(15.sp), color = paper.muted)
            }
            Spacer(Modifier.width(12.dp))
            PaperSwitch(checked)
        }
        below()
    }
}

@Composable
fun ProgressPills(current: Int, count: Int, modifier: Modifier = Modifier) {
    Row(
        modifier.semantics(mergeDescendants = true) { contentDescription = "Step ${current + 1} of $count" },
        horizontalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        for (index in 0 until count) Pill(isCurrent = index == current, isDone = index <= current)
    }
}

@Composable
private fun Pill(isCurrent: Boolean, isDone: Boolean) {
    val paper = LocalPaper.current
    val width by animateDpAsState(if (isCurrent) 22.dp else 8.dp, tween(PILL_MILLIS, easing = EaseInOut), label = "pill")
    val colour by animateColorAsState(
        if (isDone) paper.red else paper.muted.copy(alpha = 0.35f),
        tween(PILL_MILLIS, easing = EaseInOut),
        label = "pill colour",
    )
    Box(Modifier.size(width = width, height = 8.dp).background(colour, CircleShape))
}

private const val PILL_MILLIS = 300
