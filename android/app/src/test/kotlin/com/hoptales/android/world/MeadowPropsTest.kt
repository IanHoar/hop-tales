package com.hoptales.android.world

import org.junit.Assert.assertEquals
import org.junit.Test

class MeadowPropsTest {
    @Test
    fun placementsMatchSwiftSegmentBySegment() {
        val placed = (-1..3).flatMap { segment ->
            MeadowProps.placements(segment).map { "$segment ${it.asset} ${"%.3f".format(it.x)} ${"%.4f".format(it.depth)}" }
        }
        assertEquals(
            listOf(
                "-1 prop-fence 435.170 0.4741",
                "0 prop-bush 746.656 0.1063",
                "1 prop-bush 333.770 0.8246",
                "1 prop-fence 727.381 0.3339",
            ),
            placed,
        )
    }

    @Test
    fun wideFramingAnchorsTheLandToTheBottomAsOnAPhone() {
        val layout = MeadowLayout.wide(390f, 844f, 1f)
        assertEquals(844f - 986f * 0.42f, layout.top(MeadowLayer.FAR), 0.01f)
        assertEquals(844f - 705f * 0.42f, layout.top(MeadowLayer.NEAR), 0.01f)
        assertEquals(3555f * 0.42f, layout.tileWidth(MeadowLayer.NEAR), 0.01f)
    }

    @Test
    fun wideFramingGrowsOnATablet() {
        val layout = MeadowLayout.wide(2388f, 1668f, 2f)
        val k = 834f / 390f * 0.62f
        assertEquals(0.42f * k * 2f, layout.scale(MeadowLayer.MID), 0.001f)
    }
}
