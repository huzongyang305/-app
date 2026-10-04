import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 发布签名：读取 android/key.properties（该文件与密钥库都不提交到版本库）。
// 文件不存在时（例如协作方未拿到密钥）回退到 debug 签名，保证仍能构建。
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    // namespace 决定 Kotlin 包结构与 AndroidManifest 里 .MainActivity 的解析结果
    namespace = "com.codelearn.study"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications 需要 Java 8+ API 脱糖支持
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // 发布用包名：正式上架前如需换成自有域名，改这里并同步移动 MainActivity.kt
        applicationId = "com.codelearn.study"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // versionCode / versionName 都来自 pubspec.yaml 的 version: x.y.z+n。
        // 每次发布必须让 n 严格递增（应用商店据此判断升级）。
        // 使用 --split-per-abi 时 Flutter 会自动叠加 ABI 偏移，无需手工处理。
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                // Play 与 Android 9+ 优先校验 v3 签名；v2 保留给更老的系统。
                enableV3Signing = true
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // 资源瘦身主要靠 --split-per-abi；R8 混淆需要额外 proguard 规则，
            // 涉及 flutter_local_notifications / timezone 反射调用，暂不开启。
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
