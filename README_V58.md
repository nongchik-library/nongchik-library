# Nongchik Library V58 — Drive Fix + Web Config Fix

V58 is based on V57. It keeps the Google Drive diagnostic `drive-upload` function and fixes Flutter Web configuration so a Thai placeholder cannot be sent as an HTTP header/API key.

## Important
Run the web app with the current Supabase Publishable Key from Supabase Dashboard. Do not paste secrets into chat.

```powershell
flutter run -d chrome --web-port 50332 --dart-define=SUPABASE_URL=https://ddldegnsupfeqfzbjjcr.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_CURRENT_PUBLISHABLE_KEY
```

If the key is omitted or contains non-ASCII characters, the app shows a configuration error instead of sending an invalid HTTP header.

## Drive function
Deploy only the updated function when needed:

```powershell
npx supabase functions deploy drive-upload --no-verify-jwt
```

Google Drive secrets remain unchanged.
