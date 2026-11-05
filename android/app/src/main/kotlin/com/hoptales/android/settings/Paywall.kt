package com.hoptales.android.settings

import androidx.activity.compose.LocalActivity
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.billing.PlusOffer
import com.hoptales.android.billing.PlusSource
import com.hoptales.android.billing.PurchaseOutcome
import com.hoptales.android.design.Deckle
import com.hoptales.android.design.Glyphs
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PaperQuietButton
import com.hoptales.android.design.Press
import com.hoptales.android.design.paperField
import com.hoptales.android.design.pressable
import com.hoptales.android.home.DoneChip
import com.hoptales.android.world.IdleFriend
import com.hoptales.android.world.MeadowBackdrop
import com.hoptales.content.Friend
import com.hoptales.content.PlusLinks
import com.hoptales.content.PlusPlan
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

sealed interface PaywallOffers {
    data object Loading : PaywallOffers

    data object Unavailable : PaywallOffers

    data class Loaded(val offers: List<PlusOffer>) : PaywallOffers
}

@Stable
class PaywallState(private val plus: PlusSource) {
    var offers by mutableStateOf<PaywallOffers>(PaywallOffers.Loading)
    var pending by mutableStateOf(false)
    var foundNothingToRestore by mutableStateOf(false)

    suspend fun load() {
        val loaded = PlusOffer.inPaywallOrder(runCatching { plus.offers() }.getOrDefault(emptyList()))
        offers = if (loaded.isEmpty()) PaywallOffers.Unavailable else PaywallOffers.Loaded(loaded)
    }

    fun settle(outcome: PurchaseOutcome) {
        when (outcome) {
            PurchaseOutcome.PURCHASED -> plus.refresh()
            PurchaseOutcome.PENDING -> pending = true
            PurchaseOutcome.CANCELLED, PurchaseOutcome.FAILED -> Unit
        }
    }

    suspend fun restore() {
        foundNothingToRestore = false
        foundNothingToRestore = !plus.restore()
    }
}

@Composable
fun Paywall(
    plus: PlusSource,
    onClose: () -> Unit,
    onSubscribed: () -> Unit = onClose,
    state: PaywallState = remember(plus) { PaywallState(plus) },
    live: Boolean = true,
) {
    val activity = LocalActivity.current
    val scope = rememberCoroutineScope()
    val subscribed by rememberUpdatedState(onSubscribed)
    var placeholderDone by remember { mutableStateOf(!live) }
    LaunchedEffect(state) { state.load() }
    LaunchedEffect(Unit) {
        delay(PLACEHOLDER_MILLIS)
        placeholderDone = true
    }
    LaunchedEffect(state) { plus.outcomes.collect(state::settle) }
    LaunchedEffect(plus) {
        var was: Boolean? = null
        plus.isPlus.collect { isPlus ->
            if (isPlus && was == false) subscribed()
            was = isPlus
        }
    }
    Box(Modifier.fillMaxSize()) {
        MeadowBackdrop(live = live)
        PaperSheet(
            header = {
                Row(
                    Modifier.fillMaxWidth().height(HEADER_HEIGHT).padding(end = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Spacer(Modifier.weight(1f))
                    DoneChip(onClose, label = "Close")
                }
            },
        ) {
            val offers = state.offers
            when {
                state.pending -> Waiting(onClose)

                offers is PaywallOffers.Unavailable -> Unavailable(onClose)

                else -> {
                    Pitch()
                    val loaded = (offers as? PaywallOffers.Loaded)?.offers?.takeIf { placeholderDone }
                    Crossfade(loaded, animationSpec = tween(300), label = "plans") { shown ->
                        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                            if (shown == null) {
                                Column(
                                    Modifier.clearAndSetSemantics { contentDescription = "Finding the plans" },
                                    verticalArrangement = Arrangement.spacedBy(14.dp),
                                ) {
                                    PlusOffer.SAMPLES.forEach { offer -> PlanRow(offer, placeholder = true) {} }
                                }
                            } else {
                                shown.forEach { offer -> PlanRow(offer) { plus.buy(activity, offer) } }
                            }
                        }
                    }
                    Spacer(Modifier.weight(1f))
                    Footer(state) { scope.launch { state.restore() } }
                }
            }
        }
    }
}

@Composable
private fun PaperSheet(header: @Composable () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    val paper = LocalPaper.current
    val shape = remember { Deckle(seed = 29, jitter = 3.dp, step = 14.dp) }
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val fill = (maxHeight - HEADER_HEIGHT - SHEET_TOP - SHEET_BOTTOM).coerceAtLeast(0.dp)
        Column(
            Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(start = 12.dp, end = 12.dp, bottom = SHEET_BOTTOM),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            header()
            Spacer(Modifier.height(SHEET_TOP))
            Column(
                Modifier
                    .widthIn(max = 460.dp)
                    .fillMaxWidth()
                    .heightIn(min = fill)
                    .graphicsLayer()
                    .dropShadow(shape, Shadow(8.dp, paper.shadow, offset = DpOffset(0.dp, 5.dp)))
                    .background(paper.paper, shape)
                    .clip(shape)
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(14.dp),
                content = content,
            )
        }
    }
}

private val HEADER_HEIGHT = 64.dp
private val SHEET_TOP = 8.dp
private val SHEET_BOTTOM = 30.dp

@Composable
private fun Title(text: String, size: Int = 30) {
    Text(
        text,
        style = LocalTypography.current.display(size.sp),
        color = LocalPaper.current.ink,
        textAlign = TextAlign.Center,
        modifier = Modifier.semantics { heading() },
    )
}

@Composable
private fun Body(text: String) {
    Text(text, style = LocalTypography.current.ui(17.sp, FontWeight.Medium), color = LocalPaper.current.muted, textAlign = TextAlign.Center)
}

val PLUS_BENEFITS = listOf("Unlock all reading levels", "More characters", "More stories", "More costumes")

@Composable
private fun PaywallScene() {
    Box(
        Modifier
            .bleed(24.dp)
            .padding(bottom = 6.dp)
            .height(174.dp)
            .clipToBounds()
            .graphicsLayer()
            .clearAndSetSemantics {},
    ) {
        MeadowBackdrop(progress = 450f, world = Friend.GRASSHOPPER, framing = halfWide, live = false)
        IdleFriend(
            Friend.GRASSHOPPER,
            look = null,
            height = 84.dp,
            modifier = Modifier.align(Alignment.BottomCenter).padding(bottom = 44.dp),
            shadow = LocalPaper.current.shadow,
        )
    }
}

private fun Modifier.bleed(edge: Dp) = layout { measurable, constraints ->
    val extra = edge.roundToPx()
    val width = constraints.maxWidth + extra * 2
    val placeable = measurable.measure(constraints.copy(minWidth = width, maxWidth = width))
    layout(constraints.maxWidth, (placeable.height - extra).coerceAtLeast(0)) { placeable.place(-extra, -extra) }
}

@Composable
private fun Pitch() {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        PaywallScene()
        Title("Hop Tales Plus")
        Column(Modifier.padding(vertical = 4.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            PLUS_BENEFITS.forEach { benefit ->
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Icon(Glyphs.check, contentDescription = null, tint = paper.ink, modifier = Modifier.size(18.dp))
                    Text(benefit, style = type.ui(17.sp, FontWeight.Medium), color = paper.ink)
                }
            }
        }
    }
}

@Composable
private fun PlanRow(offer: PlusOffer, placeholder: Boolean = false, onClick: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val leads = offer.plan == PlusPlan.YEARLY
    val name = if (leads) "Yearly" else "Monthly"
    val price = if (leads) "${offer.price} a year" else "${offer.price} a month"
    val detail = offer.monthlyPrice?.let { "Just $it a month, the better value" } ?: "The flexible option"
    Row(
        Modifier
            .fillMaxWidth()
            .clearAndSetSemantics {
                contentDescription = "$name, $price. $detail."
                role = Role.Button
            }.then(if (placeholder) Modifier else Modifier.pressable(onClick, press = Press.PAPER))
            .paperField(selected = leads)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(name, style = type.display(21.sp), color = paper.ink, modifier = Modifier.redacted(placeholder))
                if (leads) {
                    Text(
                        "Best value",
                        style = type.ui(13.sp, FontWeight.Bold),
                        color = paper.onRed,
                        maxLines = 1,
                        modifier = Modifier
                            .background(paper.red, CircleShape)
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                            .redacted(placeholder),
                    )
                }
            }
            Text(detail, style = type.ui(14.sp, FontWeight.Medium), color = paper.muted, modifier = Modifier.redacted(placeholder))
        }
        Text(
            price,
            style = type.ui(17.sp, FontWeight.Bold),
            color = paper.ink,
            textAlign = TextAlign.End,
            modifier = Modifier.redacted(placeholder),
        )
    }
}

const val PLAY_DISCLOSURE =
    "Hop Tales Plus renews automatically until you cancel. Payment is charged to your Google Play account, and each plan " +
        "renews at the same price unless you cancel before the period ends. Cancel any time in Google Play."

@Composable
private fun Footer(state: PaywallState, onRestore: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val uri = LocalUriHandler.current
    Column(
        Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(PLAY_DISCLOSURE, style = type.ui(11.sp), color = paper.muted, textAlign = TextAlign.Center)
        if (state.foundNothingToRestore) {
            Text(
                "There's no Hop Tales Plus subscription to restore on this Google account.",
                style = type.ui(12.sp, FontWeight.Medium),
                color = paper.ink,
                textAlign = TextAlign.Center,
            )
        }
        Row(
            Modifier.heightIn(min = 44.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            FooterButton("Restore purchases", type.ui(12.sp, FontWeight.SemiBold), paper.ink, onRestore)
            FooterButton("Terms of Use", link(type.ui(12.sp, FontWeight.Medium)), paper.muted) { uri.openUri(PlusLinks.TERMS) }
            FooterButton("Privacy Policy", link(type.ui(12.sp, FontWeight.Medium)), paper.muted) { uri.openUri(PlusLinks.PRIVACY) }
        }
    }
}

private fun link(style: TextStyle) = style.copy(textDecoration = TextDecoration.Underline)

@Composable
private fun FooterButton(text: String, style: TextStyle, color: Color, onClick: () -> Unit) {
    Text(
        text,
        style = style,
        color = color,
        maxLines = 1,
        modifier = Modifier.heightIn(min = 44.dp).wrapContentHeight().pressable(onClick, role = Role.Button),
    )
}

const val PLACEHOLDER_MILLIS = 1500L

@Composable
private fun Modifier.redacted(on: Boolean): Modifier {
    if (!on) return this
    val bar = LocalPaper.current.muted.copy(alpha = 0.22f)
    return drawWithContent { drawRoundRect(bar, cornerRadius = CornerRadius(4.dp.toPx())) }
}

@Composable
private fun Unavailable(leave: () -> Unit) {
    Title("The store isn't answering", size = 26)
    Body("We couldn't load the plans from Google Play just now. Please try again later. Every Level 1 story stays free to read.")
    PaperQuietButton("Back to stories", onClick = leave)
}

@Composable
private fun Waiting(leave: () -> Unit) {
    Title("Waiting for the store", size = 26)
    Body("Your purchase is waiting to go through. Every story opens as soon as it does, so you can close this now.")
    PaperQuietButton("Back to stories", onClick = leave)
}
