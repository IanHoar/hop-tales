package com.hoptales.android.reading

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import com.hoptales.android.design.Deckle
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.world.FriendSticker
import com.hoptales.android.world.Rosette
import com.hoptales.content.Friend
import com.hoptales.content.Plus
import kotlin.math.PI

object LevelOneFinished {
    val next: Friend = Friend.at(Plus.FREE_LEVEL + 1)

    const val RAYS = 14
}

@Composable
fun LevelOneCard(geometry: PathGeometry, askAGrownUp: () -> Unit, keepReading: () -> Unit, modifier: Modifier = Modifier) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val card = remember(geometry) { Deckle(seed = 41, jitter = geometry.dp(2.6f), step = geometry.dp(10f)) }
    Column(
        modifier
            .padding(horizontal = 24.dp)
            .widthIn(max = geometry.dp(340f))
            .fillMaxWidth()
            .rotate(-1f)
            .dropShadow(card, Shadow(geometry.dp(10f), paper.shadow, offset = DpOffset(0.dp, geometry.dp(6f))))
            .background(paper.paper, card)
            .padding(geometry.dp(20f)),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(geometry.dp(12f)),
    ) {
        RosetteBurst(geometry)
        Text(
            "You finished Level ${Plus.FREE_LEVEL}!",
            style = type.display(geometry.sp(24f)),
            color = paper.ink,
            textAlign = TextAlign.Center,
            modifier = Modifier.semantics { heading() },
        )
        NextFriend(geometry)
        FlowRow(
            Modifier.padding(top = geometry.dp(4f)),
            horizontalArrangement = Arrangement.spacedBy(geometry.dp(10f), Alignment.CenterHorizontally),
            verticalArrangement = Arrangement.spacedBy(geometry.dp(10f)),
        ) {
            CardButton("Keep reading", filled = false, geometry, onClick = keepReading)
            CardButton("Ask a grown-up", filled = true, geometry, onClick = askAGrownUp)
        }
    }
}

@Composable
private fun RosetteBurst(geometry: PathGeometry) {
    val wash = LocalPaper.current.wash
    Box(Modifier.height(geometry.dp(84f)).clearAndSetSemantics {}, contentAlignment = Alignment.Center) {
        Canvas(Modifier.size(geometry.dp(120f))) {
            val radius = size.minDimension / 2
            val half = PI / LevelOneFinished.RAYS / 2
            val rays = Path()
            for (ray in 0 until LevelOneFinished.RAYS) {
                val angle = ray * 2 * PI / LevelOneFinished.RAYS
                rays.moveTo(center.x, center.y)
                rays.arcTo(
                    Rect(center, radius),
                    Math.toDegrees(angle - half).toFloat(),
                    Math.toDegrees(2 * half).toFloat(),
                    forceMoveTo = false,
                )
                rays.close()
            }
            drawPath(rays, Brush.radialGradient(listOf(wash.copy(alpha = 0.75f), wash.copy(alpha = 0f)), center, radius))
        }
        Rosette(Plus.FREE_LEVEL, Modifier.rotate(6f), height = geometry.dp(72f))
    }
}

@Composable
private fun NextFriend(geometry: PathGeometry) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val next = LevelOneFinished.next
    val words = next.examples.joinToString(", ")
    val panel = remember(geometry) { Deckle(seed = 42, jitter = geometry.dp(1.6f), step = geometry.dp(9f)) }
    Row(
        Modifier
            .fillMaxWidth()
            .background(paper.shade, panel)
            .padding(geometry.dp(12f))
            .clearAndSetSemantics { contentDescription = "${next.friendName} is waiting. Words like $words." },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(geometry.dp(12f)),
    ) {
        Box(Modifier.size(geometry.dp(72f)), contentAlignment = Alignment.Center) {
            FriendSticker(next, geometry.dp(72f))
        }
        Column(verticalArrangement = Arrangement.spacedBy(geometry.dp(3f))) {
            Text("${next.friendName} is waiting", style = type.display(geometry.sp(18f)), color = paper.ink)
            Text(
                buildAnnotatedString {
                    append("Words like ")
                    withStyle(type.word(geometry.sp(17f)).toSpanStyle().copy(color = paper.ink)) { append(words) }
                },
                style = type.ui(geometry.sp(14f)),
                color = paper.muted,
            )
        }
    }
}
