import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releasePropertiesFile = providers.environmentVariable("LOCKOUT_KEYSTORE_PROPERTIES")
    .orNull?.let { file(it) } ?: rootProject.file("key.properties")
val releaseProperties = Properties().apply {
    if (releasePropertiesFile.isFile) releasePropertiesFile.inputStream().use { load(it) }
}
val hasReleaseSigning = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !releaseProperties.getProperty(it).isNullOrBlank() }
// The existing GitHub workflow builds disposable test artifacts without private keys.
// Official local release builds always require the permanent signing configuration.
val isGithubTestArtifact = providers.environmentVariable("GITHUB_ACTIONS").orNull == "true" && !hasReleaseSigning

android {
    namespace = "com.jinatra.lockout"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications uses java.time on the scheduling path,
        // which needs desugaring to run on the minSdk this app supports.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.jinatra.lockout"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeType = "PKCS12"
                storeFile = file(releaseProperties.getProperty("storeFile"))
                storePassword = releaseProperties.getProperty("storePassword")
                keyAlias = releaseProperties.getProperty("keyAlias")
                keyPassword = releaseProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = when {
                hasReleaseSigning -> signingConfigs.getByName("release")
                isGithubTestArtifact -> signingConfigs.getByName("debug")
                else -> null
            }
        }
    }
}

val verifyReleaseSigning by tasks.registering {
    doLast {
        check(hasReleaseSigning || isGithubTestArtifact) {
            "Release signing is missing. Configure android/key.properties or LOCKOUT_KEYSTORE_PROPERTIES. See docs/releasing.md."
        }
        if (isGithubTestArtifact) {
            logger.warn("GitHub Actions test artifact only: debug-signed APK. Never publish it as an official release update.")
        } else {
            check(file(releaseProperties.getProperty("storeFile")).isFile) {
                "The configured release keystore does not exist. Restore the permanent signing key before building."
            }
        }
    }
}
tasks.matching { it.name == "validateSigningRelease" || it.name == "packageRelease" }
    .configureEach { dependsOn(verifyReleaseSigning) }

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
