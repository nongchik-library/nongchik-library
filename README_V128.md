# V128 — จัดระเบียบ Google Drive ตามตำบล → เมนู + เพิ่มรูปบุคคล

ฐานจาก V127 ที่ทดสอบครบ 7 เมนูแล้ว

โครงสร้าง Drive ใหม่:

ตำบล → เมนู → ภาพบุคคล / ภาพแหล่งเรียนรู้ / ภาพเกียรติบัตร

ทั้ง 7 เมนูใช้หลักเดียวกัน และไม่แตะ Edge Function ที่ deploy แล้ว เพราะ drive-upload รองรับ path แบบหลายระดับอยู่แล้ว

เพิ่มช่อง/ฟังก์ชัน:
- รูปบุคคล 1 รูปต่อรายการ
- บันทึก person_photo_drive_id
- แสดงรูปบุคคลพร้อมชื่อ–นามสกุลในหน้า Detail

ก่อนทดสอบให้รัน supabase_add_person_photo_v128.sql 1 ครั้ง
จากนั้น Flutter:
flutter clean
flutter pub get
flutter run -d chrome --web-port 50332 --dart-define-from-file=config.json
