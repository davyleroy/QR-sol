plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

android {
    namespace "com.example.qr_solutions"
    compileSdk 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.qr_solutions"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        
        // Enable multidex for large app
        multiDexEnabled true
        
        // Specify test runner
        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
        
        // Vector drawables support
        vectorDrawables.useSupportLibrary = true
    }

    buildTypes {
        release {
            // Enable code shrinking, obfuscation, and optimization
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // Signing config (you'll need to set up your own keystore)
            // signingConfig signingConfigs.release
        }
        
        debug {
            // Enable debugging
            debuggable true
            applicationIdSuffix ".debug"
            versionNameSuffix "-debug"
        }
    }
    
    // Build features
    buildFeatures {
        viewBinding true
    }
    
    // Packaging options
    packagingOptions {
        pickFirst '**/libc++_shared.so'
        pickFirst '**/libjsc.so'
    }
    
    // Lint options
    lintOptions {
        disable 'InvalidPackage'
        checkReleaseBuilds false
    }
}

flutter {
    source '../..'
}

dependencies {
    // AndroidX libraries
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.activity:activity-ktx:1.8.2'
    implementation 'androidx.fragment:fragment-ktx:1.6.2'
    
    // Material Design
    implementation 'com.google.android.material:material:1.11.0'
    
    // Multidex support
    implementation 'androidx.multidex:multidex:2.0.1'
    
    // Permission handling
    implementation 'androidx.work:work-runtime-ktx:2.9.0'
    
    // Network and connectivity
    implementation 'androidx.lifecycle:lifecycle-runtime-ktx:2.7.0'
    
    // Testing dependencies
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
    androidTestImplementation 'androidx.test:runner:1.5.2'
    androidTestImplementation 'androidx.test:rules:1.5.0'
}