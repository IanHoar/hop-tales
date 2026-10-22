package com.hoptales.android.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PaperLabel
import com.hoptales.android.design.headingGroup
import com.hoptales.android.design.paperChip
import com.hoptales.android.design.pressable

@Composable
fun SheetHeader(title: String, done: () -> Unit, accessory: @Composable RowScope.() -> Unit = {}) {
    HeaderRow(done, PaddingValues(horizontal = 20.dp, vertical = 12.dp), accessory) { PaperTitle(title) }
}

@Composable
fun PlainSheetHeader(title: String, size: TextUnit, done: () -> Unit, vertical: Dp = 12.dp, modifier: Modifier = Modifier) {
    HeaderRow(done, PaddingValues(horizontal = 20.dp, vertical = vertical), modifier = modifier) {
        Text(
            title,
            style = LocalTypography.current.display(size),
            color = LocalPaper.current.ink,
            modifier = Modifier.semantics { heading() },
        )
    }
}

@Composable
private fun HeaderRow(
    done: () -> Unit,
    padding: PaddingValues,
    accessory: @Composable RowScope.() -> Unit = {},
    modifier: Modifier = Modifier,
    title: @Composable () -> Unit,
) {
    Row(
        modifier.fillMaxWidth().padding(padding),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        title()
        Spacer(Modifier.weight(1f))
        accessory()
        DoneChip(done)
    }
}

@Composable
fun PaperTitle(title: String, modifier: Modifier = Modifier) {
    PaperLabel(modifier.rotate(-2f).headingGroup(), seed = 11) {
        Text(
            title,
            style = LocalTypography.current.display(22.sp),
            color = LocalPaper.current.ink,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
        )
    }
}

@Composable
fun DoneChip(onClick: () -> Unit, label: String = "Done") {
    Box(
        Modifier
            .pressable(onClick)
            .height(40.dp)
            .paperChip(CircleShape, rim = 3.dp)
            .padding(horizontal = 16.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, style = LocalTypography.current.display(17.sp), color = LocalPaper.current.ink)
    }
}

@Composable
fun MapButton(onClick: () -> Unit) {
    Box(
        Modifier
            .semantics { contentDescription = "Your journey" }
            .pressable(onClick)
            .size(40.dp)
            .paperChip(CircleShape, rim = 3.dp),
        contentAlignment = Alignment.Center,
    ) {
        MapGlyph(LocalPaper.current.ink)
    }
}
