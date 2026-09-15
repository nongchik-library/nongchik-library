-- V132: เพิ่มคอลัมน์ตำแหน่งสำหรับผู้รับผิดชอบ/ผู้ให้ข้อมูลทั้ง 7 เมนู
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'learning_resources',
    'local_wisdom',
    'local_scholars',
    'community_book_houses',
    'subdistrict_learning_centers',
    'tourist_attractions',
    'traditional_foods'
  ] LOOP
    EXECUTE format(
      'ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS position text',
      t
    );
  END LOOP;
END $$;

NOTIFY pgrst, 'reload schema';
