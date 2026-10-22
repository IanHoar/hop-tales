package com.hoptales.android.settings

import androidx.activity.compose.LocalActivity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.billing.PlusOffer
import com.hoptales.android.billing.PlusSource
import com.hoptales.android.billing.PurchaseOutcome
import com.hoptales.android.design.Deckle
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PaperButton
import com.hoptales.android.design.PaperChip
import com.hoptales.android.design.PaperQuietButton
import com.hoptales.android.design.Press
import com.hoptales.android.design.paperField
import com.hoptales.android.design.pressable
import com.hoptales.android.home.DoneChip
import com.hoptales.android.home.PaperTitle
import com.hoptales.android.world.MeadowBackdrop
import com.hoptales.content.PlusLinks
import com.hoptales.content.PlusPlan
import kotlinx.coroutines.launch

sealed interface PaywallOffers {
    data object Loading : PaywallOffers

    data object Unavailable : PaywallOffers

    data class Loaded(val offers: List<PlusOffer>) : PaywallOffers
}

@Stable
class PaywallState(private val plus: PlusSource, val onboarding: Boolean = false) {
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
    onboarding: Boolean = false,
    onTryFree: () -> Unit = onClose,
    state: PaywallState = remember(plus, onboarding) { PaywallState(plus, onboarding) },
    live: Boolean = true,
) {
    val activity = LocalActivity.current
    val scope = rememberCoroutineScope()
    val subscribed by rememberUpdatedState(onSubscribed)
    LaunchedEffect(state) { state.load() }
    LaunchedEffect(state) { plus.outcomes.collect(state::settle) }
    LaunchedEffect(plus) {
        var was: Boolean? = null
        plus.isPlus.collect { isPlus ->
            if (isPlus && was == false) subscribed()
            was = isPlus
        }
    }
    val leave = if (state.onboarding) onTryFree else onClose
    Box(Modifier.fillMaxSize()) {
        MeadowBackdrop(live = live)
        Column(Modifier.fillMaxSize()) {
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                PaperTitle("For grown-ups")
                Spacer(Modifier.weight(1f))
                DoneChip(onClose, label = "Close")
            }
            PaperSheet {
                val offers = state.offers
                when {
                    state.pending -> Waiting(state.onboarding, leave)

                    offers is PaywallOffers.Loading -> Loading()

                    offers is PaywallOffers.Unavailable -> Unavailable(state.onboarding, leave)

                    offers is PaywallOffers.Loaded -> {
                        Pitch()
                        offers.offers.forEach { offer -> PlanRow(offer) { plus.buy(activity, offer) } }
                        Footer(state, onTryFree) { scope.launch { state.restore() } }
                    }
                }
            }
        }
    }
}

@Composable
private fun PaperSheet(content: @Composable ColumnScope.() -> Unit) {
    val paper = LocalPaper.current
    val shape = remember { Deckle(seed = 29, jitter = 3.dp, step = 14.dp) }
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
            content = content,
        )
    }
}

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

@Composable
private fun Pitch() {
    Title("Hop Tales Plus")
    Text(
        "Every story in the meadow, with a new one every month and something new each season.",
        style = LocalTypography.current.ui(17.sp, FontWeight.Medium),
        color = LocalPaper.current.ink,
        textAlign = TextAlign.Center,
    )
}

@Composable
private fun PlanRow(offer: PlusOffer, onClick: () -> Unit) {
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
            }.pressable(onClick, press = Press.PAPER)
            .paperField(selected = leads)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(name, style = type.display(21.sp), color = paper.ink)
                if (leads) {
                    Text(
                        "Best value",
                        style = type.ui(13.sp, FontWeight.Bold),
                        color = paper.onRed,
                        maxLines = 1,
                        modifier = Modifier.background(paper.red, CircleShape).padding(horizontal = 10.dp, vertical = 4.dp),
                    )
                }
            }
            Text(detail, style = type.ui(14.sp, FontWeight.Medium), color = paper.muted)
        }
        Text(price, style = type.ui(17.sp, FontWeight.Bold), color = paper.ink, textAlign = TextAlign.End)
    }
}

const val PLAY_DISCLOSURE =
    "Hop Tales Plus renews automatically until you cancel. Payment is charged to your Google Play account, and each plan " +
        "renews at the same price unless you cancel before the period ends. Cancel any time in Google Play."

@Composable
private fun Footer(state: PaywallState, onTryFree: () -> Unit, onRestore: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val uri = LocalUriHandler.current
    if (state.onboarding) PaperQuietButton("Try Level 1 free", onClick = onTryFree)
    Text(PLAY_DISCLOSURE, style = type.ui(13.sp), color = paper.muted, textAlign = TextAlign.Center)
    PaperChip(onClick = onRestore) {
        Text("Restore purchases", style = type.ui(15.sp, FontWeight.SemiBold), color = paper.ink)
    }
    if (state.foundNothingToRestore) {
        Text(
            "There's no Hop Tales Plus subscription to restore on this Google account.",
            style = type.ui(14.sp, FontWeight.Medium),
            color = paper.muted,
            textAlign = TextAlign.Center,
        )
    }
    Row(horizontalArrangement = Arrangement.spacedBy(18.dp)) {
        Link("Terms of Use") { uri.openUri(PlusLinks.TERMS) }
        Link("Privacy Policy") { uri.openUri(PlusLinks.PRIVACY) }
    }
}

@Composable
private fun Link(text: String, onClick: () -> Unit) {
    Text(
        text,
        style = LocalTypography.current.ui(14.sp, FontWeight.SemiBold).copy(textDecoration = TextDecoration.Underline),
        color = LocalPaper.current.ink,
        modifier = Modifier.pressable(onClick, role = Role.Button),
    )
}

@Composable
private fun Loading() {
    Title("Hop Tales Plus")
    Body("Finding the plans…")
}

@Composable
private fun Unavailable(onboarding: Boolean, leave: () -> Unit) {
    Title("The store isn't answering", size = 26)
    Body("We couldn't load the plans from Google Play just now. Please try again later. Every Level 1 story stays free to read.")
    Leave(onboarding, leave)
}

@Composable
private fun Waiting(onboarding: Boolean, leave: () -> Unit) {
    Title("Waiting for the store", size = 26)
    Body("Your purchase is waiting to go through. Every story opens as soon as it does, so you can close this now.")
    Leave(onboarding, leave)
}

@Composable
private fun Leave(onboarding: Boolean, leave: () -> Unit) {
    if (onboarding) PaperButton("Try Level 1 free", onClick = leave) else PaperQuietButton("Back to stories", onClick = leave)
}
