plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningValues = mapOf(
    "storeFile" to System.getenv("ANDROID_KEYSTORE_PATH"),
    "storePassword" to System.getenv("ANDROID_KEYSTORE_PASSWORD"),
    "keyAlias" to System.getenv("ANDROID_KEY_ALIAS"),
    "keyPassword" to System.getenv("ANDROID_KEY_PASSWORD"),
)
val hasReleaseSigning = releaseSigningValues.values.all { !it.isNullOrBlank() }
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val allowUnsignedRelease = System.getenv("ALLOW_UNSIGNED_ANDROID_RELEASE") == "true"

if (releaseTaskRequested && !hasReleaseSigning && !allowUnsignedRelease) {
    throw GradleException(
        "Release signing is not configured. Set ANDROID_KEYSTORE_PATH, " +
            "ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD. " +
            "Use ALLOW_UNSIGNED_ANDROID_RELEASE=true only for deliberate local diagnostics.",
    )
}

android {
    namespace = "dev.cinnamonandclay.admin"
    // flutter_secure_storage 11.x requires Android API 37.0 at compile time.
    // API 37 is published as the minor-versioned platform package android-37.0,
    // so model that identity explicitly instead of asking AGP for android-37.
    // Keep compileSdk independent from targetSdk so adopting newer compile-time
    // APIs does not silently opt the app into newer runtime behavior.
    compileSdk {
        version = release(37) {
            minorApiLevel = 0
        }
    }
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "dev.cinnamonandclay.admin"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders.putAll(
            mapOf(
                "appAuthRedirectScheme" to "dev.cinnamonandclay.admin",
            ),
        )
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseSigningValues.getValue("storeFile")!!)
                storePassword = releaseSigningValues.getValue("storePassword")
                keyAlias = releaseSigningValues.getValue("keyAlias")
                keyPassword = releaseSigningValues.getValue("keyPassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
