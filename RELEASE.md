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

The build now fails if release signing is missing. For a local artifact that
must not be uploaded to a store, explicitly opt into debug signing:

```powershell
$env:CGE_ALLOW_DEBUG_RELEASE_SIGNING="true"
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
- Configure `SUPABASE_URL` and `SUPABASE_ANON_KEY` with `--dart-define`
- Configure `CGE_API_BASE_URL` with the deployed CGE website origin
- Configure Paystack only on the website/server. The mobile app must never contain
  a Paystack secret or create payment references directly.
- Verify Firebase is configured for production

Example:
```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=CGE_API_BASE_URL=https://cgelounge.com
```

## Pre-release Checklist
- [ ] All tests pass (`flutter test`)
- [ ] No analysis errors (`flutter analyze`)
- [ ] Release APK tested on physical device
- [ ] Production Paystack keys and webhook configured on the CGE server
- [ ] `CGE_API_BASE_URL` points to the production CGE server
- [ ] App store metadata prepared (see `store_metadata/`)
- [ ] Privacy policy URL ready
- [ ] App icons generated (`flutter pub run flutter_launcher_icons`)
- [ ] Splash screen generated (`flutter pub run flutter_native_splash:create`)
