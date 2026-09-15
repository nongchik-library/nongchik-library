-- Nongchik Library v4
create or replace function public.is_admin() returns boolean language sql security definer set search_path=public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin'); $$;
create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade, role text not null default 'teacher', created_at timestamptz not null default now());
create or replace function public.protect_content_fields() returns trigger language plpgsql security definer set search_path=public as $$ begin if not public.is_admin() then if new.created_by<>old.created_by then raise exception 'ไม่อนุญาตให้เปลี่ยนผู้สร้างข้อมูล'; end if; if new.status not in ('pending','rejected') then raise exception 'เฉพาะแอดมินเท่านั้นที่อนุมัติหรือปฏิเสธข้อมูล'; end if; end if; return new; end; $$;
create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
create table if not exists public.learning_resources(id uuid primary key default gen_random_uuid(),name text not null,description text default '',subdistrict text default '',address text default '',contact text default '',extra_info text default '',latitude double precision,longitude double precision,photo_paths text[] not null default '{}',created_by uuid not null references auth.users(id),status text not null default 'pending' check(status in ('pending','approved','rejected')),rejection_reason text,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.local_wisdom(like public.learning_resources including all);
create table if not exists public.local_scholars(like public.learning_resources including all);
create table if not exists public.community_book_houses(like public.learning_resources including all);
create table if not exists public.subdistrict_learning_centers(like public.learning_resources including all);
create table if not exists public.tourist_attractions(like public.learning_resources including all);
create table if not exists public.traditional_foods(like public.learning_resources including all);

do $$ declare t text; begin foreach t in array array['learning_resources','local_wisdom','local_scholars','community_book_houses','subdistrict_learning_centers','tourist_attractions','traditional_foods'] loop
 execute format('alter table public.%I add column if not exists photo_paths text[] not null default ''{}''',t);
 execute format('alter table public.%I add column if not exists rejection_reason text',t);
 execute format('alter table public.%I add column if not exists updated_at timestamptz not null default now()',t);
 execute format('alter table public.%I enable row level security',t);
 execute format('drop policy if exists "read approved own admin" on public.%I',t);
 execute format('create policy "read approved own admin" on public.%I for select using(status=''approved'' or created_by=auth.uid() or public.is_admin())',t);
 execute format('drop policy if exists "insert own" on public.%I',t);
 execute format('create policy "insert own" on public.%I for insert with check(created_by=auth.uid())',t);
 execute format('drop policy if exists "update own admin" on public.%I',t);
 execute format('create policy "update own admin" on public.%I for update using(created_by=auth.uid() or public.is_admin()) with check(created_by=auth.uid() or public.is_admin())',t);
 execute format('drop policy if exists "delete admin" on public.%I',t);
 execute format('create policy "delete admin" on public.%I for delete using(public.is_admin())',t);
 execute format('drop trigger if exists protect_content_fields on public.%I',t);
 execute format('create trigger protect_content_fields before update on public.%I for each row execute function public.protect_content_fields()',t);
 execute format('drop trigger if exists set_updated_at on public.%I',t);
 execute format('create trigger set_updated_at before update on public.%I for each row execute function public.set_updated_at()',t);
end loop; end $$;

insert into storage.buckets(id,name,public) values('library-images','library-images',false) on conflict(id) do update set public=false;
drop policy if exists "images insert own folder" on storage.objects;
create policy "images insert own folder" on storage.objects for insert to authenticated with check(bucket_id='library-images' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "images read authenticated" on storage.objects;
create policy "images read authenticated" on storage.objects for select to authenticated using(bucket_id='library-images');
drop policy if exists "images delete own or admin" on storage.objects;
create policy "images delete own or admin" on storage.objects for delete to authenticated using(bucket_id='library-images' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin()));
