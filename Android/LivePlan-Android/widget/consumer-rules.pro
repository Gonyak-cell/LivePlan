# Consumer ProGuard rules for widget module
# These rules are applied to consumers (app module) when using this library

# Glance widget receivers must be kept
-keep class com.liveplan.widget.ui.*Receiver { *; }

# WorkManager workers must be kept
-keep class com.liveplan.widget.worker.** { *; }

# Hilt entry points must be kept
-keep interface com.liveplan.widget.ui.WidgetEntryPoint { *; }
