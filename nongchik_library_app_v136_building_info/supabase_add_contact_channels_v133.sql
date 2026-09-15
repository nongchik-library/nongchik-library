-- V133: ช่องทางติดต่อแยกเป็นรายช่องทาง สำหรับทั้ง 7 เมนู
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
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS contact_phone text', t);
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS contact_line text', t);
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS contact_facebook text', t);
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS contact_tiktok text', t);
  END LOOP;
END $$;

NOTIFY pgrst, 'reload schema';
