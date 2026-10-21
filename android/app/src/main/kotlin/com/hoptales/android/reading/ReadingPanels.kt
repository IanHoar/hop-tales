package com.hoptales.android.reading

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.layout
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.hideFromAccessibility
import androidx.compose.ui.semantics.isTraversalGroup
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.traversalIndex
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.Deckle
import com.hoptales.android.design.Glyphs
import com.hoptales.android.design.InkButton
import com.hoptales.android.design.InkKind
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PaperButton
import com.hoptales.android.design.PaperLabel
import com.hoptales.android.design.PaperQuietButton
import com.hoptales.android.design.PaperStar
import com.hoptales.android.design.Press
import com.hoptales.android.design.bevel
import com.hoptales.android.design.headingGroup
import com.hoptales.android.design.paperChip
import com.hoptales.android.design.pressable
import kotlin.math.roundToInt

@Composable
fun DebugControls(word: String, readWord: () -> Unit, restOfSentence: () -> Unit) {
    val palette = LocalPalette.current
    Row(
        Modifier
            .background(palette.ink.copy(alpha = 0.75f), RoundedCornerShape(14.dp))
            .padding(horizontal = 10.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        DebugButton("Read “$word”", readWord)
        DebugButton("Rest of sentence", restOfSentence)
    }
}

@Composable
private fun DebugButton(title: String, onClick: () -> Unit) {
    val palette = LocalPalette.current
    Box(
        Modifier
            .semantics { hideFromAccessibility() }
            .pressable(onClick)
            .height(34.dp)
            .background(palette.goldShade.copy(alpha = 0.9f), CircleShape)
            .padding(horizontal = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(title, style = LocalTypography.current.ui(13.sp), color = palette.parchment)
    }
}

@Composable
fun AskToListen(onAllow: () -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        PanelBackdrop(palette.duskRoot.copy(alpha = 0.55f))
        val shape = RoundedCornerShape(32.dp)
        Column(
            Modifier
                .padding(24.dp)
                .widthIn(max = 330.dp)
                .dropShadow(shape, Shadow(17.dp, palette.duskShadow, offset = DpOffset(0.dp, 22.dp)))
                .bevel(palette.parchment, palette.parchmentLip, shape, palette.outline, palette.highlight, 4.dp, 6.dp, 9.dp)
                .padding(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Icon(Glyphs.mic, null, tint = palette.muted, modifier = Modifier.size(44.dp))
            Text("Read it out loud", style = type.display(26.sp), color = palette.ink, textAlign = TextAlign.Center)
            Text(
                "Hop Tales listens while you read so the hare can hop along. Listening happens on this " +
                    "device — nothing is recorded or sent anywhere.",
                style = type.ui(16.sp, FontWeight.Medium),
                color = palette.muted,
                textAlign = TextAlign.Center,
            )
            InkButton("Let's read", InkKind.PRIMARY, Modifier.fillMaxWidth().padding(top = 6.dp), onClick = onAllow)
        }
    }
}

@Composable
fun ListeningUnavailable(listening: Listening, onBack: () -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    val denied = listening == Listening.Denied
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        PanelBackdrop(palette.duskRoot.copy(alpha = 0.55f))
        val shape = RoundedCornerShape(32.dp)
        Column(
            Modifier
                .padding(24.dp)
                .widthIn(max = 330.dp)
                .dropShadow(shape, Shadow(17.dp, palette.duskShadow, offset = DpOffset(0.dp, 22.dp)))
                .bevel(palette.parchment, palette.parchmentLip, shape, palette.outline, palette.highlight, 4.dp, 6.dp, 9.dp)
                .padding(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Icon(if (denied) Glyphs.micOff else Glyphs.phoneOff, null, tint = palette.muted, modifier = Modifier.size(44.dp))
            Text(
                if (denied) "The microphone is off" else "This device can’t listen yet",
                style = type.display(26.sp),
                color = palette.ink,
                textAlign = TextAlign.Center,
            )
            Text(
                if (denied) {
                    "Hop Tales listens so it can hear you read. A grown-up can turn the microphone back on in Settings."
                } else {
                    "Hop Tales listens on the device itself, and this one doesn’t support that. You can still read along together."
                },
                style = type.ui(16.sp),
                color = palette.muted,
                textAlign = TextAlign.Center,
            )
            InkButton("Back to stories", InkKind.PRIMARY, Modifier.fillMaxWidth().padding(top = 6.dp), onClick = onBack)
        }
    }
}

@Composable
fun StoryFinished(title: String, stars: Int, geometry: PathGeometry, readAgain: () -> Unit, done: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    Box(Modifier.fillMaxSize()) {
        Column(
            Modifier
                .centredAt(geometry.y(STICKER_Y))
                .semantics {
                    contentDescription = "You finished $title."
                    isTraversalGroup = true
                },
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(geometry.dp(14f)),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(geometry.dp(12f)), verticalAlignment = Alignment.CenterVertically) {
                Row(
                    Modifier
                        .pressable(readAgain, press = Press.PLAIN)
                        .height(geometry.dp(48f))
                        .paperChip(CircleShape, rim = geometry.dp(4f))
                        .padding(horizontal = geometry.dp(18f)),
                    horizontalArrangement = Arrangement.spacedBy(geometry.dp(8f)),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Glyphs.again, null, tint = paper.ink, modifier = Modifier.size(geometry.dp(15f)))
                    Text("Read it again", style = type.display(geometry.sp(18f)), color = paper.ink)
                }
                Row(
                    Modifier
                        .rotate(4f)
                        .clearAndSetSemantics { contentDescription = "$stars stars" }
                        .height(geometry.dp(44f))
                        .paperChip(CircleShape, rim = geometry.dp(4f))
                        .padding(horizontal = geometry.dp(14f)),
                    horizontalArrangement = Arrangement.spacedBy(geometry.dp(6f)),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    PaperStar(geometry.dp(20f))
                    Text(
                        "+$stars",
                        style = type.display(geometry.sp(18f)).copy(fontFeatureSettings = "tnum"),
                        color = paper.ink,
                    )
                }
            }
            Box(
                Modifier
                    .size(geometry.dp(236f), geometry.dp(56f))
                    .semantics { traversalIndex = -1f }
                    .pressable(done, press = Press.PAPER)
                    .dropShadow(CircleShape, Shadow(geometry.dp(5f), paper.shadow, offset = DpOffset(0.dp, geometry.dp(4f))))
                    .background(paper.rim, CircleShape)
                    .padding(geometry.dp(4f))
                    .background(paper.red, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Text("Done", style = type.display(geometry.sp(21f)), color = paper.onRed)
            }
        }
    }
}

@Composable
fun StopReading(friend: String, keepReading: () -> Unit, stop: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Box(
            Modifier
                .fillMaxSize()
                .background(paper.night.copy(alpha = 0.45f))
                .clearAndSetSemantics {}
                .clickable(remember { MutableInteractionSource() }, indication = null, onClick = keepReading),
        )
        val card = remember { Deckle(seed = 31, jitter = 3.dp, step = 12.dp) }
        Column(
            Modifier
                .padding(horizontal = 24.dp)
                .widthIn(max = 340.dp)
                .rotate(-1f)
                .dropShadow(card, Shadow(12.dp, paper.shadow, offset = DpOffset(0.dp, 8.dp)))
                .background(paper.paper, card)
                .pointerInput(Unit) { detectTapGestures {} }
                .padding(horizontal = 24.dp, vertical = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            PaperLabel(Modifier.rotate(-2f).headingGroup(), seed = 23) {
                Text(
                    "Stop reading?",
                    style = type.display(26.sp),
                    color = paper.ink,
                    modifier = Modifier.padding(horizontal = 18.dp, vertical = 8.dp),
                )
            }
            Text(
                "$friend will wait here. You can come back to this story any time.",
                style = type.ui(16.sp, FontWeight.Medium),
                color = paper.ink.copy(alpha = 0.85f),
                textAlign = TextAlign.Center,
            )
            PaperButton("Keep reading", Modifier.padding(top = 6.dp), icon = Glyphs.book, onClick = keepReading)
            PaperQuietButton("Back to stories", Modifier.fillMaxWidth(), icon = Glyphs.house, onClick = stop)
        }
    }
}

private fun Modifier.centredAt(y: Float) = layout { measurable, constraints ->
    val placeable = measurable.measure(constraints.copy(minWidth = 0, minHeight = 0))
    layout(constraints.maxWidth, constraints.maxHeight) {
        placeable.place((constraints.maxWidth - placeable.width) / 2, (y - placeable.height / 2f).roundToInt())
    }
}

private const val STICKER_Y = 728f

@Composable
private fun PanelBackdrop(color: Color) {
    Box(
        Modifier
            .fillMaxSize()
            .background(color)
            .clearAndSetSemantics {}
            .clickable(remember { MutableInteractionSource() }, indication = null, onClick = {}),
    )
}
