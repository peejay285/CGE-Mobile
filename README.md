# CGE Lounge Mobile

Flutter client for the CGE Lounge platform. It shares the live Supabase backend
and server-owned payment and booking workflows with the CGE website.

## Local development

Run against the local website API from an Android emulator:

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=CGE_API_BASE_URL=http://10.0.2.2:3000
```

Use `http://127.0.0.1:3000` for Flutter web or an iOS simulator. Use the
computer's LAN address when testing on a physical device.

## Architecture notes

- Authentication and realtime data use Supabase.
- Secure booking and Paystack initialization use authenticated CGE API routes.
- Payment status is confirmed by the server webhook, not trusted from the
  client checkout result.
- `supabase_migration.sql` and `supabase_migration_safe.sql` are archived legacy
  prototypes. Do not apply them to the shared production database.

## Verification

```bash
flutter analyze
flutter test
flutter build apk --release
```

See `RELEASE.md` for signing and store-build instructions.
