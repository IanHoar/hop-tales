package com.hoptales.android.world

import android.content.Context
import com.google.android.play.core.assetpacks.AssetPackManagerFactory
import com.google.android.play.core.assetpacks.model.AssetPackStatus
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.io.File

enum class PackStatus {
    INSTALLED,
    ON_THE_WAY,
    MISSING,
    UNAVAILABLE,
}

interface PackDelivery {
    fun assetsPath(pack: String): String?

    fun status(pack: String, onStatus: (PackStatus) -> Unit)

    fun fetch(pack: String)

    fun listen(onStatus: (pack: String, status: PackStatus) -> Unit)
}

class LookPack(private val delivery: PackDelivery) {
    private val folder = MutableStateFlow<File?>(null)
    private var fetched = false

    val sheets: StateFlow<File?> = folder.asStateFlow()

    fun start() {
        attempt { delivery.listen { pack, status -> if (pack == NAME) heard(status) } }
        if (!located()) attempt { delivery.status(NAME, ::heard) }
    }

    private fun heard(status: PackStatus) {
        when (status) {
            PackStatus.INSTALLED -> located()

            PackStatus.MISSING -> if (!fetched && !located()) {
                fetched = true
                attempt { delivery.fetch(NAME) }
            }

            PackStatus.ON_THE_WAY, PackStatus.UNAVAILABLE -> Unit
        }
    }

    private fun located(): Boolean {
        val path = attempt { delivery.assetsPath(NAME) } ?: return false
        folder.value = File(path)
        return true
    }

    private inline fun <T> attempt(call: () -> T): T? = runCatching(call).getOrNull()

    companion object {
        const val NAME = "looks"

        val bundled = LookPack(
            object : PackDelivery {
                override fun assetsPath(pack: String): String? = null

                override fun status(pack: String, onStatus: (PackStatus) -> Unit) = Unit

                override fun fetch(pack: String) = Unit

                override fun listen(onStatus: (pack: String, status: PackStatus) -> Unit) = Unit
            },
        )
    }
}

class PlayPackDelivery(context: Context) : PackDelivery {
    private val manager by lazy { AssetPackManagerFactory.getInstance(context.applicationContext) }

    override fun assetsPath(pack: String): String? = manager.getPackLocation(pack)?.assetsPath()

    override fun status(pack: String, onStatus: (PackStatus) -> Unit) {
        manager.getPackStates(listOf(pack))
            .addOnSuccessListener { states -> states.packStates()[pack]?.let { onStatus(packStatus(it.status())) } }
            .addOnFailureListener { onStatus(PackStatus.UNAVAILABLE) }
    }

    override fun fetch(pack: String) {
        manager.fetch(listOf(pack))
    }

    override fun listen(onStatus: (pack: String, status: PackStatus) -> Unit) {
        manager.registerListener { state -> onStatus(state.name(), packStatus(state.status())) }
    }

    private fun packStatus(status: Int): PackStatus = when (status) {
        AssetPackStatus.COMPLETED -> PackStatus.INSTALLED

        AssetPackStatus.PENDING,
        AssetPackStatus.DOWNLOADING,
        AssetPackStatus.TRANSFERRING,
        AssetPackStatus.WAITING_FOR_WIFI,
        -> PackStatus.ON_THE_WAY

        AssetPackStatus.NOT_INSTALLED,
        AssetPackStatus.FAILED,
        AssetPackStatus.CANCELED,
        -> PackStatus.MISSING

        else -> PackStatus.UNAVAILABLE
    }
}
