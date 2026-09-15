# V113 — REAL DETAIL + GOOGLE DRIVE PROXY 1 IMAGE

ฐานโปรเจกต์: V73 ซึ่งเป็นรุ่นที่ฟังก์ชันหลักใช้งานได้ครบและเป็นจุดอ้างอิงก่อนการแก้ปัญหา Scroll

การทดสอบนี้เปลี่ยนเฉพาะระบบรูปในหน้า Detail:
- ใช้หน้า Detail จริงของ V73
- ใช้รูป Google Drive จริงเพียง 1 รูป
- รูปผ่าน Supabase Edge Function `drive-image`
- ไม่ใช้ Google Drive `uc?export=view` โดยตรง
- ไม่โหลดหลายรูป
- ไม่ใช้ thumbnail หลายรายการ
- UI, PDF, Word, GPS, ข้อมูลรายละเอียด และปุ่มต่าง ๆ ของ Detail เดิมยังคงอยู่

ก่อนรัน ให้ deploy function:
`npx supabase functions deploy drive-image --no-verify-jwt`

จากนั้น:
`flutter clean`
`flutter pub get`
`flutter run -d chrome --web-port 50332 --dart-define-from-file=config.json`

ผลที่ต้องดู:
1. รูปจริงขึ้นหรือไม่
2. หน้า Detail จริงเลื่อนลื่นหรือไม่
3. ทดสอบเลื่อนขึ้นลงหลายรอบ
