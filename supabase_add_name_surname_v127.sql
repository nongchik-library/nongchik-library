-- V127: Add first_name / last_name fields to all 7 data menus.
-- Run this once in Supabase SQL Editor before testing V127.

DO $$
DECLARE t text;
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
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS first_name text', t);
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS last_name text', t);
  END LOOP;
END $$;
