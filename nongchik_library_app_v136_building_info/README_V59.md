# Nongchik Library V59 — Drive Config Fix

V59 keeps the V57/V58 Google Drive diagnostic function and changes Flutter Web startup so the app has a valid publishable-key fallback. This avoids the configuration screen when the browser is launched without dart-define.

Recommended run:
```powershell
flutter clean
flutter pub get
flutter run -d chrome --web-port 50332
```

The Supabase publishable key is a public client key; no secret/service-role key is included.

Drive function deployment is unchanged:
```powershell
npx supabase functions deploy drive-upload --no-verify-jwt
```
