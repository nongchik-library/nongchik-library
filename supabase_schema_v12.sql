-- Nongchik Library V12
-- ระบบจัดการผู้ใช้งาน / สิทธิ์ / ตำบลที่รับผิดชอบ
-- รันหลังจาก schema v5 และสามารถรันซ้ำได้

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'teacher' check (role in ('teacher','admin')),
  display_name text not null default '',
  email text not null default '',
  phone text not null default '',
  subdistrict text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists display_name text not null default '';
alter table public.profiles add column if not exists email text not null default '';
alter table public.profiles add column if not exists phone text not null default '';
alter table public.profiles add column if not exists subdistrict text not null default '';
alter table public.profiles add column if not exists is_active boolean not null default true;
alter table public.profiles add column if not exists updated_at timestamptz not null default now();

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin' and p.is_active = true
  );
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_updated_at on public.profiles;
create trigger set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

-- สร้าง profile อัตโนมัติเมื่อมีผู้สมัคร/ผู้ดูแลสร้างผู้ใช้ใหม่
create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id, role, display_name, email, is_active)
  values (
    new.id,
    'teacher',
    coalesce(new.raw_user_meta_data->>'display_name', ''),
    coalesce(new.email, ''),
    true
  )
  on conflict (id) do update set
    email = excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function public.handle_new_user_profile();

-- เปิด RLS และกำหนดสิทธิ์: เจ้าของอ่านของตนเอง, Admin อ่าน/แก้ไขทั้งหมด
alter table public.profiles enable row level security;

drop policy if exists "profiles read own admin" on public.profiles;
create policy "profiles read own admin" on public.profiles
for select to authenticated
using (id = auth.uid() or public.is_admin());

drop policy if exists "profiles update admin only" on public.profiles;
create policy "profiles update admin only" on public.profiles
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "profiles insert admin" on public.profiles;
create policy "profiles insert admin" on public.profiles
for insert to authenticated
with check (public.is_admin());

drop policy if exists "profiles delete admin" on public.profiles;
create policy "profiles delete admin" on public.profiles
for delete to authenticated
using (public.is_admin());

-- ทำให้ profile เดิมมีค่า email จาก auth.users (ใช้ได้จาก SQL Editor)
update public.profiles p
set email = coalesce(u.email, p.email)
from auth.users u
where u.id = p.id and coalesce(p.email, '') = '';

-- เพิ่ม/ปรับกฎของข้อมูลทั้ง 7 หมวด:
-- ครูอ่านข้อมูลที่อนุมัติได้ และข้อมูลของตนเอง
-- ครูเพิ่ม/แก้ไขได้เฉพาะตำบลที่ Admin มอบหมาย
-- Admin ทำได้ทุกอย่าง
DO $$
declare t text;
begin
  foreach t in array array[
    'learning_resources','local_wisdom','local_scholars',
    'community_book_houses','subdistrict_learning_centers',
    'tourist_attractions','traditional_foods'
  ] loop
    execute format('drop policy if exists "read approved own admin" on public.%I', t);
    execute format('drop policy if exists "insert own assigned subdistrict" on public.%I', t);
    execute format('drop policy if exists "update own assigned subdistrict" on public.%I', t);
    execute format('drop policy if exists "delete admin" on public.%I', t);

    execute format($sql$
      create policy "read approved own admin" on public.%I
      for select to authenticated
      using (
        (status = 'approved' and exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_active = true))
        or (created_by = auth.uid())
        or public.is_admin()
      )
    $sql$, t);

    execute format($sql$
      create policy "insert own assigned subdistrict" on public.%I
      for insert to authenticated
      with check (
        created_by = auth.uid()
        and (
          public.is_admin()
          or subdistrict = coalesce((select p.subdistrict from public.profiles p where p.id = auth.uid() and p.is_active = true), '')
        )
      )
    $sql$, t);

    execute format($sql$
      create policy "update own assigned subdistrict" on public.%I
      for update to authenticated
      using (created_by = auth.uid() or public.is_admin())
      with check (
        public.is_admin()
        or (
          created_by = auth.uid()
          and subdistrict = coalesce((select p.subdistrict from public.profiles p where p.id = auth.uid() and p.is_active = true), '')
        )
      )
    $sql$, t);

    execute format($sql$
      create policy "delete admin" on public.%I
      for delete to authenticated
      using (public.is_admin())
    $sql$, t);
  end loop;
end $$;

-- Trigger เดิม: ครูเปลี่ยนผู้สร้างไม่ได้ และอนุมัติเองไม่ได้
create or replace function public.protect_content_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    if new.created_by <> old.created_by then
      raise exception 'ไม่อนุญาตให้เปลี่ยนผู้สร้างข้อมูล';
    end if;
    if new.status not in ('pending','rejected') then
      raise exception 'เฉพาะแอดมินเท่านั้นที่อนุมัติหรือปฏิเสธข้อมูล';
    end if;
  end if;
  return new;
end;
$$;

DO $$
declare t text;
begin
  foreach t in array array[
    'learning_resources','local_wisdom','local_scholars',
    'community_book_houses','subdistrict_learning_centers',
    'tourist_attractions','traditional_foods'
  ] loop
    execute format('drop trigger if exists protect_content_fields on public.%I', t);
    execute format('create trigger protect_content_fields before update on public.%I for each row execute function public.protect_content_fields()', t);
  end loop;
end $$;
