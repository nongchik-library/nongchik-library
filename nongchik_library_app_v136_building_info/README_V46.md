Nongchik Library V46 - แก้ปัญหาฟอร์มเพิ่มข้อมูลและโหลด profile ก่อนบันทึก

# Nongchik Library V45

## แก้ปัญหาเพิ่มข้อมูล 7 เมนูหลัก

อาการที่แก้: ฟอร์มเพิ่มข้อมูลของ แหล่งเรียนรู้ / ภูมิปัญญาท้องถิ่น / ปราชญ์ชาวบ้าน / บ้านหนังสือชุมชน / ศกร.ระดับตำบล / แหล่งท่องเที่ยว / อาหารและขนมโบราณ ไม่สามารถบันทึกได้ หลังเพิ่มฟิลด์ประวัติและรางวัล

### ต้องทำ 1 ครั้งใน Supabase
1. เปิด Supabase Dashboard > SQL Editor
2. เปิดไฟล์ `supabase_schema_v45.sql`
3. คัดลอก SQL ทั้งหมดไปวาง
4. กด Run
5. ผลลัพธ์ท้ายคำสั่งควรแสดง 7 แถว และคอลัมน์ `has_background_history`, `has_resource_history`, `has_awards`, `has_certificate_paths` เป็น `true` ทั้งหมด

จากนั้นเปิดโปรเจกต์ Flutter แล้วรัน:

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

ไม่ต้องลบข้อมูลเดิม และไม่ต้องสร้าง bucket ใหม่
