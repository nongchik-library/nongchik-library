# เพิ่มคุณครู – V14

เวอร์ชันนี้เพิ่มปุ่ม **+ เพิ่มคุณครู** แบบ Floating Action Button ให้เห็นชัดเจนบนหน้าจอจัดการผู้ใช้งาน และมี Supabase Edge Function `create-teacher` สำหรับสร้างบัญชี Authentication อย่างปลอดภัยโดยตรวจสอบสิทธิ์ Admin ก่อนทุกครั้ง

## 1) Deploy Edge Function ครั้งแรก
เปิด Terminal ที่โฟลเดอร์โปรเจกต์ แล้วรัน:

```powershell
npx supabase login
```

เบราว์เซอร์จะเปิดให้เข้าสู่ระบบ Supabase ให้ใช้บัญชีเจ้าของโปรเจกต์ จากนั้นกลับมาที่ Terminal

ตรวจสอบว่าเชื่อมต่อโปรเจกต์ถูกตัว:

```powershell
npx supabase link --project-ref ddldegnsupfeqfzbjjcr
```

จากนั้น deploy:

```powershell
npx supabase functions deploy create-teacher --no-verify-jwt
```

> Function มีการตรวจสอบ Authorization token และตรวจสอบว่าเป็น Admin เอง จึงไม่ควรตัดการตรวจสอบสิทธิ์ในโค้ดออก

## 2) รันแอป

```powershell
flutter pub get
flutter run -d chrome
```

## 3) วิธีเพิ่มคุณครู

1. เข้าระบบด้วยบัญชี Admin
2. กด **จัดการผู้ใช้งานและสิทธิ์**
3. กดปุ่ม **+ เพิ่มคุณครู** มุมขวาล่าง
4. กรอกชื่อ อีเมล เบอร์โทร ตำบล และรหัสผ่านเริ่มต้น
5. กด **เพิ่มคุณครู**
6. บัญชีจะถูกสร้างใน Supabase Authentication และสร้าง profile เป็น `Teacher` พร้อมตำบลที่รับผิดชอบ

## สำคัญ
- ไม่ต้องใช้ Service Role Key ใน Flutter
- ไม่ต้องนำ Service Role Key มาใส่ในแชต
- Function จะใช้ `SUPABASE_SERVICE_ROLE_KEY` ของ Supabase ฝั่งเซิร์ฟเวอร์เอง
- บัญชีคุณครูใหม่จะยืนยันอีเมลให้แล้วและสามารถเข้าสู่ระบบได้ทันที
