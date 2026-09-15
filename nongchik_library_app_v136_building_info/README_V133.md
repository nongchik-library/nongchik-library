# V133 – ช่องทางติดต่อแยกเป็นรายช่องทาง

ฐานจาก V132 ที่ผ่านการทดสอบแล้ว

## เพิ่มในเมนูเพิ่มข้อมูลทั้ง 7 เมนู
1. ผู้รับผิดชอบ (คงช่องเดิม `contact`)
2. ตำแหน่ง
3. เบอร์โทรศัพท์
4. ID Line
5. Facebook
6. TikTok

## ฐานข้อมูล
รัน `supabase_add_contact_channels_v133.sql` ครั้งเดียวใน Supabase SQL Editor

เพิ่มคอลัมน์:
- contact_phone
- contact_line
- contact_facebook
- contact_tiktok

## การแสดงผล
ข้อมูลช่องทางติดต่อถูกเพิ่มในหน้า Detail และเอกสาร PDF/Word โดยไม่เปลี่ยนระบบ Google Drive หรือโครงสร้างโฟลเดอร์เดิม
