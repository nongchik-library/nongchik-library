# Nongchik Library v62 – Drive upload fix

แก้ Edge Function drive-upload ที่ยังอ้างถึงตัวแปร identity ซึ่งถูกลบออกไปแล้ว ทำให้เกิด `identity is not defined` หลังการอัปโหลด/สร้างไฟล์

Deploy:
```powershell
npx supabase functions deploy drive-upload --no-verify-jwt
```

หลัง deploy ให้ทดสอบอัปโหลดจากเว็บเดิมได้เลย ไม่ต้อง build Flutter ใหม่
