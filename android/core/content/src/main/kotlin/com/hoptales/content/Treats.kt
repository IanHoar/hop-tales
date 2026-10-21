package com.hoptales.content

import kotlinx.serialization.Serializable

data class StoryTreat(val word: WordRef, val friend: Friend, val isTrail: Boolean)

data class CollectedTreat(val friend: Friend, val isTrail: Boolean, val isGolden: Boolean) {
    val worth: Int get() = if (isGolden) Levels.GOLDEN_TREAT_WORTH else 1
}

@Serializable
data class Basket(val total: Int = 0, val golden: Int = 0, val filled: Int = 0, val inBasket: Int = 0) {
    val goal: Int get() = Levels.treatsForBasket(filled + 1)

    fun adding(treat: CollectedTreat): Pair<Basket, Int> {
        var basket = copy(
            total = total + treat.worth,
            golden = golden + if (treat.isGolden) 1 else 0,
            inBasket = inBasket + treat.worth,
        )
        var presents = 0
        while (basket.inBasket >= basket.goal) {
            basket = basket.copy(inBasket = basket.inBasket - basket.goal, filled = basket.filled + 1)
            presents += 1
        }
        return basket to presents
    }
}

fun Journey.treat(story: Story): StoryTreat? {
    if (story.isBigStory) return null
    val last = story.sentences.lastIndex
    if (last < 0) return null
    val words = story.sentences[last].words.size
    if (words <= 1) return null
    val word = WordRef(last, (words - 1) / 2)
    val next = nextFriend
    if (story.stretch && story.level == level && next != null) return StoryTreat(word, next, isTrail = true)
    return StoryTreat(word, story.friend, isTrail = false)
}

fun Progress.collecting(treat: CollectedTreat): Recorded<Progress> {
    if (treat.isTrail) return Recorded(this, emptyList())
    val (basket, presents) = (baskets[treat.friend] ?: Basket()).adding(treat)
    val moments = (0 until presents).map { offset ->
        JourneyMoment.BasketFull(treat.friend, number = basket.filled - presents + offset + 1)
    }
    return Recorded(copy(baskets = baskets + (treat.friend to basket)), moments)
}
