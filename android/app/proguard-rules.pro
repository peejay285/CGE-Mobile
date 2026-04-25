# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / GoTrue
-keep class io.supabase.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# Paystack
-keep class co.paystack.** { *; }
-dontwarn co.paystack.**

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
