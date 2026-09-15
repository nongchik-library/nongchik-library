-- Nongchik Library v33: history, resource history, awards and certificate attachments
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
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS background_history text DEFAULT '''';', t);
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS resource_history text DEFAULT '''';', t);
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS awards text DEFAULT '''';', t);
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS certificate_paths text[] DEFAULT ARRAY[]::text[];', t);
  END LOOP;
END $$;

-- Existing RLS policies continue to protect these new columns because they are ordinary
-- content columns and the existing teacher/admin INSERT/UPDATE policies apply to the row.
