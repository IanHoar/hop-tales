package com.hoptales.android.reading

import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.FitText
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PaperChip
import com.hoptales.android.design.SpeakerGlyph

@Composable
fun HintChip(modifier: Modifier = Modifier, scale: Float = 1f, at: DpOffset = DpOffset.Zero, onClick: () -> Unit) {
    val paper = LocalPaper.current
    PaperChip(
        modifier
            .offset(at.x, at.y)
            .padding(vertical = 3.dp * scale)
            .semantics { contentDescription = "Hear the word" },
        height = 38.dp * scale,
        rim = 3.dp * scale,
        onClick = onClick,
    ) {
        SpeakerGlyph(paper.ink, size = 18.dp * scale)
        FitText(HINT_TITLE, LocalTypography.current.ui(16.sp * scale), paper.ink, minimumScale = 0.75f)
    }
}

private const val HINT_TITLE = "Hint?"
