package com.hoptales.content

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class Slot(val title: String) {
    @SerialName("head")
    HEAD("Hats"),

    @SerialName("eyes")
    EYES("Glasses"),

    @SerialName("neck")
    NECK("Neck"),

    @SerialName("body")
    BODY("Coats"),

    @SerialName("back")
    BACK("Bags"),

    @SerialName("claws")
    CLAWS("Claws"),

    @SerialName("antennae")
    ANTENNAE("Antennae"),
}

@Serializable
data class WardrobePart(val x: Double, val y: Double, val w: Double, val rot: Double, val pivot: List<Double>)

@Serializable
data class WardrobeItem(val id: String, val name: String, val slot: Slot, val parts: List<WardrobePart>)

class WardrobeLibrary(val all: Map<Friend, List<WardrobeItem>>, val painted: Map<Friend, Set<String>>) {
    fun items(friend: Friend): List<WardrobeItem> {
        val library = all[friend].orEmpty()
        val painted = painted[friend].orEmpty()
        return wearable[friend].orEmpty().filter { it in painted }.mapNotNull { id -> library.firstOrNull { it.id == id } }
    }

    fun startingItem(friend: Friend): WardrobeItem? = starting[friend]?.let { id -> items(friend).firstOrNull { it.id == id } }

    fun unlockable(friend: Friend): List<WardrobeItem> = items(friend).filter { it.id != starting[friend] }

    companion object {
        val wearable: Map<Friend, List<String>> = mapOf(
            Friend.HARE to listOf("scarf", "straw", "bowtie", "crown", "specs", "satchel"),
            Friend.BUNNY to listOf("bow", "bluebell-crown", "bonnet", "heart-glasses", "daisy-chain", "basket-pack"),
            Friend.FROG to listOf("neckerchief", "lilypad-hat", "goggles", "check-bowtie", "reed-satchel", "raincoat"),
            Friend.CROW to listOf("knit-cap", "flat-cap", "top-hat", "aviator-goggles", "autumn-scarf", "post-satchel"),
            Friend.CAT to listOf("sage-collar", "garden-hat", "beret", "cateye-glasses", "red-bell-collar", "cardigan"),
            Friend.CRAB to listOf("sailor-kerchief", "sailor-cap", "captain-hat", "diving-mask", "life-ring", "claw-mittens"),
            Friend.GRASSHOPPER to listOf("satchel", "acorn-cap", "antenna-poms", "explorer-goggles", "clover-bowtie", "ladybird-cape"),
        )

        val starting: Map<Friend, String> = mapOf(
            Friend.BUNNY to "bow",
            Friend.HARE to "scarf",
            Friend.FROG to "neckerchief",
            Friend.CROW to "knit-cap",
            Friend.CAT to "sage-collar",
            Friend.CRAB to "sailor-kerchief",
            Friend.GRASSHOPPER to "satchel",
        )

        val empty = WardrobeLibrary(emptyMap(), emptyMap())

        fun decode(wardrobe: String, looks: String): WardrobeLibrary {
            val items = StoryLibrary.json.decodeFromString<Map<String, List<WardrobeItem>>>(wardrobe)
            val painted = StoryLibrary.json.decodeFromString<Map<String, List<String>>>(looks)
            return WardrobeLibrary(
                all = items.byFriend(),
                painted = painted.byFriend().mapValues { it.value.toSet() },
            )
        }

        private fun <T> Map<String, T>.byFriend(): Map<Friend, T> =
            entries.mapNotNull { (key, value) -> Friend.entries.firstOrNull { it.key == key }?.let { it to value } }.toMap()
    }
}

fun Friend.startingLook(): String? = WardrobeLibrary.starting[this]?.let { "look-$key-$it" }

fun Progress.unlockedCount(friend: Friend, wardrobe: WardrobeLibrary): Int {
    if (friend !in journey.met) return 0
    val items = wardrobe.unlockable(friend).size
    return minOf(1 + (baskets[friend]?.filled ?: 0), items)
}

fun Progress.isUnlocked(item: WardrobeItem, friend: Friend, wardrobe: WardrobeLibrary): Boolean {
    if (item == wardrobe.startingItem(friend)) return true
    val index = wardrobe.unlockable(friend).indexOf(item)
    if (index < 0) return false
    return index < unlockedCount(friend, wardrobe)
}

fun Progress.newestItem(friend: Friend, wardrobe: WardrobeLibrary): WardrobeItem? {
    val count = unlockedCount(friend, wardrobe)
    return if (count > 0) wardrobe.unlockable(friend)[count - 1] else null
}

fun Progress.outfit(friend: Friend, wardrobe: WardrobeLibrary): List<WardrobeItem> {
    val chosen = choices(friend, wardrobe)
    return wardrobe.items(friend).filter { chosen[it.slot] == it.id && isUnlocked(it, friend, wardrobe) }
}

fun Progress.wearing(item: WardrobeItem, friend: Friend, wardrobe: WardrobeLibrary): Progress {
    if (!isUnlocked(item, friend, wardrobe)) return this
    return copy(outfits = outfits + (friend to mapOf(item.slot to item.id)))
}

fun Progress.undressing(friend: Friend): Progress = copy(outfits = outfits + (friend to emptyMap()))

fun Progress.takingOff(slot: Slot, friend: Friend, wardrobe: WardrobeLibrary): Progress =
    copy(outfits = outfits + (friend to choices(friend, wardrobe) - slot))

private fun Progress.choices(friend: Friend, wardrobe: WardrobeLibrary): Map<Slot, String> {
    outfits[friend]?.let { return it }
    val item = wardrobe.startingItem(friend) ?: return emptyMap()
    return mapOf(item.slot to item.id)
}

fun JourneyMoment.unlockedItem(wardrobe: WardrobeLibrary): WardrobeItem? {
    if (this !is JourneyMoment.BasketFull) return null
    val items = wardrobe.unlockable(friend)
    return items.getOrNull(number)
}
