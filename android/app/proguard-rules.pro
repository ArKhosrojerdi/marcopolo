# Adivery SDK and its bundled ad-network adapters rely on reflection, so keep
# their classes from being stripped/renamed by R8.
-keep class com.adivery.** { *; }
-dontwarn com.adivery.**

# Optional mediation adapters that Adivery references but may not be bundled
# (e.g. MBridge). They are loaded conditionally — suppress missing-class errors.
-keep class com.mbridge.** { *; }
-dontwarn com.mbridge.**

# Google Mobile Ads types referenced by Adivery's native-ad media views.
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**
