# Nongchik Library v61

## Fix: Google Drive upload 401
The previous v57/v60 diagnostic called Google OAuth userinfo (`oauth2/v3/userinfo`) using a token scoped only for Google Drive. That diagnostic could return `401 Invalid Credentials` and abort an otherwise valid Drive upload. v61 removes that nonessential userinfo check.

## Deploy only the drive-upload function
From the project folder:

```bash
npx supabase functions deploy drive-upload --no-verify-jwt
```

No Flutter rebuild is required for this fix. Keep the four existing Supabase Edge Function secrets unchanged.

Then retry uploading a small JPG to the `โครงการ STEM` folder.
