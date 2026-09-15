-- V55: Google Drive metadata support
-- Run this in Supabase SQL Editor. Existing Supabase storage records remain valid.
alter table if exists public.library_files add column if not exists storage_provider text not null default 'supabase';
alter table if exists public.library_files add column if not exists drive_file_id text;
alter table if exists public.library_files add column if not exists drive_web_url text;

create index if not exists library_files_drive_file_id_idx on public.library_files(drive_file_id);

-- Content tables: store Drive file IDs alongside legacy photo_paths/certificate_paths.
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['learning_resources','local_wisdom','local_scholars','community_book_houses','subdistrict_learning_centers','tourist_attractions','traditional_foods'] LOOP
    EXECUTE format('alter table public.%I add column if not exists photo_drive_ids text[]', t);
    EXECUTE format('alter table public.%I add column if not exists certificate_drive_ids text[]', t);
  END LOOP;
END $$;
