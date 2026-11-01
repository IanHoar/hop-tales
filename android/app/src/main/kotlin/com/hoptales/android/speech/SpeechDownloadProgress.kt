package com.hoptales.android.speech

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography

@Composable
fun SpeechDownloadProgress(percent: Int?, modifier: Modifier = Modifier, alignment: Alignment.Horizontal = Alignment.Start) {
    val paper = LocalPaper.current
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(6.dp), horizontalAlignment = alignment) {
        val bar = Modifier.fillMaxWidth().height(8.dp)
        if (percent == null) {
            LinearProgressIndicator(bar, color = paper.sage, trackColor = paper.rim, strokeCap = StrokeCap.Round)
        } else {
            LinearProgressIndicator(
                progress = { percent / 100f },
                modifier = bar.semantics { progressBarRangeInfo = ProgressBarRangeInfo(percent / 100f, 0f..1f) },
                color = paper.sage,
                trackColor = paper.rim,
                strokeCap = StrokeCap.Round,
                gapSize = 0.dp,
                drawStopIndicator = {},
            )
        }
        Text(
            if (percent == null) "Downloading English speech…" else "Downloading English speech… $percent%",
            style = LocalTypography.current.ui(14.sp, FontWeight.Medium),
            color = paper.muted,
        )
    }
}
