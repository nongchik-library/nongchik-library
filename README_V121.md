# V121 - Detail 5 Images Compile Fix

แก้ไข V120 ที่คอมไพล์ไม่ผ่านใน data_detail_page.dart

- แก้ `_showFullImage()` ให้รับ index ของภาพ
- คลิกภาพหลัก/ภาพย่อยแล้วเปิดภาพที่ถูกต้อง
- คงโครงสร้าง Detail และระบบภาพสูงสุด 5 ภาพของ V120
- ไม่เปลี่ยนส่วนอื่นของระบบ

คำสั่งทดสอบ:
flutter clean
flutter pub get
flutter run -d chrome --web-port 50332 --dart-define-from-file=config.json
