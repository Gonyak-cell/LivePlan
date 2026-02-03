# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Glance widget classes should not be obfuscated
-keep class com.liveplan.widget.ui.** { *; }
-keep class com.liveplan.widget.worker.** { *; }
