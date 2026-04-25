# Release Build Instructions

## Android

### 1. Generate a release keystore (one-time)
```bash
keytool -genkey -v -keystore keystore/cge-lounge-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cge-lounge
```

### 2. Create key.properties
Copy `android/key.properties.example` to `android/key.properties` and fill in your passwords:
```bash
cp android/key.properties.example android/key.properties
```

### 3. Build release APK
```bash
flutter build apk --release
```

### 4. Build release App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

The output files will be at:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## iOS

### 1. Open in Xcode
```bash
open ios/Runner.xcworkspace
```

### 2. Configure signing
- Select the Runner target
- Go to Signing & Capabilities
- Select your Apple Developer Team
- Ensure the Bundle ID is `com.cgelounge.cgeLoungeApp`

### 3. Build for release
```bash
flutter build ipa --release
```

## Environment Setup
- Switch Paystack key from `pk_test_...` to `pk_live_...` in `lib/core/services/payment_service.dart`
- Ensure Supabase URL and anon key point to production
- Verify Firebase is configured for production

## Pre-release Checklist
- [ ] All tests pass (`flutter test`)
- [ ] No analysis errors (`flutter analyze`)
- [ ] Release APK tested on physical device
- [ ] Paystack live key configured
- [ ] App store metadata prepared (see `store_metadata/`)
- [ ] Privacy policy URL ready
- [ ] App icons generated (`flutter pub run flutter_launcher_icons`)
- [ ] Splash screen generated (`flutter pub run flutter_native_splash:create`)
