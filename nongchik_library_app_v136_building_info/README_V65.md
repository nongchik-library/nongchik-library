# Nongchik Library V65 — Google Drive Upload Fix

รุ่นนี้แก้จุดสำคัญของ Google Drive Upload และเพิ่มการตรวจสอบว่า Edge Function ใช้บัญชี Google ใด

## สิ่งที่แก้
- ตรวจสอบบัญชี Google จาก Access Token ด้วย Google userinfo
- ตรวจสอบ Google Drive Root Folder ID ก่อนค้นหา/สร้างโฟลเดอร์
- หาก Root Folder เข้าไม่ได้ จะรายงานบัญชี Google และ Root ID ใน error เพื่อหาสาเหตุได้ทันที
- ยังคงใช้ OAuth Client ID + Client Secret + Refresh Token ใน Supabase Secrets
- ไม่ต้องใช้ Service Account
- Flutter ไม่เก็บ Google secret

## Supabase Secrets ที่ต้องมี
- GOOGLE_DRIVE_CLIENT_ID
- GOOGLE_DRIVE_CLIENT_SECRET
- GOOGLE_DRIVE_REFRESH_TOKEN
- GOOGLE_DRIVE_ROOT_FOLDER_ID

## Deploy
เปิด Terminal ในโฟลเดอร์โปรเจกต์ แล้วรัน:

```powershell
npx supabase functions deploy drive-upload --no-verify-jwt
```

## สำคัญ
ถ้าทดสอบแล้วขึ้นว่า `เข้าถึงโฟลเดอร์หลักไม่ได้` และมีอีเมลบัญชี Google แสดงออกมา ให้ใช้ OAuth Refresh Token ที่สร้างจาก OAuth Client เดียวกันกับ `GOOGLE_DRIVE_CLIENT_ID` และ `GOOGLE_DRIVE_CLIENT_SECRET` และเป็นบัญชีที่มีสิทธิ์เขียนในโฟลเดอร์หลัก

ห้ามส่ง Client Secret หรือ Refresh Token ให้ผู้อื่น
