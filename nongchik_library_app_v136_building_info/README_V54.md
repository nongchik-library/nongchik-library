# Nongchik Library V54

## เพิ่มฟังก์ชันลบคุณครู
- หน้า “จัดการผู้ใช้งานและสิทธิ์” เพิ่มปุ่มถังขยะสีแดงสำหรับบัญชี Teacher
- Admin เท่านั้นที่เห็น/เรียกใช้งานการลบได้
- บัญชี Admin จะไม่มีปุ่มลบ
- มีหน้าต่างยืนยันก่อนลบ และแจ้งเตือนว่าการลบเป็นการถาวร
- ใช้ Supabase Edge Function `delete-teacher` เพื่อลบบัญชี Authentication อย่างปลอดภัย โดยตรวจสอบ Admin ฝั่งเซิร์ฟเวอร์อีกชั้น

## ต้อง Deploy Edge Function ก่อนใช้งานปุ่มลบ
เปิด Terminal ที่โฟลเดอร์โปรเจกต์ แล้วรัน:

```powershell
npx supabase functions deploy delete-teacher --no-verify-jwt
```

ถ้าเครื่องยังไม่ได้ login Supabase CLI ให้ login ก่อน:

```powershell
npx supabase login
```

ไม่ต้องนำ `service_role key` มาใส่ใน Flutter หรือส่งให้ใคร เพราะ Edge Function ใช้ `SUPABASE_SERVICE_ROLE_KEY` ของ Supabase ฝั่งเซิร์ฟเวอร์
