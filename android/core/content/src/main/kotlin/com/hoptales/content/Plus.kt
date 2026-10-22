package com.hoptales.content

object Plus {
    const val FREE_LEVEL = 1

    fun isLocked(story: Story, isPlus: Boolean, locksStories: Boolean): Boolean = locksStories && !story.isFree && !isPlus
}

enum class PlusPlan(val appStoreProductId: String, val playBasePlanId: String) {
    MONTHLY("com.hoptales.plus.monthly", "monthly"),
    YEARLY("com.hoptales.plus.yearly", "yearly"),
    ;

    val playOfferId: String? get() = if (this == YEARLY) PLAY_TRIAL_OFFER_ID else null

    companion object {
        const val APP_STORE_GROUP = "hop_tales_plus"
        const val PLAY_PRODUCT_ID = "hop_tales_plus"
        const val PLAY_TRIAL_OFFER_ID = "yearly-free-trial"

        fun fromAppStore(productId: String): PlusPlan? = entries.firstOrNull { it.appStoreProductId == productId }

        fun fromPlay(productId: String, basePlanId: String): PlusPlan? =
            if (productId == PLAY_PRODUCT_ID) entries.firstOrNull { it.playBasePlanId == basePlanId } else null
    }
}
