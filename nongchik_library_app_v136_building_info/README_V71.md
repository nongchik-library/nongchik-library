# Nongchik Library App V72

แก้ปัญหาอัปโหลดหลายไฟล์: ตัดการเรียก Google Identity/userinfo ออกจาก Edge Function เพราะ OAuth token ที่ให้สิทธิ์ Google Drive อย่างเดียวไม่จำเป็นต้องมีสิทธิ์ OpenID userinfo และอาจทำให้เกิด 401 ทั้งที่ไฟล์อัปโหลดเข้า Drive ได้

## Deploy Edge Function
```
npx supabase functions deploy drive-upload --no-verify-jwt
```

## Run Flutter Web
```
flutter clean
flutter pub get
flutter run -d chrome --web-port 50332 --dart-define-from-file=config.json
```

รองรับเลือกหลายไฟล์ในการอัปโหลดครั้งเดียว โดยระบบอัปโหลดทีละไฟล์และบันทึกแต่ละไฟล์เป็นรายการแยกใน library_files. ไม่มีการจำกัดจำนวนไฟล์ในตัว Flutter; ข้อจำกัดต่อไฟล์ของ Edge Function ยังคง 25 MB.


V72 สำคัญ: drive-upload จะตรวจสอบผู้ใช้จาก Supabase JWT และบันทึก metadata ลง library_files ฝั่ง Edge Function หลังอัปโหลด Drive สำเร็จ หากบันทึกฐานข้อมูลไม่สำเร็จ ระบบจะลบไฟล์ Drive ที่เพิ่งสร้างเพื่อไม่ให้เกิดไฟล์ค้าง.
