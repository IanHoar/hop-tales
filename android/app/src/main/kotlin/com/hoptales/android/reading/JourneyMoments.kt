package com.hoptales.android.reading

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.Deckle
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.Press
import com.hoptales.android.design.paperChip
import com.hoptales.android.design.pressable
import com.hoptales.android.design.rememberReducedMotion
import com.hoptales.android.world.FriendSticker
import com.hoptales.android.world.Sticker
import com.hoptales.android.world.TreatSticker
import com.hoptales.android.world.WearSticker
import com.hoptales.content.CollectedTreat
import com.hoptales.content.Friend
import com.hoptales.content.JourneyMoment
import com.hoptales.content.LevelUp
import com.hoptales.content.Levels
import com.hoptales.content.Story
import com.hoptales.content.StoryTreat
import com.hoptales.content.WardrobeItem
import com.hoptales.content.unlockedItem
import com.hoptales.reading.ReadingState
import kotlin.math.roundToInt

@Composable
fun TallyCard(tally: JourneyMoment.Tally, found: JourneyMoment.TreatFound?, geometry: PathGeometry, modifier: Modifier = Modifier) {
    val type = LocalTypography.current
    val reached = tally.total >= tally.goal
    val paper = LocalPaper.current
    val card = remember(geometry) { Deckle(seed = 21, jitter = geometry.dp(2.4f), step = geometry.dp(10f)) }
    Column(
        modifier
            .widthIn(max = geometry.dp(320f))
            .rotate(-1.5f)
            .dropShadow(card, Shadow(geometry.dp(8f), paper.shadow, offset = DpOffset(0.dp, geometry.dp(5f))))
            .background(paper.paper, card)
            .padding(geometry.dp(16f))
            .clearAndSetSemantics {
                contentDescription = "${tally.steps.roundToInt()} steps. ${tally.total.toInt()} of ${tally.goal.toInt()} on the path to " +
                    "${tally.next.friendName}." +
                    if (tally.storiesLeft > 0 && reached) " ${tally.storiesLeft} more stories to read first." else ""
            },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(geometry.dp(10f)),
    ) {
        found?.let { (treat, trail) ->
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(geometry.dp(6f))) {
                TreatSticker(treat.friend, geometry.dp(26f), isGolden = treat.isGolden)
                Text(treatLine(treat, trail), style = type.display(geometry.sp(17f)), color = paper.ink)
            }
        }
        if (tally.bigWords > 0) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(geometry.dp(6f))) {
                Sticker("collect-star", Modifier.size(geometry.dp(22f)))
                Text(
                    if (tally.bigWords == 1) "A big word read!" else "${tally.bigWords} big words read!",
                    style = type.display(geometry.sp(17f)),
                    color = paper.ink,
                )
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(geometry.dp(12f))) {
            FriendSticker(tally.next, geometry.dp(46f), Modifier.alpha(if (reached) 1f else 0.55f), isSilhouette = !reached)
            Column(verticalArrangement = Arrangement.spacedBy(geometry.dp(6f))) {
                Text("The path to ${tally.next.friendName}", style = type.display(geometry.sp(16f)), color = paper.ink)
                PathRibbon(if (tally.goal > 0) tally.total / tally.goal else 1.0, geometry)
                Text(
                    "+${tally.steps.roundToInt()} steps · ${tally.total.toInt()} of ${tally.goal.toInt()}",
                    style = type.ui(geometry.sp(13f), FontWeight.Medium).copy(fontFeatureSettings = "tnum"),
                    color = paper.muted,
                )
                if (tally.storiesLeft > 0 && reached) {
                    Text(
                        if (tally.storiesLeft == 1) {
                            "Read one more story to meet ${tally.next.friendName}"
                        } else {
                            "Read ${tally.storiesLeft} more stories to meet ${tally.next.friendName}"
                        },
                        style = type.ui(geometry.sp(13f), FontWeight.SemiBold),
                        color = paper.ink,
                    )
                }
            }
        }
    }
}

fun treatLine(treat: CollectedTreat, trail: Int): String {
    if (treat.isTrail) {
        val treats = treat.friend.treat.many.replaceFirstChar { it.uppercase() }
        return "$treats for ${treat.friend.friendName} · $trail of ${Levels.trailGoal(treat.friend.level - 1)}"
    }
    return if (treat.isGolden) {
        "A golden ${treat.friend.treat.one}! That counts ${treat.worth}."
    } else {
        "You found a ${treat.friend.treat.one}!"
    }
}

@Composable
fun PathRibbon(fill: Double, geometry: PathGeometry, modifier: Modifier = Modifier) {
    val paper = LocalPaper.current
    val track = remember(geometry) { Deckle(seed = 8, jitter = geometry.dp(1.2f), step = geometry.dp(6f)) }
    val filled = remember(geometry) { Deckle(seed = 9, jitter = geometry.dp(1.2f), step = geometry.dp(6f)) }
    Box(modifier.width(geometry.dp(180f)).height(geometry.dp(12f)).background(paper.muted.copy(alpha = 0.22f), track)) {
        Box(Modifier.fillMaxWidth(fill.coerceIn(0.0, 1.0).toFloat()).height(geometry.dp(12f)).background(paper.wash, filled))
    }
}

@Composable
fun CalloutCard(
    moment: JourneyMoment,
    item: WardrobeItem?,
    leads: Boolean,
    primary: () -> Unit,
    dismiss: () -> Unit,
    geometry: PathGeometry,
    modifier: Modifier = Modifier,
    isDone: Boolean = false,
    isLast: Boolean = true,
) {
    val type = LocalTypography.current
    val paper = LocalPaper.current
    var tapped by rememberSaveable(moment.toString()) { mutableStateOf(false) }
    val opened = tapped || isDone
    val waitsForOpening = moment is JourneyMoment.BasketFull && !opened
    val card = remember(geometry) { Deckle(seed = 33, jitter = geometry.dp(2.6f), step = geometry.dp(10f)) }
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
        when (moment) {
            is JourneyMoment.BigStoryReady -> FriendSticker(moment.friend, geometry.dp(120f))

            is JourneyMoment.NotYet -> FriendSticker(moment.friend, geometry.dp(120f))

            is JourneyMoment.NewFriend -> Box(
                Modifier.clearAndSetSemantics { contentDescription = "${moment.friend.friendName}, your new friend" },
            ) { FriendReveal(moment.friend, geometry) }

            is JourneyMoment.BasketFull -> PresentReveal(moment.friend, item, opened, geometry) { tapped = true }

            else -> Unit
        }
        Text(title(moment), style = type.display(geometry.sp(22f)), color = paper.ink, textAlign = TextAlign.Center)
        Text(
            detail(moment, item, opened),
            style = type.ui(geometry.sp(15f), FontWeight.Medium),
            color = paper.ink.copy(alpha = 0.85f),
            textAlign = TextAlign.Center,
        )
        Row(
            Modifier.padding(top = geometry.dp(4f)),
            horizontalArrangement = Arrangement.spacedBy(geometry.dp(10f)),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (waitsForOpening) {
                Text("Tap the present to open it", style = type.ui(geometry.sp(14f), FontWeight.SemiBold), color = paper.muted)
            } else {
                if (!isDone) secondary(moment)?.let { CardButton(it, filled = false, geometry, onClick = dismiss) }
                CardButton(
                    if (isDone) "Done" else primaryTitle(moment, isLast),
                    filled = true,
                    geometry = geometry,
                    onClick = if (leads &&
                        !isDone
                    ) {
                        primary
                    } else {
                        dismiss
                    },
                )
            }
        }
    }
}

@Composable
private fun PresentReveal(friend: Friend, item: WardrobeItem?, opened: Boolean, geometry: PathGeometry, open: () -> Unit) {
    val reduceMotion = rememberReducedMotion()
    val opening = remember { Animatable(if (opened) 1f else 0f) }
    LaunchedEffect(opened) {
        if (!opened) return@LaunchedEffect
        if (reduceMotion) opening.snapTo(1f) else opening.animateTo(1f, swiftSpring(PRESENT_SECONDS, PRESENT_BOUNCE))
    }
    Box(
        Modifier
            .height(geometry.dp(120f))
            .pressable(open, enabled = !opened)
            .semantics { contentDescription = if (opened) item?.name ?: "A present" else "A present. Double tap to open it." },
        contentAlignment = Alignment.Center,
    ) {
        val shown = { opening.value.coerceIn(0f, 1f) }
        if (opened) {
            Sticker("collect-present-open", Modifier.size(geometry.dp(96f)).offset(x = -geometry.dp(40f)).graphicsLayer { alpha = shown() })
            if (item != null) {
                WearSticker(
                    friend,
                    item,
                    geometry.dp(96f),
                    geometry.dp(78f),
                    Modifier.offset(x = geometry.dp(56f), y = -geometry.dp(24f)).graphicsLayer {
                        val scale = PresentMotion.itemScale(opening.value)
                        scaleX = scale
                        scaleY = scale
                        transformOrigin = TransformOrigin(0f, 1f)
                        alpha = shown()
                    },
                )
            }
        }
        if (opening.value < 1f) {
            Sticker(
                "collect-present",
                Modifier.size(geometry.dp(110f)).graphicsLayer {
                    val scale = PresentMotion.closedScale(opening.value)
                    scaleX = scale
                    scaleY = scale
                    alpha = 1f - shown()
                },
            )
        }
    }
}

@Composable
internal fun CardButton(text: String, filled: Boolean, geometry: PathGeometry, onClick: () -> Unit) {
    val paper = LocalPaper.current
    val style = LocalTypography.current.display(geometry.sp(16f))
    if (filled) {
        Box(
            Modifier
                .pressable(onClick)
                .height(geometry.dp(46f))
                .background(paper.red, CircleShape)
                .border(geometry.dp(3f), paper.rim, CircleShape)
                .padding(horizontal = geometry.dp(18f)),
            contentAlignment = Alignment.Center,
        ) {
            Text(text, style = style, color = paper.onRed)
        }
    } else {
        Box(
            Modifier
                .pressable(onClick, press = Press.PLAIN)
                .height(geometry.dp(46f))
                .paperChip(CircleShape, rim = geometry.dp(3f))
                .padding(horizontal = geometry.dp(16f)),
            contentAlignment = Alignment.Center,
        ) {
            Text(text, style = style, color = paper.ink)
        }
    }
}

private fun title(moment: JourneyMoment): String = when (moment) {
    is JourneyMoment.BigStoryReady -> "${moment.friend.friendName} has a bigger story!"
    is JourneyMoment.NotYet -> "${moment.friend.friendName} will wait for you at ${moment.friend.place}."
    is JourneyMoment.NewFriend -> "Reading level ${moment.friend.level}!"
    is JourneyMoment.BasketFull -> "A full basket!"
    else -> ""
}

private fun detail(moment: JourneyMoment, item: WardrobeItem?, opened: Boolean): String = when (moment) {
    is JourneyMoment.BigStoryReady ->
        "The path is full. Find ${moment.friend.friendName}'s big story on your journey map, and go to ${moment.friend.place} together."

    is JourneyMoment.NotYet -> "The path stays full. Try the big story again whenever you like."

    is JourneyMoment.NewFriend -> {
        val friend = moment.friend
        "${friend.friendName} is your new friend. ${friend.friendName} gave you ${friend.gift}." +
            if (moment.via == LevelUp.TRAIL) " You found all the ${friend.treat.many}!" else ""
    }

    is JourneyMoment.BasketFull -> if (opened) {
        "It's ${item?.let { "a ${it.name.lowercase()}" } ?: "a present"} for ${moment.friend.friendName}!"
    } else {
        "You filled ${moment.friend.friendName}'s basket of ${moment.friend.treat.many}. There's a present inside!"
    }

    else -> ""
}

private fun primaryTitle(moment: JourneyMoment, isLast: Boolean): String = when (moment) {
    is JourneyMoment.BigStoryReady, is JourneyMoment.NewFriend -> if (isLast) "Back to my stories" else "Next"
    is JourneyMoment.NotYet -> "OK"
    is JourneyMoment.BasketFull -> "Try it on"
    else -> ""
}

private fun secondary(moment: JourneyMoment): String? = when (moment) {
    is JourneyMoment.BasketFull -> "Later"
    else -> null
}

@Composable
fun BasketChip(treat: StoryTreat, geometry: PathGeometry, modifier: Modifier = Modifier) {
    val paper = LocalPaper.current
    fun path(value: Float) = (geometry.path(value) / geometry.density).dp
    Row(
        modifier
            .clearAndSetSemantics { contentDescription = "You found a ${treat.friend.treat.one}." }
            .height(path(42f))
            .paperChip(CircleShape, rim = path(3f))
            .padding(horizontal = path(12f)),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(path(6f)),
    ) {
        if (treat.isTrail) {
            FriendSticker(treat.friend, path(28f), Modifier.alpha(TRAIL_ALPHA), isSilhouette = true)
        } else {
            Sticker("collect-basket", Modifier.size(path(28f)))
        }
        TreatSticker(treat.friend, path(22f))
        Text("+1", style = LocalTypography.current.display((geometry.path(16f) / geometry.density).sp), color = paper.ink)
    }
}

@Composable
fun JourneyPanel(
    state: ReadingState,
    geometry: PathGeometry,
    onTryItOn: (Friend) -> Unit,
    isDone: Boolean,
    dismiss: () -> Unit,
    onBackToStories: () -> Unit = dismiss,
) {
    val app = LocalContext.current.applicationContext as HopTalesApplication
    Box(Modifier.fillMaxSize()) {
        MomentCards(state, geometry, app, onTryItOn, isDone, dismiss, onBackToStories)
        if (state.callout is JourneyMoment.NewFriend) PaperConfetti(delayMillis = FriendReveal.CONFETTI_DELAY_MILLIS)
        if (state.callout is JourneyMoment.LevelOneFinished) PaperConfetti(delayMillis = LEVEL_ONE_CONFETTI_DELAY_MILLIS)
    }
}

@Composable
private fun MomentCards(
    state: ReadingState,
    geometry: PathGeometry,
    app: HopTalesApplication,
    onTryItOn: (Friend) -> Unit,
    isDone: Boolean,
    dismiss: () -> Unit,
    onBackToStories: () -> Unit,
) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.TopCenter) {
        val top = (geometry.y(PANEL_Y) / geometry.density).dp
        val moment = state.callout ?: state.tally
        AnimatedContent(
            moment,
            Modifier.padding(top = top),
            transitionSpec = {
                val timing = tween<Float>(MOMENT_MILLIS, easing = EaseInOut)
                val enter = fadeIn(timing) + if (targetState is JourneyMoment.Tally) EnterTransition.None else scaleIn(timing, CALLOUT_FROM)
                val exit =
                    fadeOut(timing) + if (initialState is JourneyMoment.Tally) ExitTransition.None else scaleOut(timing, CALLOUT_FROM)
                enter togetherWith exit
            },
            contentAlignment = Alignment.TopCenter,
            label = "moment",
        ) { shown ->
            when (shown) {
                null -> Unit

                is JourneyMoment.Tally -> TallyCard(shown, state.collectedTreat, geometry)

                JourneyMoment.LevelOneFinished -> LevelOneCard(geometry, backToStories = onBackToStories)

                else -> {
                    val item = shown.unlockedItem(app.wardrobe)
                    val story = shown.story(app.library)
                    CalloutCard(
                        moment = shown,
                        item = item,
                        leads = story != null || item != null,
                        primary = {
                            if (story != null) onBackToStories()
                            if (shown is JourneyMoment.BasketFull) onTryItOn(shown.friend)
                        },
                        dismiss = dismiss,
                        geometry = geometry,
                        isDone = isDone,
                        isLast = state.journeyMoments.count { it.isCallout } <= 1,
                    )
                }
            }
        }
    }
}

object PresentMotion {
    const val ITEM_FROM = 0.2f
    const val CLOSED_TO = 1.1f

    fun itemScale(opening: Float): Float = ITEM_FROM + (1 - ITEM_FROM) * opening

    fun closedScale(opening: Float): Float = 1 + (CLOSED_TO - 1) * opening.coerceIn(0f, 1f)
}

private const val PRESENT_SECONDS = 0.5
private const val PRESENT_BOUNCE = 0.4
private const val TRAIL_ALPHA = 0.6f
private const val MOMENT_MILLIS = 300
private const val CALLOUT_FROM = 0.9f
private const val PANEL_Y = 110f
private const val LEVEL_ONE_CONFETTI_DELAY_MILLIS = 300
