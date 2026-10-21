package com.hoptales.android

import android.media.AudioManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.home.BookScreen
import com.hoptales.android.home.FriendsScreen
import com.hoptales.android.home.HomeScreen
import com.hoptales.android.home.JourneyMapScreen
import com.hoptales.android.home.WardrobeScreen
import com.hoptales.android.onboarding.OnboardingScreen
import com.hoptales.android.reading.ReadingScreen
import com.hoptales.android.settings.SettingsScreen
import com.hoptales.content.Friend
import com.hoptales.content.Story
import com.hoptales.content.tapping
import com.hoptales.content.undressing
import com.hoptales.onboarding.OnboardingState
import java.util.Locale

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        volumeControlStream = AudioManager.STREAM_MUSIC
        val app = application as HopTalesApplication
        val store = app.progressStore
        finishAnsweredDraft(app)
        setContent {
            HopTalesTheme {
                var storyID by rememberSaveable { mutableStateOf<String?>(null) }
                var sheet by rememberSaveable { mutableStateOf<String?>(null) }
                var isShowingSettings by rememberSaveable { mutableStateOf(false) }
                var visit by rememberSaveable { mutableIntStateOf(0) }
                val progress by store.progress.collectAsStateWithLifecycle()
                val profile by app.profileStore.profile.collectAsStateWithLifecycle()
                val route = when {
                    profile == null -> Route.Onboarding
                    isShowingSettings -> Route.Settings
                    else -> storyID?.let(app.library::get)?.let(Route::Reading) ?: sheet?.let(Route::Sheet) ?: Route.Home
                }
                BackHandler(enabled = route is Route.Sheet) { sheet = null }
                AnimatedContent(
                    targetState = route,
                    transitionSpec = { fadeIn() togetherWith fadeOut() },
                    label = "route",
                ) { target ->
                    val friend = progress.journey.activeFriend
                    when (target) {
                        Route.Onboarding -> OnboardingScreen(key = "onboarding-$visit")

                        Route.Settings -> SettingsScreen(key = "settings-$visit", onDone = { isShowingSettings = false })

                        is Route.Reading -> ReadingScreen(
                            story = target.story,
                            onDone = { storyID = null },
                            onStory = { storyID = it.id },
                            onTryItOn = {
                                storyID = null
                                sheet = Sheet.wardrobe(it)
                            },
                        )

                        is Route.Sheet -> when {
                            target.sheet == Sheet.JOURNEY -> JourneyMapScreen(
                                library = app.library,
                                journey = progress.journey,
                                onFriend = { tapped -> store.update { it.copy(journey = it.journey.readingWith(tapped)) } },
                                onBigStory = {
                                    sheet = null
                                    storyID = it.id
                                },
                                onDone = { sheet = null },
                            )

                            target.sheet == Sheet.FRIENDS -> FriendsScreen(
                                progress = progress,
                                wardrobe = app.wardrobe,
                                onFriend = { tapped -> store.update { it.copy(journey = it.journey.readingWith(tapped)) } },
                                onJourney = { sheet = Sheet.JOURNEY },
                                onDone = { sheet = null },
                            )

                            target.sheet.startsWith(Sheet.WARDROBE) -> {
                                val dressing = Sheet.friend(target.sheet) ?: friend
                                WardrobeScreen(
                                    friend = dressing,
                                    progress = progress,
                                    wardrobe = app.wardrobe,
                                    onItem = { item -> store.update { it.tapping(item, dressing, app.wardrobe) } },
                                    onJustMe = { store.update { it.undressing(dressing) } },
                                    onDone = { sheet = null },
                                )
                            }

                            else -> BookScreen(
                                library = app.library,
                                progress = progress,
                                friend = Sheet.friend(target.sheet) ?: friend,
                                onFriend = { sheet = Sheet.book(it) },
                                onDone = { sheet = null },
                            )
                        }

                        Route.Home -> HomeScreen(
                            library = app.library,
                            progress = progress,
                            onStory = { storyID = it.id },
                            childName = profile?.childName,
                            onGrownUps = {
                                visit += 1
                                isShowingSettings = true
                            },
                            onJourney = { sheet = Sheet.JOURNEY },
                            onFriends = { sheet = Sheet.FRIENDS },
                            onWardrobe = { sheet = Sheet.wardrobe(friend) },
                            onBook = { sheet = Sheet.book(friend) },
                        )
                    }
                }
            }
        }
    }

    private fun finishAnsweredDraft(app: HopTalesApplication) {
        app.profileStore.load()?.let {
            app.progressStore.startJourney(it.startingFriend)
            return
        }
        val draft = app.profileStore.loadDraft()?.let(OnboardingState::resuming) ?: return
        if (!draft.isComplete) return
        val profile = draft.profile(Locale.getDefault().country)
        app.profileStore.save(profile)
        app.progressStore.startJourney(profile.startingFriend)
    }
}

private sealed interface Route {
    data object Onboarding : Route
    data object Home : Route
    data object Settings : Route
    data class Reading(val story: Story) : Route
    data class Sheet(val sheet: String) : Route
}

private object Sheet {
    const val JOURNEY = "journey"
    const val FRIENDS = "friends"
    const val WARDROBE = "wardrobe:"
    const val BOOK = "book:"

    fun wardrobe(friend: Friend) = WARDROBE + friend.key

    fun book(friend: Friend) = BOOK + friend.key

    fun friend(sheet: String): Friend? = Friend.entries.firstOrNull { sheet.endsWith(":${it.key}") }
}
