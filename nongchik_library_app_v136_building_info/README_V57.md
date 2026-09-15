# Nongchik Library V57 — Google Drive diagnostic fix

V57 keeps the V56 Google Drive upload flow but adds a safe diagnostic step that calls Google OAuth userinfo and reports the Google account email used by the Edge Function. It also prefixes folder-access errors with that account email.

## Deploy
From this project folder:

```powershell
npx supabase functions deploy drive-upload --no-verify-jwt
```

No Google OAuth recreation is required. Keep the existing Supabase Edge Function secrets unchanged:
- GOOGLE_DRIVE_CLIENT_ID
- GOOGLE_DRIVE_CLIENT_SECRET
- GOOGLE_DRIVE_REFRESH_TOKEN
- GOOGLE_DRIVE_ROOT_FOLDER_ID

## Test
1. Run the Flutter app.
2. Upload `S__31588355.jpg` to the `โครงการ STEM` folder.
3. If it fails, the app should show an error containing the Google account email used by the Function.
4. Compare that email with the Google account that owns/has access to the root Drive folder.

The diagnostic does not expose refresh tokens or client secrets.

V57 does not migrate existing Supabase Storage files.
