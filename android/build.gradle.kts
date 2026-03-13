plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.example.sanjeevni"
    compileSdk flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId "com.example.sanjeevni"
        minSdk flutter.minSdkVersion
        targetSdk flutter.targetSdkVersion
        versionCode flutter.versionCode
        versionName flutter.versionName
    }

    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile(
                    "proguard-android-optimize.txt"
            ), "proguard-rules.pro"
        }
    }

    packagingOptions {
        jniLibs {
            keepDebugSymbols += "**/*.so"
        }
    }
}

flutter {
    source "../.."
}
