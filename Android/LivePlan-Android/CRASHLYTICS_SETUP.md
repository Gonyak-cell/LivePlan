# Firebase Crashlytics Setup Guide

> **Note**: Per `performance.md`, Crashlytics is **optional** and **disabled by default** in Phase 1.
> Only enable if crash reporting is necessary for production quality assurance.

## Prerequisites

1. A Firebase project (https://console.firebase.google.com)
2. Firebase CLI (optional, for configuration)

## Setup Steps

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or use an existing one
3. Add an Android app with package name `com.liveplan`
4. Download `google-services.json`
5. Place it in `app/google-services.json`

### 2. Enable Gradle Plugins

**In `build.gradle.kts` (root):**
```kotlin
plugins {
    // ... existing plugins ...
    // Uncomment these:
    alias(libs.plugins.google.services) apply false
    alias(libs.plugins.firebase.crashlytics) apply false
}
```

**In `app/build.gradle.kts`:**
```kotlin
plugins {
    // ... existing plugins ...
    // Uncomment these:
    alias(libs.plugins.google.services)
    alias(libs.plugins.firebase.crashlytics)
}

dependencies {
    // ... existing dependencies ...
    // Uncomment these:
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.crashlytics)
    implementation(libs.firebase.analytics)
}
```

### 3. Initialize Crashlytics (Optional Custom Config)

If you need custom initialization, add to `LivePlanApplication.kt`:

```kotlin
import com.google.firebase.crashlytics.FirebaseCrashlytics

class LivePlanApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // ... existing code ...

        // Configure Crashlytics (optional)
        FirebaseCrashlytics.getInstance().apply {
            // Disable collection in debug builds
            setCrashlyticsCollectionEnabled(!BuildConfig.DEBUG)

            // Don't log user identifiers (privacy)
            setUserId("")
        }
    }
}
```

### 4. Privacy Considerations (per performance.md)

- **Minimal data collection**: Only crash reports, no user tracking
- **No PII in logs**: Never log task titles or project names
- **Debug builds**: Crashlytics disabled in debug
- **Release builds**: Only crash stack traces collected

### 5. Verify Setup

1. Build and run the app
2. Force a test crash:
   ```kotlin
   throw RuntimeException("Test Crashlytics")
   ```
3. Check Firebase Console > Crashlytics

## Troubleshooting

- If build fails, ensure `google-services.json` is in `app/` directory
- If crashes don't appear, wait 5-10 minutes and refresh console
- Check that Firebase project has Crashlytics enabled

## Removal Plan (per performance.md requirements)

If Crashlytics needs to be removed:

1. Comment out all Firebase plugins and dependencies
2. Remove `google-services.json`
3. Remove any Crashlytics initialization code
4. Clean and rebuild project

The app should work without any Firebase dependencies.
