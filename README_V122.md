# V122 - Detail 5 Images Stable

รุ่นนี้ยึดหน้า Detail จริงของโปรเจกต์ และคงข้อมูล/ปุ่ม PDF/Word/แก้ไข/ข้อมูล GPS ส่วนอื่นไว้เหมือนเดิม

ปรับเฉพาะส่วนรูปภาพ:
- แสดงรูปภาพสูงสุด 5 รูป
- รูปหลัก 1 รูป + รูปย่อยสูงสุด 4 รูป
- กำหนดขนาดพื้นที่รูปตายตัว
- ไม่มี PageView / Gallery / โหลดรูปหลายชุดแบบ Async
- ไม่มี GestureDetector ครอบรูปภาพโดยตรง เพื่อลดปัญหา hit-test / mouse_tracker บน Flutter Web
- มีปุ่ม "ดูภาพหลักเต็มจอ" แยกออกจากพื้นที่รูป
- ใช้ Google Drive ผ่าน Supabase Edge Function ตามระบบเดิม

คำสั่งทดสอบ:
flutter clean
flutter pub get
flutter run -d chrome --web-port 50332 --dart-define-from-file=config.json
