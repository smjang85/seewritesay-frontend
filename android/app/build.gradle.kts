import java.util.Properties
import java.io.FileInputStream


plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    // ✅ 최신 Play Core 구성요소
    implementation("com.google.android.play:app-update:2.1.0")
    implementation("com.google.android.play:app-update-ktx:2.1.0")
    implementation("com.google.android.play:review:2.0.2")
    implementation("com.google.android.play:review-ktx:2.0.2")

    // ✅ Jetpack 필수 유틸 (core-ktx는 androidx 네임스페이스)
    implementation("androidx.core:core-ktx:1.16.0")

    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    implementation("com.google.firebase:firebase-analytics")
}

android {
    namespace = "com.seewritesay.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = project.file("key.properties")
            val keystoreProperties = Properties().apply {
                if (keystorePropertiesFile.exists()) {
                    load(FileInputStream(keystorePropertiesFile))
                } else {
                    throw GradleException("key.properties 파일을 찾을 수 없습니다.")
                }
            }

            val keystorePath = keystoreProperties["storeFile"]?.toString()
                ?: throw GradleException("storeFile 설정이 누락되었습니다.")

            storeFile = file(keystorePath) // 여기서도 경로 앞에 android/app 안 붙입니다.
            storePassword = keystoreProperties["storePassword"]?.toString()
                ?: throw GradleException("storePassword 누락됨")

            keyAlias = keystoreProperties["keyAlias"]?.toString()
                ?: throw GradleException("keyAlias 누락됨")

            keyPassword = keystoreProperties["keyPassword"]?.toString()
                ?: throw GradleException("keyPassword 누락됨")
        }
    }



    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }

    defaultConfig {
        applicationId = "com.seewritesay.app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}

flutter {
    source = "../.."
}

apply(plugin = "com.google.gms.google-services")
