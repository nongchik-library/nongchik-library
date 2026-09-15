# V126 — Google Drive แยกโฟลเดอร์ตามตำบล (โครงสร้างจริง)

โครงสร้างที่ต้องการ:

Google Drive Root
└── ชื่อตำบล
    ├── ภาพแหล่งเรียนรู้
    └── ภาพเกียรติบัตร

ตัวอย่าง:
ปุโละปุโย
├── ภาพแหล่งเรียนรู้
└── ภาพเกียรติบัตร

## สำคัญ
ไฟล์ `supabase/functions/drive-upload/index.ts` ต้อง Deploy ขึ้น Supabase จึงจะเปลี่ยนพฤติกรรมของ Edge Function ที่ใช้งานจริงได้

PowerShell (ถ้ามี Supabase CLI):
`supabase functions deploy drive-upload`

ถ้าเครื่องขึ้นว่า `supabase is not recognized` ให้ติดตั้ง/เรียก CLI ก่อน แล้วค่อย deploy

การแก้ในแอปมีเฉพาะชื่อโฟลเดอร์เกียรติบัตรเป็น `ภาพเกียรติบัตร` และแก้ duplicate `subdistrict` ใน request ไม่แตะระบบ Detail/Scroll/Google Drive image display
