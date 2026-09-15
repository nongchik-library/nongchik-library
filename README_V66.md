# V66 – แก้ปัญหาเปิด/ดาวน์โหลดไฟล์ Google Drive

แก้ `ProgressEvent` ที่เกิดจากการใช้ browser `HttpRequest`/Blob กับ URL ข้ามโดเมนของ Google Drive/Supabase Storage.

- เปิดรูป/PDF ด้วย browser navigation โดยตรง
- ดาวน์โหลดด้วย browser navigation ไปยัง Google Drive download endpoint
- ไม่ต้องเปลี่ยน Secrets หรือฐานข้อมูล
- Google Drive upload เดิมยังใช้เหมือนเดิม
