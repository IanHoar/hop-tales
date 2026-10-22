plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.roborazzi)
    alias(libs.plugins.play.publisher)
}

val shared = rootDir.resolve("../ios/HopTalesPackage/Sources")
val notYetOnAndroid = listOf("postcard-*")

data class ReleaseVersion(val code: Int, val name: String)

fun releaseVersion(tag: String): ReleaseVersion {
    val match = Regex("""^(?:android/)?v(\d+)\.(\d+)\.(\d+)-(\d+)$""").matchEntire(tag)
        ?: throw GradleException(
            "releaseTag \"$tag\" is not a release version. Android release tags are " +
                "android/v<major>.<minor>.<patch>-<build>, e.g. android/v1.0.0-1.",
        )
    val (major, minor, patch, build) = match.destructured.toList().map { it.toLong() }
    listOf("minor" to minor, "patch" to patch, "build" to build).forEach { (part, value) ->
        if (value >= 100) {
            throw GradleException(
                "releaseTag \"$tag\": $part is $value, but versionCode leaves it two digits (0-99). See docs/google-play.md.",
            )
        }
    }
    val code = major * 1_000_000 + minor * 10_000 + patch * 100 + build
    if (code > 2_100_000_000) {
        throw GradleException("releaseTag \"$tag\": versionCode $code is above Play's limit of 2100000000.")
    }
    return ReleaseVersion(code.toInt(), "$major.$minor.$patch")
}

val release = providers.gradleProperty("releaseTag").orNull?.let(::releaseVersion)

android {
    namespace = "com.hoptales.android"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.hoptales.android"
        minSdk = 31
        targetSdk = 37
        versionCode = release?.code ?: 1
        versionName = release?.name ?: "0.1.0"
    }

    signingConfigs {
        create("release") {
            val store = providers.gradleProperty("HOPTALES_UPLOAD_STORE").orNull
            if (store != null) {
                storeFile = file(store)
                storePassword = providers.gradleProperty("HOPTALES_UPLOAD_PASSWORD").get()
                keyAlias = providers.gradleProperty("HOPTALES_UPLOAD_ALIAS").get()
                keyPassword = providers.gradleProperty("HOPTALES_UPLOAD_PASSWORD").get()
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    sourceSets {
        getByName("main") {
            assets.srcDir(shared.resolve("Content/Resources"))
            assets.srcDir(shared.resolve("World/Resources"))
            assets.srcDir(shared.resolve("DesignSystem/Resources"))
        }
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.systemProperty("robolectric.pixelCopyRenderMode", "hardware")
                it.jvmArgs("--add-opens=java.base/jdk.internal.access=ALL-UNNAMED")
                it.systemProperty("hoptales.database", shared.resolve("Content/Database.swift").absolutePath)
            }
        }
    }

    androidResources {
        noCompress += listOf("webp", "png")
        ignoreAssetsPatterns += notYetOnAndroid
    }
}

dependencies {
    implementation(project(":core:reading"))
    implementation(project(":core:onboarding"))
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.core.splashscreen)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.window)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.foundation)
    implementation(libs.compose.material3)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.kotlinx.coroutines.android)
    debugImplementation(libs.compose.ui.tooling)
    testImplementation(libs.junit)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.robolectric)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
    testImplementation(libs.androidx.window.testing)
    debugImplementation(libs.compose.ui.test.manifest)
}

play {
    track.set("internal")
    defaultToAppBundles.set(true)
    releaseStatus.set(com.github.triplet.gradle.androidpublisher.ReleaseStatus.COMPLETED)
    providers.gradleProperty("HOPTALES_PLAY_CREDENTIALS").orNull?.let {
        serviceAccountCredentials.set(file(it))
    }
}

roborazzi {
    outputDir.set(file("src/test/screenshots"))
}
