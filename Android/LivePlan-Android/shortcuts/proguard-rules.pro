# Shortcuts module proguard rules
# Add project specific ProGuard rules here.

# Keep Hilt entry points
-keep class com.liveplan.shortcuts.di.ShortcutsEntryPoint { *; }

# Keep TileService
-keep class com.liveplan.shortcuts.tiles.CompleteTaskTileService { *; }

# Keep Activities used by App Shortcuts
-keep class com.liveplan.shortcuts.activity.QuickAddActivity { *; }
-keep class com.liveplan.shortcuts.activity.CompleteNextActivity { *; }

# Keep NotificationService
-keep class com.liveplan.shortcuts.notification.LivePlanNotificationService { *; }
