package com.hoptales.android.onboarding

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import com.hoptales.android.billing.PlusSource
import com.hoptales.android.settings.ParentGate
import com.hoptales.android.settings.ParentGateState
import com.hoptales.android.settings.Paywall

enum class PlusOfferStep { GATE, PAYWALL }

@Composable
fun PlusOfferScreen(
    plus: PlusSource,
    onDone: () -> Unit,
    step: PlusOfferStep = PlusOfferStep.GATE,
    gate: ParentGateState = remember { ParentGateState.drawing() },
    live: Boolean = true,
) {
    var shown by rememberSaveable { mutableStateOf(step) }
    when (shown) {
        PlusOfferStep.GATE -> ParentGate(onPassed = { shown = PlusOfferStep.PAYWALL }, onClose = onDone, initial = gate)

        PlusOfferStep.PAYWALL -> Paywall(
            plus,
            onClose = onDone,
            onSubscribed = onDone,
            onboarding = true,
            onTryFree = onDone,
            live = live,
        )
    }
}
