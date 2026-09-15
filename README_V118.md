# V118 — REAL DETAIL (PRODUCTION BASE)

เวอร์ชันนี้คืนหน้า Detail จริงจากโปรเจกต์เดิม โดยใช้โครงสร้าง Scroll ที่ผ่านการทดสอบว่าลื่น และระบบรูป Google Drive แบบเสถียร 1 รูป

- หน้า Detail จริง ไม่มีข้อความทดสอบ V115/V116/V117
- แสดงข้อมูลจริงทุกส่วน
- รูป Google Drive ใช้ Supabase Edge Function thumbnail 480px
- ไม่มี PageView / Gallery / thumbnail หลายรูป / image preload / scroll listener
- คลิกภาพเพื่อเปิดดูเต็มจอแบบภาพเดียว
- ปุ่ม PDF / Word / แก้ไข / Google Maps ยังคงใช้งาน
- ใช้ SingleChildScrollView + Column ซึ่งผ่านการทดสอบว่า scroll ลื่น

คำสั่งรัน:
flutter clean
flutter pub get
flutter run -d chrome --web-port 50332 --dart-define-from-file=config.json
