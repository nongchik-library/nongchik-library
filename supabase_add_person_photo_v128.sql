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
      'ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS person_photo_drive_id text',
      t
    );
  END LOOP;
END $$;

NOTIFY pgrst, 'reload schema';
