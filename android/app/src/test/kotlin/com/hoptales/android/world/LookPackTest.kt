package com.hoptales.android.world

import com.hoptales.android.BuildConfig
import com.hoptales.content.Friend
import com.hoptales.content.startingLook
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File
import java.io.FileNotFoundException

class LookPackTest {
    @get:Rule
    val temporary = TemporaryFolder()

    private class FakeDelivery(var path: String? = null, val reply: PackStatus? = null) : PackDelivery {
        var fetches = 0
        var listener: ((String, PackStatus) -> Unit)? = null

        override fun assetsPath(pack: String): String? = path

        override fun status(pack: String, onStatus: (PackStatus) -> Unit) {
            reply?.let(onStatus)
        }

        override fun fetch(pack: String) {
            fetches += 1
        }

        override fun listen(onStatus: (pack: String, status: PackStatus) -> Unit) {
            listener = onStatus
        }

        fun land(path: String) {
            this.path = path
            listener?.invoke(LookPack.NAME, PackStatus.INSTALLED)
        }
    }

    @Test
    fun anInstalledPackIsUsedStraightAway() {
        val delivery = FakeDelivery(path = "/packs/looks/assets")
        val pack = LookPack(delivery).apply { start() }
        assertEquals(File("/packs/looks/assets"), pack.sheets.value)
        assertEquals(0, delivery.fetches)
    }

    @Test
    fun aPackOnItsWayAppearsWhenItLands() {
        val delivery = FakeDelivery(reply = PackStatus.ON_THE_WAY)
        val pack = LookPack(delivery).apply { start() }
        assertNull(pack.sheets.value)
        delivery.land("/packs/looks/assets")
        assertEquals(File("/packs/looks/assets"), pack.sheets.value)
        assertEquals(0, delivery.fetches)
    }

    @Test
    fun aMissingPackIsFetchedOnce() {
        val delivery = FakeDelivery(reply = PackStatus.MISSING)
        val pack = LookPack(delivery).apply { start() }
        delivery.listener?.invoke(LookPack.NAME, PackStatus.MISSING)
        assertEquals(1, delivery.fetches)
        assertNull(pack.sheets.value)
        delivery.land("/packs/looks/assets")
        assertEquals(File("/packs/looks/assets"), pack.sheets.value)
    }

    @Test
    fun aPackPlayCannotDeliverIsLeftAlone() {
        val delivery = FakeDelivery(reply = PackStatus.UNAVAILABLE)
        val pack = LookPack(delivery).apply { start() }
        delivery.listener?.invoke("other", PackStatus.MISSING)
        assertEquals(0, delivery.fetches)
        assertNull(pack.sheets.value)
    }

    @Test
    fun aSheetInThePackComesFromThePack() {
        val pack = temporary.newFolder("looks")
        pack.resolve("look-hare-crown-idle.webp").writeText("pack")
        assertEquals("pack", read("look-hare-crown-idle", pack, mapOf("look-hare-crown-idle.webp" to "bundled")))
    }

    @Test
    fun aSheetNotInThePackComesFromTheApp() {
        val pack = temporary.newFolder("looks")
        assertEquals("bundled", read("look-hare-scarf-idle", pack, mapOf("look-hare-scarf-idle.webp" to "bundled")))
        assertEquals("bundled", read("look-hare-crown-idle", null, mapOf("look-hare-crown-idle.webp" to "bundled")))
        assertEquals("png", read("hare-sit", null, mapOf("hare-sit.png" to "png")))
    }

    @Test
    fun aSheetThatHasNotLandedIsNothing() {
        assertNull(read("look-hare-crown-idle", temporary.newFolder("looks"), emptyMap()))
        assertNull(read("look-hare-crown-idle", null, emptyMap()))
    }

    @Test
    fun theAppKeepsEveryFriendsStartingLook() {
        val kept = BuildConfig.BASE_LOOKS.split(",").map { "look-$it" }.toSet()
        assertEquals(Friend.entries.mapNotNull { it.startingLook() }.toSet(), kept)
    }

    private fun read(name: String, pack: File?, bundled: Map<String, String>): String? =
        ArtFile.open(name, pack) { file -> bundled[file]?.byteInputStream() ?: throw FileNotFoundException(file) }
            ?.use { it.readBytes().decodeToString() }
}
