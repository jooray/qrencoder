import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The shared publisher key. Kept outside the repository. A release build
// without it fails; pass -PallowDebugSigning=true to build a debug-signed
// release for local testing only.
val keystoreProperties = Properties().apply {
    val path = System.getenv("APP_SIGNING_PROPERTIES")
        ?: "${System.getProperty("user.home")}/.apk-signing-keystore/signing.properties"
    File(path).takeIf { it.exists() }?.inputStream()?.use { load(it) }
}

android {
    namespace = "io.bednar.qrencoder"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.bednar.qrencoder"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreProperties.getProperty("storeFile") != null) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            val release = signingConfigs.findByName("release")
            signingConfig = when {
                release != null -> release
                project.hasProperty("allowDebugSigning") ->
                    signingConfigs.getByName("debug")
                else -> null
            }
        }
    }
}

dependencies {
    // FileProvider, so COPY IMAGE can put a real image on the clipboard.
    implementation("androidx.core:core-ktx:1.13.1")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Fail release builds loudly instead of shipping a debug-signed APK.
gradle.taskGraph.whenReady {
    val releaseTask = allTasks.any {
        it.project == project && Regex("^(assemble|bundle|package)Release\$").matches(it.name)
    }
    if (releaseTask && keystoreProperties.getProperty("storeFile") == null &&
        !project.hasProperty("allowDebugSigning")
    ) {
        throw GradleException(
            "No release signing config: set storeFile in " +
                "~/.apk-signing-keystore/signing.properties (or APP_SIGNING_PROPERTIES), " +
                "or pass -PallowDebugSigning=true for a local test build."
        )
    }
}
