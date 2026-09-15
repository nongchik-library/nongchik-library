-- V136: ข้อมูลอาคารสถานที่ / เวลาเปิดทำการ / สิ่งอำนวยความสะดวก / ครุภัณฑ์
-- สำหรับเมนู ศกร.ระดับตำบล เท่านั้น
-- เพิ่มเฉพาะคอลัมน์ใหม่ ไม่ลบข้อมูลเดิม

ALTER TABLE public.subdistrict_learning_centers
  ADD COLUMN IF NOT EXISTS building_use text,
  ADD COLUMN IF NOT EXISTS permission_case text,
  ADD COLUMN IF NOT EXISTS independence text,
  ADD COLUMN IF NOT EXISTS weekday_hours text,
  ADD COLUMN IF NOT EXISTS weekend_hours text,
  ADD COLUMN IF NOT EXISTS opening_days text,
  ADD COLUMN IF NOT EXISTS internet text,
  ADD COLUMN IF NOT EXISTS water_supply text,
  ADD COLUMN IF NOT EXISTS electricity text,
  ADD COLUMN IF NOT EXISTS toilet text,
  ADD COLUMN IF NOT EXISTS notebook text,
  ADD COLUMN IF NOT EXISTS desktop text,
  ADD COLUMN IF NOT EXISTS tv text,
  ADD COLUMN IF NOT EXISTS tablet text,
  ADD COLUMN IF NOT EXISTS projector text,
  ADD COLUMN IF NOT EXISTS tables text,
  ADD COLUMN IF NOT EXISTS chairs text;

NOTIFY pgrst, 'reload schema';
