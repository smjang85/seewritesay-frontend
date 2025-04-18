import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.seewritesay.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
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
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
