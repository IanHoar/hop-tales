package com.hoptales.android.home

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.Deckle
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PadlockSticker
import com.hoptales.android.design.PaperButton
import com.hoptales.android.design.PaperQuietButton
import com.hoptales.android.settings.ParentGate
import com.hoptales.android.settings.ParentGateState
import com.hoptales.android.world.MeadowPostcard
import com.hoptales.content.StoryStanding

enum class LockedStep { CARD, GATE, PLUS_COMING }

val StoryStanding.lockedLine: String?
    get() {
        val total = story.sentences.size
        return when (val standing = standing) {
            StoryStanding.Standing.Unread -> null
            is StoryStanding.Standing.InProgress -> "You read ${total - standing.remaining} of $total"
            StoryStanding.Standing.Finished -> "You read all $total"
        }
    }

@Composable
fun LockedStoryScreen(
    standing: StoryStanding,
    onDone: () -> Unit,
    step: LockedStep = LockedStep.CARD,
    gate: ParentGateState = remember { ParentGateState.drawing() },
) {
    var shown by rememberSaveable { mutableStateOf(step) }
    if (shown == LockedStep.GATE) {
        ParentGate(onPassed = { shown = LockedStep.PLUS_COMING }, onClose = { shown = LockedStep.CARD }, initial = gate)
        return
    }
    val paper = LocalPaper.current
    val shape = remember { Deckle(seed = 23, jitter = 3.dp, step = 14.dp) }
    Column(Modifier.fillMaxSize().background(paper.page)) {
        SheetHeader("Hop Tales Plus", onDone)
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(start = 20.dp, end = 20.dp, top = 8.dp, bottom = 30.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(
                Modifier
                    .widthIn(max = 460.dp)
                    .fillMaxWidth()
                    .dropShadow(shape, Shadow(8.dp, paper.shadow, offset = DpOffset(0.dp, 5.dp)))
                    .background(paper.paper, shape)
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                if (shown == LockedStep.PLUS_COMING) PlusComing(onDone) else Card(standing) { shown = LockedStep.GATE }
            }
        }
    }
}

@Composable
private fun Card(standing: StoryStanding, onAsk: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val line = standing.lockedLine
    val art = RoundedCornerShape(20.dp)
    Box(Modifier.fillMaxWidth().padding(bottom = 10.dp)) {
        MeadowPostcard(standing.story.mood, Modifier.fillMaxWidth().height(190.dp).clip(art).border(4.dp, paper.rim, art))
        PadlockSticker(64.dp, Modifier.align(Alignment.BottomEnd).offset(12.dp, 16.dp))
    }
    Column(
        Modifier.clearAndSetSemantics {
            contentDescription = listOfNotNull("${standing.story.title}. Locked.", line?.let { "$it." }).joinToString(" ")
            heading()
        },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Text(standing.story.title, style = type.display(28.sp), color = paper.ink, textAlign = TextAlign.Center)
        if (line != null) Text(line, style = type.ui(16.sp, FontWeight.Medium), color = paper.muted)
    }
    Text("This story is part of Hop Tales Plus.", style = type.ui(18.sp), color = paper.ink, textAlign = TextAlign.Center)
    PaperButton("Ask a grown-up", onClick = onAsk)
}

@Composable
private fun PlusComing(onDone: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    Text(
        "Hop Tales Plus is on its way",
        style = type.display(26.sp),
        color = paper.ink,
        textAlign = TextAlign.Center,
        modifier = Modifier.semantics { heading() },
    )
    Text(
        "Subscriptions aren't open yet. Every Level 1 story stays free to read.",
        style = type.ui(17.sp, FontWeight.Medium),
        color = paper.muted,
        textAlign = TextAlign.Center,
    )
    PaperQuietButton("Back to stories", onClick = onDone)
}
