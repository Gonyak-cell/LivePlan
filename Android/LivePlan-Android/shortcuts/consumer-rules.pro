# Consumer rules for shortcuts module
# These rules are applied when this module is consumed by the app module

# Keep Hilt entry points
-keep class com.liveplan.shortcuts.di.ShortcutsEntryPoint { *; }

# Keep TileService for Quick Settings
-keep class com.liveplan.shortcuts.tiles.CompleteTaskTileService { *; }

# Keep Activities for App Shortcuts
-keep class com.liveplan.shortcuts.activity.QuickAddActivity { *; }
-keep class com.liveplan.shortcuts.activity.CompleteNextActivity { *; }

# Keep NotificationService
-keep class com.liveplan.shortcuts.notification.LivePlanNotificationService { *; }
