# Nongchik Library V70

V70 keeps the V69 multi-file upload UI and fixes a Google Drive batch-upload edge case: a successful Drive upload must not be reported as failed only because the optional public-permission request is temporarily rate-limited or rejected. The app retries that permission request and still returns the uploaded Drive file metadata so it can be saved in Supabase.

## Run
flutter clean
flutter pub get
flutter run -d chrome --web-port 50332 --dart-define-from-file=config.json

## Deploy Edge Function
npx supabase functions deploy drive-upload --no-verify-jwt

No Google secrets or database changes are required.
