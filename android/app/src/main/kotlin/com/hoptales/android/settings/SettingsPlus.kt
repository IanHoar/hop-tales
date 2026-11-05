package com.hoptales.android.settings

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.billing.PlusSource
import com.hoptales.android.design.Glyphs
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PaperButton
import com.hoptales.android.design.paperField
import com.hoptales.content.PlusLinks
import com.hoptales.content.PlusStatus

enum class PlusRequest { SUBSCRIBE, MANAGE, REFUND }

@Composable
fun SettingsSheet(
    state: SettingsState,
    actions: SettingsActions,
    plus: PlusSource,
    openLink: (String) -> Unit,
    gate: ParentGateState = remember { ParentGateState.drawing() },
) {
    val packageName = LocalContext.current.packageName
    var asking by rememberSaveable { mutableStateOf<PlusRequest?>(null) }
    var paying by rememberSaveable { mutableStateOf(false) }
    val request = asking
    when {
        paying -> {
            BackHandler { paying = false }
            Paywall(plus, onClose = { paying = false })
        }

        request != null -> {
            BackHandler { asking = null }
            ParentGate(
                onPassed = {
                    asking = null
                    when (request) {
                        PlusRequest.SUBSCRIBE -> paying = true
                        PlusRequest.MANAGE -> openLink(PlusLinks.playSubscriptions(packageName))
                        PlusRequest.REFUND -> openLink(PlusLinks.PLAY_REFUNDS)
                    }
                },
                onClose = { asking = null },
                initial = gate,
            )
        }

        else -> {
            BackHandler(onBack = actions.done)
            SettingsContent(state, actions) { asking = it }
        }
    }
}

@Composable
fun PlusRow(state: SettingsState, onPlus: (PlusRequest) -> Unit) {
    Column(
        Modifier
            .fillMaxWidth()
            .paperField()
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        if (state.plusStatus.canSubscribe) {
            PlusUpsell { onPlus(PlusRequest.SUBSCRIBE) }
        } else {
            PlusMembership(state.plusStatus, onPlus)
        }
    }
}

@Composable
private fun PlusUpsell(unlock: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text("Every story, at every level", style = type.display(20.sp), color = paper.ink)
        Text(
            "Level 1 is free. ${PlusStatus.GIVES} ${PlusStatus.RHYTHM}",
            style = type.ui(15.sp),
            color = paper.muted,
        )
    }
    PaperButton("Unlock Hop Tales Plus", onClick = unlock)
}

@Composable
private fun PlusMembership(status: PlusStatus, onPlus: (PlusRequest) -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(status.line(), style = type.display(20.sp), color = paper.ink)
        status.detail?.let { Text(it, style = type.ui(15.sp, FontWeight.Medium), color = paper.muted) }
    }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        ActionChip("Manage subscription", Glyphs.share) { onPlus(PlusRequest.MANAGE) }
        if (status.canRequestRefund) ActionChip("Request a refund", Glyphs.uturnBackward) { onPlus(PlusRequest.REFUND) }
    }
}
