// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    // ❌ Do NOT put "com.google.gms.google-services" here with a version.
    // We declare its version at the project root and apply it conditionally below.
}

android {
    namespace = "com.example.frontendemart"

    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Provided by your script: -PAPP_ID, -PAPP_NAME
    val APP_ID: String   = (project.findProperty("APP_ID") as String?) ?: "com.example.frontendemart"
    val APP_NAME: String = (project.findProperty("APP_NAME") as String?) ?: "eMart"

    defaultConfig {
        applicationId = APP_ID
        minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // App name
        resValue("string", "app_name", APP_NAME)
    }

    signingConfigs {
        create("release") {
            val ksPath  = System.getenv("KEYSTORE_PATH")     ?: (project.findProperty("KEYSTORE_PATH") as String? ?: "")
            val ksPass  = System.getenv("KEYSTORE_PASSWORD") ?: (project.findProperty("KEYSTORE_PASSWORD") as String? ?: "")
            val keyAl   = System.getenv("KEY_ALIAS")         ?: (project.findProperty("KEY_ALIAS") as String? ?: "")
            val keyPass = System.getenv("KEY_PASSWORD")      ?: (project.findProperty("KEY_PASSWORD") as String? ?: "")

            storeFile = if (ksPath.isNotEmpty()) file(ksPath) else null
            storePassword = ksPass
            keyAlias = keyAl
            keyPassword = keyPass

            enableV1Signing = true
            enableV2Signing = true
        }
    }

    buildTypes {
        debug {
            // Keep debug app independent (e.g., com.capu.emart.dev)
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "$APP_NAME Dev")
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM (keeps versions aligned)
    implementation(platform("com.google.firebase:firebase-bom:33.16.0"))

    // Firebase SDKs you use (add more as needed)
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
}

/**
 * Apply Google Services ONLY if a google-services.json is present.
 * Keep this OUTSIDE android{} / buildTypes{}.
 */
if (
    file("google-services.json").exists() ||
    file("src/debug/google-services.json").exists() ||
    file("src/release/google-services.json").exists()
) {
    apply(plugin = "com.google.gms.google-services")
}
 