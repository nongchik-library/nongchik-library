# Nongchik Library V55 — Google Drive Storage

V55 changes new file/photo/certificate uploads to Google Drive while keeping Supabase as the application database, authentication, permissions, GPS and approval workflow. Existing Supabase Storage files remain readable.

## Architecture
- Netlify: Flutter Web hosting
- Supabase: Auth + PostgreSQL + RLS + Edge Functions
- Google Drive: new images/PDF/Word/certificates

## Important
V55 is Drive-ready but requires a one-time Google OAuth setup before uploads can work. Do not put Google client secret, refresh token, or Supabase service-role key in Flutter.

## 1) Run SQL
Open Supabase SQL Editor and run `supabase_schema_v55_drive.sql`.

## 2) Google Cloud
Create/choose a Google Cloud project, enable Google Drive API, create an OAuth 2.0 Web/Desktop client and authorize the account that owns the Drive folder. The required Drive scope is `https://www.googleapis.com/auth/drive`. Obtain the refresh token using Google's OAuth flow.

Create a root folder in the Google Drive account, copy its folder ID.

## 3) Supabase secrets
Set these secrets in Supabase Edge Functions:
- `GOOGLE_DRIVE_CLIENT_ID`
- `GOOGLE_DRIVE_CLIENT_SECRET`
- `GOOGLE_DRIVE_REFRESH_TOKEN`
- `GOOGLE_DRIVE_ROOT_FOLDER_ID`

Example CLI:
```
npx supabase secrets set GOOGLE_DRIVE_CLIENT_ID="..." GOOGLE_DRIVE_CLIENT_SECRET="..." GOOGLE_DRIVE_REFRESH_TOKEN="..." GOOGLE_DRIVE_ROOT_FOLDER_ID="..."
```

## 4) Deploy Edge Function
```
npx supabase functions deploy drive-upload --no-verify-jwt
npx supabase functions deploy drive-delete --no-verify-jwt
```
The function verifies that an Authorization header exists and keeps Google credentials server-side.

## 5) Test locally
```
flutter clean
flutter pub get
flutter run -d chrome
```

## 6) Build web
```
flutter build web --release --dart-define=SUPABASE_URL=https://ddldegnsupfeqfzbjjcr.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

## Security note
V55 marks newly uploaded Drive files as `anyone with the link: viewer` so the public approved library can display files without exposing Google OAuth credentials. If your organization requires private Drive files, the next version should add a private download proxy and only expose files after approval.

## Existing files
Files already stored in Supabase Storage are not automatically migrated. They continue to work. A later migration tool can copy them to Drive if desired.
