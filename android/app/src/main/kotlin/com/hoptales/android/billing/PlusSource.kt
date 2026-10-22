package com.hoptales.android.billing

import android.app.Activity
import com.hoptales.android.BuildConfig
import com.hoptales.content.Plus
import com.hoptales.content.PlusStatus
import com.hoptales.content.Story
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow

interface PlusSource {
    val isPlus: StateFlow<Boolean>

    val status: StateFlow<PlusStatus>

    val outcomes: SharedFlow<PurchaseOutcome>

    fun refresh()

    suspend fun offers(): List<PlusOffer>

    fun buy(activity: Activity?, offer: PlusOffer)

    suspend fun restore(): Boolean

    fun isLocked(story: Story): Boolean = Plus.isLocked(story, isPlus.value, BuildConfig.PLUS_LOCKS_STORIES)
}

class FakePlusSource(
    isPlus: Boolean = false,
    private val offers: List<PlusOffer>? = PlusOffer.SAMPLES,
    private val outcome: PurchaseOutcome = PurchaseOutcome.PURCHASED,
    private val restores: Boolean = false,
    status: PlusStatus? = null,
) : PlusSource {
    override val isPlus = MutableStateFlow(isPlus)

    override val status = MutableStateFlow(status ?: if (isPlus) PlusStatus.Renews() else PlusStatus.Free)

    private val outcomeFlow = MutableSharedFlow<PurchaseOutcome>(extraBufferCapacity = 4)
    override val outcomes: SharedFlow<PurchaseOutcome> = outcomeFlow.asSharedFlow()

    var refreshes = 0
        private set

    val bought = mutableListOf<PlusOffer>()

    private var owns = false

    override fun refresh() {
        refreshes += 1
        if (owns) {
            isPlus.value = true
            if (status.value == PlusStatus.Free) status.value = PlusStatus.Renews()
        }
    }

    override suspend fun offers(): List<PlusOffer> = offers.orEmpty()

    override fun buy(activity: Activity?, offer: PlusOffer) {
        bought += offer
        if (outcome == PurchaseOutcome.PURCHASED) owns = true
        outcomeFlow.tryEmit(outcome)
    }

    override suspend fun restore(): Boolean {
        if (restores) owns = true
        refresh()
        return isPlus.value
    }
}
