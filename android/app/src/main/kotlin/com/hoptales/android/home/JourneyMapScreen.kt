package com.hoptales.android.home

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.pressable
import com.hoptales.android.world.FriendSticker
import com.hoptales.android.world.Rosette
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.JourneyStop
import com.hoptales.content.Story
import com.hoptales.content.StoryLibrary
import com.hoptales.content.stop
import kotlin.math.roundToInt

private val SPACING = 150.dp
private val INSET = 110.dp
private val MAP_HEIGHT = SPACING * (Friend.entries.size - 1) + INSET * 2

@Composable
fun JourneyMapScreen(library: StoryLibrary, journey: Journey, onFriend: (Friend) -> Unit, onBigStory: (Story) -> Unit, onDone: () -> Unit) {
    val paper = LocalPaper.current
    Column(Modifier.fillMaxSize().background(paper.page)) {
        PlainSheetHeader("Your journey", 26.sp, onDone, vertical = 10.dp)
        BoxWithConstraints(Modifier.fillMaxWidth().weight(1f).verticalScroll(rememberScrollState(Int.MAX_VALUE))) {
            val width = maxWidth
            val points = Friend.entries.indices.map { index ->
                Pair(width * if (index % 2 == 0) 0.32f else 0.68f, MAP_HEIGHT - INSET - SPACING * index)
            }
            Box(Modifier.fillMaxWidth().height(MAP_HEIGHT).windowInsetsPadding(WindowInsets.navigationBars)) {
                Trail(points, journey, library)
                for (friend in Friend.entries) {
                    val (x, y) = points[friend.level - 1]
                    Centred(x, y) {
                        StopView(friend, journey.stop(friend, library)) {
                            val stop = journey.stop(friend, library)
                            val bigStory = library.bigStory(friend.level)
                            if (stop == JourneyStop.Next(bigStoryWaiting = true) && bigStory != null) {
                                onBigStory(bigStory)
                            } else if (stop.isTappable) {
                                onFriend(friend)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun Centred(x: Dp, y: Dp, content: @Composable () -> Unit) {
    Layout(content, Modifier.wrapContentSize()) { measurables, constraints ->
        val placeable = measurables.first().measure(constraints.copy(minWidth = 0, minHeight = 0))
        layout(0, 0) {
            placeable.place(IntOffset((x.toPx() - placeable.width / 2f).roundToInt(), (y.toPx() - 45.dp.toPx()).roundToInt()))
        }
    }
}

@Composable
private fun Trail(points: List<Pair<Dp, Dp>>, journey: Journey, library: StoryLibrary) {
    val paper = LocalPaper.current
    Canvas(Modifier.fillMaxSize()) {
        val offsets = points.map { (x, y) -> Offset(x.toPx(), y.toPx()) }
        val path = Path().apply {
            moveTo(offsets.first().x, offsets.first().y)
            for ((from, to) in offsets.zipWithNext()) {
                val middle = (from.y + to.y) / 2
                cubicTo(from.x, middle, to.x, middle, to.x, to.y)
            }
        }
        drawPath(path, paper.shade, style = Stroke(34.dp.toPx(), cap = StrokeCap.Round))
        drawPath(
            path,
            paper.muted.copy(alpha = 0.35f),
            style = Stroke(
                3.dp.toPx(),
                cap = StrokeCap.Round,
                pathEffect = PathEffect.dashPathEffect(floatArrayOf(2.dp.toPx(), 12.dp.toPx())),
            ),
        )
        val level = journey.level
        if (level < offsets.size) {
            val dot = point(offsets[level - 1], offsets[level], 0.2 + 0.6 * journey.fill(library))
            drawCircle(paper.wash, 11.dp.toPx(), dot)
            drawCircle(paper.washRing, 9.5.dp.toPx(), dot, style = Stroke(3.dp.toPx()))
        }
    }
}

private fun point(from: Offset, to: Offset, progress: Double): Offset {
    val middle = (from.y + to.y) / 2
    val one = Offset(from.x, middle)
    val two = Offset(to.x, middle)
    val t = progress.coerceIn(0.0, 1.0).toFloat()
    val u = 1 - t
    return from * (u * u * u) + one * (3 * u * u * t) + two * (3 * u * t * t) + to * (t * t * t)
}

@Composable
private fun StopView(friend: Friend, stop: JourneyStop, onClick: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val reading = stop == JourneyStop.Reading
    val tag = when (stop) {
        JourneyStop.Reading -> "reading"
        JourneyStop.Next(bigStoryWaiting = true) -> "big story waiting"
        is JourneyStop.Next -> "next"
        else -> null
    }
    Column(
        Modifier
            .pressable(onClick, enabled = stop.isTappable)
            .clearAndSetSemantics {
                contentDescription = label(friend, stop)
                if (stop.isTappable) role = Role.Button
            },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Box {
            Box(
                Modifier
                    .size(90.dp)
                    .dropShadow(CircleShape, Shadow(4.dp, paper.shadow, offset = DpOffset(0.dp, 3.dp)))
                    .background(paper.paper, CircleShape)
                    .border(4.dp, if (reading) paper.red else paper.rim, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                FriendSticker(
                    friend,
                    70.dp,
                    Modifier.alpha(if (stop == JourneyStop.Later) 0.4f else 1f),
                    isSilhouette = stop == JourneyStop.Later,
                    silhouette = paper.silhouette,
                    saturation = if (stop is JourneyStop.Next) 0f else 1f,
                )
            }
            if (stop == JourneyStop.Met || reading) {
                Rosette(friend.level, Modifier.align(Alignment.TopEnd).offset(x = 10.dp, y = (-8).dp))
            }
        }
        Text(if (stop == JourneyStop.Later) "?" else friend.friendName, style = type.display(17.sp), color = paper.ink)
        if (tag != null) {
            Text(
                tag,
                style = type.ui(12.sp),
                color = if (reading) paper.onRed else paper.ink,
                modifier = Modifier
                    .background(if (reading) paper.red else paper.wash, CircleShape)
                    .padding(horizontal = 8.dp, vertical = 3.dp),
            )
        }
    }
}

private fun label(friend: Friend, stop: JourneyStop): String = when (stop) {
    JourneyStop.Reading -> "${friend.friendName}, reading level ${friend.level}. Reading now."

    JourneyStop.Met -> "${friend.friendName}, reading level ${friend.level}. Tap to read with ${friend.friendName}."

    is JourneyStop.Next -> if (stop.bigStoryWaiting) {
        "${friend.friendName}'s big story is waiting."
    } else {
        "${friend.friendName} is next. Fill the path to meet them."
    }

    JourneyStop.Later -> "A friend at reading level ${friend.level}."
}
