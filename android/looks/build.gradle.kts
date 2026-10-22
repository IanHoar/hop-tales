plugins {
    alias(libs.plugins.android.asset.pack)
}

val world = rootDir.resolve("../ios/HopTalesPackage/Sources/World/Resources")
val baseLooks = providers.gradleProperty("hoptales.baseLooks").get().split(",")
val sheets = layout.buildDirectory.dir("pack/looks/src/main/assets")

assetPack {
    packName.set("looks")
    dynamicDelivery {
        deliveryType.set("fast-follow")
    }
}

val syncLooks = tasks.register<Sync>("syncLooks") {
    from(world) {
        include("look-*")
        exclude(baseLooks.flatMap { listOf("look-$it.*", "look-$it-idle.*", "look-$it-hop.*") })
    }
    into(sheets)
}

configurations.named("packElements") {
    artifacts.clear()
    outgoing.artifact(sheets) { builtBy(syncLooks) }
}
