# ============================================================================
# LivePlan ProGuard/R8 Rules
# ============================================================================
# Add project specific ProGuard rules here.
# For more details, see: http://developer.android.com/guide/developing/tools/proguard.html

# ============================================================================
# General Android Rules
# ============================================================================

# Keep line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable

# Hide original source file name
-renamesourcefileattribute SourceFile

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# ============================================================================
# Kotlin
# ============================================================================

# Keep Kotlin Metadata
-keepattributes RuntimeVisibleAnnotations,AnnotationDefault

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# Kotlin Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep `@Serializable` classes
-keep,includedescriptorclasses class com.liveplan.**$$serializer { *; }
-keepclassmembers class com.liveplan.** {
    *** Companion;
}
-keepclasseswithmembers class com.liveplan.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# ============================================================================
# Hilt / Dagger
# ============================================================================

-dontwarn dagger.hilt.internal.aggregatedroot.codegen.**
-keep class dagger.hilt.internal.aggregatedroot.codegen.** { *; }
-keep class * extends dagger.hilt.android.internal.managers.ComponentSupplier { *; }
-keep class * extends dagger.hilt.android.internal.managers.ViewComponentManager$FragmentContextWrapper { *; }

# Keep Hilt generated classes
-keep class **_HiltModules { *; }
-keep class **_HiltModules$* { *; }
-keep class **_Factory { *; }
-keep class **_MembersInjector { *; }

# ============================================================================
# Jetpack Compose
# ============================================================================

# Keep Compose compiler metadata
-keep class androidx.compose.** { *; }
-dontwarn androidx.compose.**

# Keep composable functions for debugging
-keepclassmembers class * {
    @androidx.compose.runtime.Composable <methods>;
}

# ============================================================================
# Glance (Widget)
# ============================================================================

-keep class androidx.glance.** { *; }
-keep class * extends androidx.glance.appwidget.GlanceAppWidget { *; }
-keep class * extends androidx.glance.appwidget.GlanceAppWidgetReceiver { *; }

# ============================================================================
# LivePlan Domain Models
# ============================================================================

# Keep all domain entities (used for serialization)
-keep class com.liveplan.core.domain.model.** { *; }

# Keep all data layer DTOs
-keep class com.liveplan.data.local.** { *; }
-keep class com.liveplan.data.dto.** { *; }

# Keep App Shortcuts/Intents
-keep class com.liveplan.shortcuts.** { *; }

# ============================================================================
# DataStore
# ============================================================================

-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite {
    <fields>;
}
-keep class * extends androidx.datastore.preferences.protobuf.GeneratedMessageLite { *; }

# ============================================================================
# Enum classes
# ============================================================================

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ============================================================================
# Debug / Optional
# ============================================================================

# Uncomment for debugging ProGuard issues:
# -printconfiguration proguard-merged-config.txt
# -printusage proguard-usage.txt
# -printseeds proguard-seeds.txt
