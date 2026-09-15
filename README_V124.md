# V123 Detail 5 Images Simple

หน้า Detail จริง ใช้ข้อมูลเดิมและฟังก์ชัน PDF/Word/แก้ไข/GPS โดยปรับเฉพาะโครงสร้างหน้าแสดงผลให้เรียบง่าย
- รูปภาพสูงสุด 5 รูป
- รูปหลัก 1 รูป + รูปย่อยแบบ Wrap สูงสุด 4 รูป
- ไม่มี PageView / Gallery / GestureDetector
- ใช้ Image.network ธรรมดา
- SingleChildScrollView + Column


## V124 fix — library category constraint
The real Data Form previously sent the Thai display title (for example `แหล่งเรียนรู้`) to `library_files.category`. The database constraint expects controlled category codes used by File Library (`learning_resource`, `local_wisdom`, `scholar`, `activity`, `other`). V124 maps DataType values to those safe codes before Drive upload/database insert.
