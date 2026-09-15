-- supabase_schema_v3.sql
-- ตารางข้อมูล 4 หมวด + RLS

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin');
$$;

create table if not exists public.learning_resources (id uuid primary key default gen_random_uuid(), name text not null, description text, subdistrict text, address text, contact text, extra_info text, latitude double precision, longitude double precision, status text not null default 'pending' check(status in ('pending','approved','rejected')), created_by uuid not null references auth.users(id) on delete cascade, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.local_wisdom (id uuid primary key default gen_random_uuid(), name text not null, description text, subdistrict text, address text, contact text, extra_info text, latitude double precision, longitude double precision, status text not null default 'pending' check(status in ('pending','approved','rejected')), created_by uuid not null references auth.users(id) on delete cascade, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.local_scholars (id uuid primary key default gen_random_uuid(), name text not null, description text, subdistrict text, address text, contact text, extra_info text, latitude double precision, longitude double precision, status text not null default 'pending' check(status in ('pending','approved','rejected')), created_by uuid not null references auth.users(id) on delete cascade, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.community_book_houses (id uuid primary key default gen_random_uuid(), name text not null, description text, subdistrict text, address text, contact text, extra_info text, latitude double precision, longitude double precision, status text not null default 'pending' check(status in ('pending','approved','rejected')), created_by uuid not null references auth.users(id) on delete cascade, created_at timestamptz not null default now(), updated_at timestamptz not null default now());

-- เปิด RLS
alter table public.learning_resources enable row level security; alter table public.local_wisdom enable row level security; alter table public.local_scholars enable row level security; alter table public.community_book_houses enable row level security;

-- ลบ policy เดิมของตารางชุดนี้ก่อน (ถ้ามี)
do $$ declare t text; begin foreach t in array array['learning_resources','local_wisdom','local_scholars','community_book_houses'] loop execute format('drop policy if exists "read approved or own" on public.%I',t); execute format('drop policy if exists "insert authenticated" on public.%I',t); execute format('drop policy if exists "update own or admin" on public.%I',t); execute format('drop policy if exists "delete admin only" on public.%I',t); execute format('drop policy if exists "admin manage" on public.%I',t); execute format('create policy "read approved or own" on public.%I for select to authenticated using (status = ''approved'' or created_by = auth.uid() or public.is_admin())',t); execute format('create policy "insert authenticated" on public.%I for insert to authenticated with check (created_by = auth.uid())',t); execute format('create policy "update own or admin" on public.%I for update to authenticated using (created_by = auth.uid() or public.is_admin()) with check (created_by = auth.uid() or public.is_admin())',t); execute format('create policy "delete admin only" on public.%I for delete to authenticated using (public.is_admin())',t); end loop; end $$;

-- ครูแก้ข้อมูลของตนเองแล้วส่งกลับ pending; แอดมินอนุมัติ/ปฏิเสธได้
create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
do $$ declare t text; begin foreach t in array array['learning_resources','local_wisdom','local_scholars','community_book_houses'] loop execute format('drop trigger if exists set_updated_at on public.%I',t); execute format('create trigger set_updated_at before update on public.%I for each row execute function public.set_updated_at()',t); end loop; end $$;

-- สำคัญ: ห้ามครูเปลี่ยน created_by เป็นคนอื่น แต่แอดมินทำได้
