# Flutter 核心类保护
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Store Deferred Components（可选功能，R8警告时忽略）
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Flutter embedding 保护
-keep class androidx.lifecycle.** { *; }
-keep class androidx.arch.core.** { *; }

# flutter_local_notifications 保护（使用反射）
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# timezone 库保护
-keep class org.threeten.bp.** { *; }

# shared_preferences 保护
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Gson 保护（如果使用）
-keepattributes Signature
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private static final boolean serializable;
    private final java.io.ObjectStreamField[] serialPersistentFields;
    private transient java.util.Comparator<?> comparator;
}

# 保留所有枚举类
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保留 Kotlin 元数据
-keep class kotlin.Metadata { *; }

# 移除日志（可选，生产环境）
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
