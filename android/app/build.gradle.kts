plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") // ✅ Firebase plugin
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mad"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.mad"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ✅ ADD THIS dependencies block for Firebase:
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.2.2")) // ✅ Firebase BOM
    implementation("com.google.firebase:firebase-auth") // ✅ Firebase Authentication
    implementation("com.google.firebase:firebase-firestore") // ✅ Firebase Firestore
    implementation("com.google.firebase:firebase-messaging") // ✅ Firebase Messaging (for notifications)
}
