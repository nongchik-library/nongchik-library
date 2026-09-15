-- Nongchik Library v34: virtual folders for the image/document library
-- Run this once in Supabase SQL Editor. It does not delete existing files.

create table if not exists public.library_folders (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text default '',
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists library_folders_owner_name_idx
  on public.library_folders (created_by, lower(name));

alter table public.library_folders enable row level security;

drop policy if exists "library_folders_select" on public.library_folders;
drop policy if exists "library_folders_insert" on public.library_folders;
drop policy if exists "library_folders_update" on public.library_folders;
drop policy if exists "library_folders_delete" on public.library_folders;

create policy "library_folders_select" on public.library_folders
for select using (created_by = auth.uid() or public.is_admin());

create policy "library_folders_insert" on public.library_folders
for insert with check (created_by = auth.uid() or public.is_admin());

create policy "library_folders_update" on public.library_folders
for update using (created_by = auth.uid() or public.is_admin())
with check (created_by = auth.uid() or public.is_admin());

create policy "library_folders_delete" on public.library_folders
for delete using (public.is_admin());

-- Existing library_files table: store the virtual folder name with each file.
alter table public.library_files add column if not exists folder_name text not null default 'ทั่วไป';
create index if not exists library_files_folder_name_idx on public.library_files(folder_name);

-- Optional folder description is kept in library_folders.description.
