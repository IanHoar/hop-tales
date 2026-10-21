package com.hoptales.android.home

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.EaseOut
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.Deckle
import com.hoptales.android.design.GearGlyph
import com.hoptales.android.design.Glyphs
import com.hoptales.android.design.LocalFold
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PaperLabel
import com.hoptales.android.design.PaperStar
import com.hoptales.android.design.headingGroup
import com.hoptales.android.design.paperChip
import com.hoptales.android.design.pressable
import com.hoptales.android.design.rememberReducedMotion
import com.hoptales.android.reading.swiftSpring
import com.hoptales.android.world.FriendSticker
import com.hoptales.android.world.IdleFriend
import com.hoptales.android.world.MeadowBackdrop
import com.hoptales.android.world.MeadowFraming
import com.hoptales.android.world.MeadowLayout
import com.hoptales.android.world.MeadowPostcard
import com.hoptales.android.world.Rosette
import com.hoptales.android.world.Sticker
import com.hoptales.android.world.WearSticker
import com.hoptales.content.Journey
import com.hoptales.content.Progress
import com.hoptales.content.Story
import com.hoptales.content.StoryLibrary
import com.hoptales.content.StoryStanding
import com.hoptales.content.WardrobeLibrary
import com.hoptales.content.greeting
import com.hoptales.content.keepGoing
import com.hoptales.content.newestItem
import com.hoptales.content.outfit
import com.hoptales.content.shelf
import com.hoptales.content.startingStoryID
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.time.LocalTime

@Composable
fun HomeScreen(
    library: StoryLibrary,
    progress: Progress,
    onStory: (Story) -> Unit,
    childName: String? = null,
    hour: Int = LocalTime.now().hour,
    onGrownUps: () -> Unit = {},
    onJourney: () -> Unit = {},
    onFriends: () -> Unit = {},
    onWardrobe: () -> Unit = {},
    onBook: () -> Unit = {},
    entrance: Boolean = false,
    covered: Boolean = false,
) {
    val paper = LocalPaper.current
    val arrival = rememberArrival(entrance)
    val wardrobe = (LocalContext.current.applicationContext as HopTalesApplication).wardrobe
    val insets = WindowInsets.safeDrawing.asPaddingValues()
    val friend = progress.journey.activeFriend
    val standings = progress.shelf(library)
    val keepGoing = standings.keepGoing(friend.startingStoryID(library))
    val outfit = progress.outfit(friend, wardrobe)
    BoxWithConstraints(Modifier.fillMaxSize().background(paper.page)) {
        val fullHeight = maxHeight
        val screen = fullHeight.value
        val area = Size(maxWidth.value, maxHeight.value)
        val fold = LocalFold.current?.takeUnless { it.runsAcross }
        val room = fold?.room(area)
        val standsAside = fold != null || maxWidth > HomeLayout.WIDE_LAYOUT.dp
        val column = minOf(HomeLayout.COLUMN_WIDTH, (room?.width ?: Float.POSITIVE_INFINITY) - 32f).dp
        val landscape = maxWidth > maxHeight
        val horizon = if (standsAside && landscape) HomeLayout.LOW_HORIZON else HomeLayout.SHEET_TOP
        val landScale = HomeLayout.LAND_SCALE * (maxWidth.value / 390f).coerceIn(1f, 1.3f)
        val pathCentre = screen * horizon - HomeLayout.FEET_ABOVE_SHEET - 20f
        val framing = remember(landScale, pathCentre) {
            MeadowFraming { width, _, density -> MeadowLayout(width, landScale * density, pathCentre * density) }
        }
        MeadowBackdrop(progress = 900f, world = friend, framing = framing, live = !covered)
        if (standsAside) {
            val stage = HomeLayout.FRIEND_HEIGHT.dp * 2
            Box(
                Modifier
                    .offset(
                        x = (fold?.stage(area)?.center?.x?.dp ?: ((maxWidth - HomeLayout.COLUMN_WIDTH.dp) / 4)) - stage / 2,
                        y = (screen * horizon - HomeLayout.FEET_ABOVE_SHEET - HomeLayout.FRIEND_HEIGHT).dp,
                    ).size(stage, HomeLayout.FRIEND_HEIGHT.dp),
                contentAlignment = Alignment.BottomCenter,
            ) {
                IdleFriend(
                    friend,
                    outfit.firstOrNull()?.id,
                    HomeLayout.FRIEND_HEIGHT.dp,
                    Modifier.popsIn(arrival),
                    shadow = paper.shadow,
                )
            }
        }
        val scroll = rememberScrollState()
        var sheetTop by remember { mutableIntStateOf(0) }
        val top = insets.calculateTopPadding()
        val bottom = insets.calculateBottomPadding()
        val sheetTopDp = with(LocalDensity.current) { sheetTop.toDp() }
        Box(
            Modifier.fillMaxSize().verticalScroll(scroll).padding(start = (room?.left ?: 0f).dp),
            contentAlignment = Alignment.TopCenter,
        ) {
            Box(Modifier.widthIn(max = column).fillMaxWidth().heightIn(min = fullHeight)) {
                Column(
                    Modifier
                        .fillMaxWidth()
                        .graphicsLayer { translationY = scroll.value.toFloat() }
                        .onSizeChanged { sheetTop = it.height },
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    TopBar(
                        greeting(hour, childName),
                        onGrownUps,
                        Modifier.padding(top = top + maxOf(8.dp, 20.dp - top)).graphicsLayer {
                            val shown = arrival.bar.value
                            translationY = -HomeLayout.BAR_DROP.dp.toPx() * (1 - shown)
                            alpha = shown.coerceIn(0f, 1f)
                        },
                    )
                    Spacer(Modifier.height(maxOf(0.dp, (screen * HomeLayout.SHEET_TOP).dp - top - 330.dp)))
                    IdleFriend(
                        friend,
                        outfit.firstOrNull()?.id,
                        HomeLayout.FRIEND_HEIGHT.dp,
                        Modifier.alpha(if (standsAside) 0f else 1f).popsIn(arrival),
                        shadow = paper.shadow,
                    )
                    Spacer(Modifier.height(14.dp))
                    LevelChip(
                        library,
                        progress.journey,
                        onJourney,
                        Modifier.padding(horizontal = 28.dp).graphicsLayer { alpha = arrival.chip.value },
                    )
                    Spacer(Modifier.height(18.dp))
                }
                Sheet(
                    Modifier
                        .padding(top = sheetTopDp)
                        .heightIn(min = fullHeight - sheetTopDp)
                        .graphicsLayer { translationY = HomeLayout.SHEET_RISE.dp.toPx() * arrival.sheet.value },
                    bottomInset = bottom,
                ) {
                    if (keepGoing != null) KeepGoingCard(keepGoing) { onStory(keepGoing.story) }
                    StickerButtons(progress, wardrobe, onFriends, onWardrobe, onBook)
                    Text(
                        "More stories",
                        style = LocalTypography.current.display(20.sp),
                        color = paper.ink,
                        modifier = Modifier.padding(top = 6.dp).semantics { heading() },
                    )
                    for (standing in standings.filter { it.story.id != keepGoing?.story?.id }) {
                        StoryRow(standing) { onStory(standing.story) }
                    }
                }
            }
        }
    }
}

private object HomeLayout {
    const val SHEET_TOP = 0.51f
    const val LOW_HORIZON = 0.8f
    const val FEET_ABOVE_SHEET = 100f
    const val LAND_SCALE = 0.6f
    const val FRIEND_HEIGHT = 170f
    const val COLUMN_WIDTH = 560f
    const val WIDE_LAYOUT = 760f
    const val SHEET_RISE = 160f
    const val BAR_DROP = 40f
    const val FRIEND_FROM = 0.4f
}

private class Arrival(
    val sheet: Animatable<Float, *>,
    val friend: Animatable<Float, *>,
    val bar: Animatable<Float, *>,
    val chip: Animatable<Float, *>,
)

@Composable
private fun rememberArrival(entrance: Boolean): Arrival {
    val still = rememberReducedMotion()
    val plays = remember { entrance && !still }
    val arrival = remember {
        Arrival(
            Animatable(if (plays) 1f else 0f),
            Animatable(if (plays) 0f else 1f),
            Animatable(if (plays) 0f else 1f),
            Animatable(if (plays) 0f else 1f),
        )
    }
    LaunchedEffect(Unit) {
        if (!plays) return@LaunchedEffect
        launch { arrival.sheet.animateTo(0f, swiftSpring(0.7, 0.12)) }
        launch {
            delay(250)
            arrival.friend.animateTo(1f, swiftSpring(0.5, 0.45))
        }
        launch {
            delay(350)
            arrival.chip.animateTo(1f, tween(400, easing = EaseOut))
        }
        launch {
            delay(450)
            arrival.bar.animateTo(1f, swiftSpring(0.55, 0.35))
        }
    }
    return arrival
}

private fun Modifier.popsIn(arrival: Arrival) = graphicsLayer {
    val shown = arrival.friend.value
    val scale = HomeLayout.FRIEND_FROM + (1 - HomeLayout.FRIEND_FROM) * shown
    scaleX = scale
    scaleY = scale
    alpha = shown.coerceIn(0f, 1f)
    transformOrigin = TransformOrigin(0.5f, 1f)
}

@Composable
private fun TopBar(greeting: String, onGrownUps: () -> Unit, modifier: Modifier = Modifier) {
    val paper = LocalPaper.current
    Row(modifier.fillMaxWidth().padding(horizontal = 20.dp), verticalAlignment = Alignment.Top) {
        Box(Modifier.weight(1f)) {
            PaperLabel(Modifier.rotate(-3f).headingGroup(), seed = 7) {
                Text(
                    greeting,
                    style = LocalTypography.current.display(21.sp),
                    color = paper.ink,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.padding(horizontal = 18.dp, vertical = 9.dp),
                )
            }
        }
        Spacer(Modifier.width(8.dp))
        Box(
            Modifier
                .size(46.dp)
                .semantics { contentDescription = "Settings for grown-ups" }
                .pressable(onGrownUps)
                .paperChip(CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            GearGlyph(paper.ink)
        }
    }
}

@Composable
private fun Sheet(modifier: Modifier, bottomInset: Dp, content: @Composable () -> Unit) {
    val paper = LocalPaper.current
    val shape = remember { Deckle(seed = 21, jitter = 3.dp, step = 16.dp) }
    Column(
        modifier
            .fillMaxWidth()
            .dropShadow(shape, Shadow(10.dp, paper.shadow, offset = DpOffset(0.dp, (-4).dp)))
            .background(paper.paper, shape)
            .padding(start = 24.dp, end = 24.dp, top = 26.dp, bottom = maxOf(bottomInset, 16.dp) + 18.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) { content() }
}

@Composable
private fun LevelChip(library: StoryLibrary, journey: Journey, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val paper = LocalPaper.current
    val next = journey.nextFriend
    val title = if (next == null) {
        "Level ${journey.level} · ${journey.activeFriend.friendName}"
    } else {
        "Level ${journey.level} · ${journey.steps.toInt()} of ${journey.goal(library).toInt()} to ${next.friendName}"
    }
    Row(
        modifier
            .fillMaxWidth()
            .pressable(onClick)
            .clearAndSetSemantics {
                contentDescription = "$title. Opens your journey."
                role = Role.Button
            }
            .paperChip(RoundedCornerShape(18.dp), rim = 3.dp)
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Rosette(journey.level, Modifier.width(40.dp))
        Spacer(Modifier.size(12.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
            Text(
                title,
                style = LocalTypography.current.display(16.sp),
                color = paper.ink,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (next != null) {
                Box(Modifier.fillMaxWidth().height(8.dp).clip(CircleShape).background(paper.muted.copy(alpha = 0.22f))) {
                    Box(Modifier.fillMaxWidth(journey.fill(library).toFloat()).height(8.dp).background(paper.wash, CircleShape))
                }
            }
        }
        Spacer(Modifier.size(12.dp))
        MapGlyph(paper.ink)
    }
}

@Composable
fun MapGlyph(colour: Color, modifier: Modifier = Modifier) {
    Canvas(modifier.size(22.dp)) {
        val w = size.width
        val h = size.height
        val stroke = Stroke(width = 2.dp.toPx(), join = StrokeJoin.Round)
        val outline = Path().apply {
            moveTo(0f, h * 0.18f)
            lineTo(w / 3, 0f)
            lineTo(w * 2 / 3, h * 0.18f)
            lineTo(w, 0f)
            lineTo(w, h * 0.82f)
            lineTo(w * 2 / 3, h)
            lineTo(w / 3, h * 0.82f)
            lineTo(0f, h)
            close()
        }
        drawPath(outline, colour, style = stroke)
        drawLine(colour, Offset(w / 3, 0f), Offset(w / 3, h * 0.82f), stroke.width)
        drawLine(colour, Offset(w * 2 / 3, h * 0.18f), Offset(w * 2 / 3, h), stroke.width)
    }
}

@Composable
private fun StickerButtons(
    progress: Progress,
    wardrobe: WardrobeLibrary,
    onFriends: () -> Unit,
    onWardrobe: () -> Unit,
    onBook: () -> Unit,
) {
    val friend = progress.journey.activeFriend
    val newest = progress.newestItem(friend, wardrobe)
    Row(Modifier.padding(vertical = 6.dp)) {
        StickerButton("Friends", onFriends) { FriendSticker(friend, 52.dp) }
        if (newest != null) {
            StickerButton("Wardrobe", onWardrobe) { WearSticker(friend, newest, 52.dp, 44.dp) }
        }
        StickerButton("Book", onBook) { Sticker("collect-basket", Modifier.size(50.dp)) }
    }
}

@Composable
private fun RowScope.StickerButton(title: String, onClick: () -> Unit, art: @Composable () -> Unit) {
    val paper = LocalPaper.current
    Column(
        Modifier
            .weight(1f)
            .pressable(onClick)
            .clearAndSetSemantics {
                contentDescription = title
                role = Role.Button
            },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Box(
            Modifier
                .size(84.dp)
                .dropShadow(CircleShape, Shadow(4.dp, paper.shadow.copy(alpha = paper.shadow.alpha * 0.6f), offset = DpOffset(0.dp, 3.dp)))
                .background(paper.rim.copy(alpha = 0.7f), CircleShape)
                .border(3.dp, paper.rim, CircleShape),
            contentAlignment = Alignment.Center,
        ) { art() }
        Text(title, style = LocalTypography.current.display(16.sp), color = paper.ink)
    }
}

@Composable
private fun KeepGoingCard(standing: StoryStanding, onClick: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val heading = if (standing.isCurrent) "Keep reading" else "Start here"
    val total = standing.story.sentences.size
    val meta = (standing.standing as? StoryStanding.Standing.InProgress)?.let { "Sentence ${total - it.remaining + 1} of $total" }
        ?: "Your next story"
    val shape = RoundedCornerShape(20.dp)
    Row(
        Modifier
            .fillMaxWidth()
            .pressable(onClick)
            .clearAndSetSemantics {
                contentDescription = "$heading. ${standing.story.title}. $meta."
                role = Role.Button
            }
            .dropShadow(shape, Shadow(3.dp, paper.shadow.copy(alpha = paper.shadow.alpha * 0.55f), offset = DpOffset(0.dp, 2.dp)))
            .background(paper.rim, shape)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        MeadowPostcard(standing.story.mood, Modifier.size(62.dp).clip(RoundedCornerShape(12.dp)))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(heading.uppercase(), style = type.caps(12.sp).copy(letterSpacing = 0.06.em), color = paper.muted)
            Text(standing.story.title, style = type.display(19.sp), color = paper.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(meta, style = type.ui(13.sp, FontWeight.Medium), color = paper.muted)
        }
        Box(Modifier.size(46.dp).paperChip(CircleShape, fill = paper.red), contentAlignment = Alignment.Center) {
            Canvas(Modifier.size(16.dp)) {
                val play = Path().apply {
                    moveTo(size.width * 0.15f, 0f)
                    lineTo(size.width, size.height / 2)
                    lineTo(size.width * 0.15f, size.height)
                    close()
                }
                drawPath(play, paper.onRed)
            }
        }
    }
}

@Composable
private fun StoryRow(standing: StoryStanding, onClick: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val shape = RoundedCornerShape(16.dp)
    Row(
        Modifier
            .fillMaxWidth()
            .pressable(onClick)
            .clearAndSetSemantics {
                contentDescription = "${standing.story.title}. ${standing.subtitle}"
                role = Role.Button
            }
            .background(paper.rim.copy(alpha = 0.55f), shape)
            .padding(horizontal = 10.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        val thumbnail = RoundedCornerShape(11.dp)
        MeadowPostcard(standing.story.mood, Modifier.size(50.dp).clip(thumbnail).border(3.dp, paper.rim, thumbnail))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text(standing.story.title, style = type.display(17.sp), color = paper.ink)
            Text(standing.subtitle, style = type.ui(13.sp, FontWeight.Medium), color = paper.muted)
        }
        when (standing.standing) {
            StoryStanding.Standing.Finished -> Box(
                Modifier.size(24.dp).background(paper.sageDeep, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Glyphs.check, null, tint = paper.onRed, modifier = Modifier.size(16.dp))
            }

            is StoryStanding.Standing.InProgress -> PaperStar(22.dp)

            StoryStanding.Standing.Unread -> Text(
                "New",
                style = type.ui(13.sp),
                color = paper.redInk,
                modifier = Modifier.padding(end = 4.dp),
            )
        }
    }
}
