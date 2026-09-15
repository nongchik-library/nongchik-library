# Nongchik Library V60 — Drive Config Fix

V60 keeps the existing Nongchik Library features and Google Drive Edge Functions from V57/V59, but changes Flutter Web configuration so the Supabase publishable key is supplied through `config.json`.

## 1) Get the current key
Supabase Dashboard → Project Settings → API Keys → **Publishable key** → Copy.

Use the **Publishable key** only. Never use a `service_role`/secret key.

## 2) Edit config.json
Open `config.json` in the project root and replace only:

`PASTE_CURRENT_SUPABASE_PUBLISHABLE_KEY_HERE`

with the current Publishable key. Do not send the key in chat.

## 3) Run
Open VS Code Terminal in this folder:

```powershell
flutter clean
flutter pub get
flutter run -d chrome --web-port 50332 --dart-define-from-file=config.json
```

## 4) Expected result
The login page should open at `http://localhost:50332` and Supabase login should work.

## 5) Google Drive
The existing `drive-upload` diagnostic Edge Function from V57 remains available. No Google OAuth secret needs to be changed for this configuration fix.
