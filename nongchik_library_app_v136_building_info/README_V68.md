# Nongchik Library V69

## Multi-file upload
- Select multiple JPG/JPEG/PNG/WEBP/DOC/DOCX/PDF files in one picker.
- Set one common folder, category and description.
- Click one button to upload all selected files sequentially to Google Drive.
- Each file is saved as a separate `library_files` record and enters pending review.
- No fixed number-of-files limit is imposed by the app. Browser memory and Google Drive/network limits still apply.
- Per-file Google Drive upload limit remains 25 MB in the existing Edge Function.

Run:
`flutter clean`
`flutter pub get`
`flutter run -d chrome --web-port 50332 --dart-define-from-file=config.json`
