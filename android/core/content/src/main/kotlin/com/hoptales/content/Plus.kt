package com.hoptales.content

object Plus {
    const val FREE_LEVEL = 1

    fun isLocked(story: Story, isPlus: Boolean, locksStories: Boolean): Boolean = locksStories && !story.isFree && !isPlus

    fun offersAtOnboarding(profile: Profile, isPlus: Boolean, locksStories: Boolean): Boolean =
        locksStories && !isPlus && !profile.plusOffered
}

object PlusLinks {
    const val TERMS = "https://www.hoptales.com/terms.html"
    const val PRIVACY = "https://www.hoptales.com/privacy.html"
}

enum class PlusPlan(val appStoreProductId: String, val playBasePlanId: String, val months: Int) {
    MONTHLY("com.hoptales.plus.monthly", "monthly", 1),
    YEARLY("com.hoptales.plus.yearly", "yearly", 12),
    ;

    companion object {
        const val APP_STORE_GROUP = "hop_tales_plus"
        const val PLAY_PRODUCT_ID = "hop_tales_plus"
        val PAYWALL_ORDER = listOf(YEARLY, MONTHLY)

        fun fromAppStore(productId: String): PlusPlan? = entries.firstOrNull { it.appStoreProductId == productId }

        fun fromPlay(productId: String, basePlanId: String): PlusPlan? =
            if (productId == PLAY_PRODUCT_ID) entries.firstOrNull { it.playBasePlanId == basePlanId } else null
    }
}
