# V120 – REAL DETAIL / 5 IMAGES SAFE

ใช้ V118 ที่ผ่านการทดสอบว่า Detail 1 รูปแสดงและ Scroll ลื่นเป็นฐาน

ปรับเฉพาะส่วนรูปภาพ:
- แสดงรูปจาก Google Drive สูงสุด 5 รูป
- รูปแรกเป็นภาพหลัก 420px
- รูปที่ 2–5 เป็นแถบภาพย่อ 4 ช่อง
- ใช้ Supabase Edge Function drive-image แบบ thumbnail 480px
- ไม่มี PageView / Gallery / Image-loading setState
- ใช้พื้นที่ขนาดคงที่ ลดปัญหา Flutter Web layout/hit-test
- ส่วนข้อมูล ปุ่ม PDF/Word แก้ไข GPS และส่วนอื่นคงจาก V118
