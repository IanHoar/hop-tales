package com.hoptales.android.world

import androidx.compose.ui.graphics.Color
import com.hoptales.content.Mood
import com.hoptales.content.Sky
import com.hoptales.content.Weather
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MeadowSkyTest {
    @Test
    fun seededRandomMatchesSwiftFloatingPointRandom() {
        val random = SeededRandom(7)
        val values = List(5) { "%.6f".format(random.nextDouble(-40.0, 390.0)) }
        assertEquals(listOf("-32.781033", "347.327093", "210.660026", "154.550015", "67.255555"), values)
    }

    @Test
    fun starFieldMatchesSwiftOnAPhone() {
        assertEquals(
            "1:105.081:104.124:27.672,2:181.610:83.919:24.625,3:128.986:206.468:20.466,1:207.887:208.744:25.549," +
                "2:27.431:307.365:19.020,3:96.640:261.120:21.001,1:249.771:310.275:20.986,2:368.308:254.491:23.863",
            field(SkyLayout(390f, 844f, 1f, 0f)),
        )
    }

    @Test
    fun starFieldMatchesSwiftAtDeviceScale() {
        assertEquals(
            "1:347.070:351.098:96.853,2:598.152:283.998:86.189,3:421.838:697.721:71.632,1:91.366:1039.227:66.572," +
                "2:319.804:884.806:73.503,3:822.756:1048.850:73.450,1:1206.200:862.898:83.520",
            field(SkyLayout(1280f, 2856f, 3.5f, 0f)),
        )
    }

    private fun field(layout: SkyLayout) = MeadowStars.field(layout).joinToString(",") {
        "${it.asset.last()}:${"%.3f".format(it.x)}:${"%.3f".format(it.y)}:${"%.3f".format(it.width)}"
    }

    @Test
    fun dayClearLeavesTheLandUntinted() {
        val look = SkyLook.of(Mood())
        MeadowLayer.entries.forEach { assertEquals(Color.White, look.tint(it)) }
        assertEquals(1f, look.sun)
        assertEquals(0f, look.stars)
        assertEquals(0.55f, look.fairClouds)
        assertEquals(0f, look.stormBacking)
    }

    @Test
    fun stormDimsTheGradeAndHidesTheSun() {
        val look = SkyLook.of(Mood(Sky.NIGHT, Weather.STORM))
        assertEquals(Color(0xFF6876A0).red * 0.74f, look.tint(MeadowLayer.NEAR).red, 1 / 255f)
        assertEquals(0f, look.sun)
        assertEquals(1f, look.stars)
        assertEquals(0.35f, look.stormClouds, 1e-6f)
        assertEquals(1f, look.stormBacking)
        assertEquals(0.34f, look.overlay)
    }

    @Test
    fun crossfadeBlendsEveryValueLinearly() {
        val day = SkyLook.of(Mood(Sky.DAY))
        val night = SkyLook.of(Mood(Sky.NIGHT))
        val half = day.blend(night, 0.5f)
        assertEquals(0.5f, half.stars, 1e-6f)
        assertEquals(0.5f, half.sun, 1e-6f)
        assertEquals((day.gradient[0].red + night.gradient[0].red) / 2, half.gradient[0].red, 1 / 255f)
        assertEquals(night, day.blend(night, 1f))
        assertEquals(day, day.blend(night, 0f))
    }

    @Test
    fun skyColourBendsAtTheMiddleStop() {
        val gradient = Sky.DAY.style.gradient
        assertEquals(gradient[0], gradientColor(gradient, 0f))
        assertEquals(gradient[1].green, gradientColor(gradient, GRADIENT_MIDDLE).green, 1 / 255f)
        assertEquals(gradient[2], gradientColor(gradient, 1f))
    }

    @Test
    fun cloudsDriftLeftAndComeBackFromTheRight() {
        val layout = SkyLayout(400f, 800f, 2f, 0f)
        val cloud = SkyCloud.drifting[0]
        assertEquals(0f, cloud.x(100f, layout, 0.0))
        assertEquals(-24f, cloud.x(100f, layout, 2.0), 1e-4f)
        assertEquals(449f, cloud.x(100f, layout, 51.0 / 12), 1e-3f)
        assertEquals(-49f, cloud.x(100f, layout, (50.0 + 499) / 12), 1e-3f)
        assertEquals(140f, cloud.y(layout))
    }

    @Test
    fun lightningFirstFlashesSixSecondsIntoTheStorm() {
        assertEquals(0f, Lightning.flash(5.9))
        assertEquals(Lightning.PEAK, Lightning.flash(6.05), 1e-4f)
        assertEquals(0f, Lightning.flash(6.41))
        assertTrue((0..2000).any { Lightning.flash(10.0 + it * 0.01) > 0f })
    }

    @Test
    fun rainOnlyFallsWhileItIsRaining() {
        val rain = Shower.rain()
        assertEquals(0, count(rain, 1.0))
        rain.fall(true, 1.0)
        assertTrue(count(rain, 2.0) > 100)
        rain.fall(false, 3.0)
        assertTrue(rain.isVisible(4.0))
        assertEquals(0, count(rain, 5.3))
        assertFalse(rain.isVisible(5.3))
    }

    @Test
    fun dropsStartAboveTheScreenAndFallDownAndLeft() {
        val rain = Shower.rain()
        rain.fall(true, 0.0)
        val drops = mutableListOf<Particle>()
        rain.forEach(1.0, 400f, 2f) { drops += it }
        assertTrue(drops.all { it.dx < 0 && it.dy > 0 })
        val fresh = drops.minBy { it.y }
        assertTrue(fresh.y < 0f)
    }

    @Test
    fun stillWeatherIsTheSameEveryTime() {
        assertEquals(StillWeather.rain(780f, 1688f, 2f), StillWeather.rain(780f, 1688f, 2f))
        assertEquals(390 * 844 / 2600, StillWeather.rain(780f, 1688f, 2f).size)
        assertEquals(390 * 844 / 5200, StillWeather.snow(780f, 1688f, 2f).size)
    }

    private fun count(shower: Shower, now: Double): Int {
        var count = 0
        shower.forEach(now, 400f, 1f) { count++ }
        return count
    }
}
