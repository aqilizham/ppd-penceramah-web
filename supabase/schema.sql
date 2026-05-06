create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  school_name text,
  role text not null default 'school' check (role in ('school', 'ppd')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reference_counters (
  year int primary key,
  last_no int not null default 0
);

create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  ref_no text unique not null,
  school_name text not null,
  officer_name text not null,
  program_title text not null,
  program_date date,
  program_time text,
  program_venue text,
  target_participants text,
  contact_name text,
  contact_phone text,
  speaker_name text not null,
  speaker_ic text not null,
  speaker_phone text,
  speaker_citizenship text,
  speaker_address text,
  speaker_category text not null check (speaker_category in ('dalam', 'luar', 'swasta')),
  speaker_agency text not null,
  academic_qualification text,
  professional_qualification text,
  certification text,
  organization_name text,
  organization_address text,
  organization_registration_no text,
  fee_amount numeric(10, 2),
  purpose text,
  docs jsonb not null default '{"cover": false, "appointment": false, "ic": false, "invite": false}'::jsonb,
  status text not null default 'sent' check (status in ('draft', 'sent', 'review', 'process', 'approved', 'issued')),
  ppd_officer text,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  application_ref text not null references public.applications(ref_no) on delete cascade,
  document_type text not null check (document_type in ('cover', 'appointment', 'ic', 'invite', 'approval_letter', 'ppd_invite_letter')),
  file_name text not null,
  storage_path text not null,
  uploaded_by uuid not null references public.profiles(id),
  uploaded_at timestamptz not null default now()
);

create table if not exists public.status_history (
  id uuid primary key default gen_random_uuid(),
  application_ref text not null references public.applications(ref_no) on delete cascade,
  status text not null,
  note text,
  changed_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists applications_touch_updated_at on public.applications;
create trigger applications_touch_updated_at
before update on public.applications
for each row execute function public.touch_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, school_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'school_name', ''),
    'school'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_ppd()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'ppd'
  );
$$;

create or replace function public.prevent_role_self_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.role is distinct from new.role and not public.is_ppd() then
    raise exception 'Role changes must be made by PPD/admin.';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_role_self_escalation on public.profiles;
create trigger profiles_prevent_role_self_escalation
before update on public.profiles
for each row execute function public.prevent_role_self_escalation();

create or replace function public.next_ref_no()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  current_year int := extract(year from now())::int;
  next_no int;
begin
  insert into public.reference_counters (year, last_no)
  values (current_year, 1)
  on conflict (year)
  do update set last_no = public.reference_counters.last_no + 1
  returning last_no into next_no;

  return 'PPDKLG-' || current_year || '-' || lpad(next_no::text, 3, '0');
end;
$$;

alter table public.profiles enable row level security;
alter table public.applications enable row level security;
alter table public.documents enable row level security;
alter table public.status_history enable row level security;

drop policy if exists "profiles_select_own_or_ppd" on public.profiles;
create policy "profiles_select_own_or_ppd"
on public.profiles for select
using (id = auth.uid() or public.is_ppd());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "applications_select_own_or_ppd" on public.applications;
create policy "applications_select_own_or_ppd"
on public.applications for select
using (created_by = auth.uid() or public.is_ppd());

drop policy if exists "applications_insert_own" on public.applications;
create policy "applications_insert_own"
on public.applications for insert
with check (created_by = auth.uid());

drop policy if exists "applications_update_school_or_ppd" on public.applications;
create policy "applications_update_school_or_ppd"
on public.applications for update
using (created_by = auth.uid() or public.is_ppd())
with check (
  public.is_ppd()
  or (
    created_by = auth.uid()
    and status in ('draft', 'sent', 'review')
  )
);

drop policy if exists "documents_select_own_or_ppd" on public.documents;
create policy "documents_select_own_or_ppd"
on public.documents for select
using (
  public.is_ppd()
  or exists (
    select 1
    from public.applications a
    where a.ref_no = documents.application_ref
      and a.created_by = auth.uid()
  )
);

drop policy if exists "documents_insert_own" on public.documents;
create policy "documents_insert_own"
on public.documents for insert
with check (
  uploaded_by = auth.uid()
  and exists (
    select 1
    from public.applications a
    where a.ref_no = documents.application_ref
      and (a.created_by = auth.uid() or public.is_ppd())
  )
);

drop policy if exists "status_history_select_own_or_ppd" on public.status_history;
create policy "status_history_select_own_or_ppd"
on public.status_history for select
using (
  public.is_ppd()
  or exists (
    select 1
    from public.applications a
    where a.ref_no = status_history.application_ref
      and a.created_by = auth.uid()
  )
);

drop policy if exists "status_history_insert_ppd" on public.status_history;
create policy "status_history_insert_ppd"
on public.status_history for insert
with check (public.is_ppd());

insert into storage.buckets (id, name, public)
values ('speaker-documents', 'speaker-documents', false)
on conflict (id) do nothing;

drop policy if exists "speaker_documents_insert_own_folder" on storage.objects;
create policy "speaker_documents_insert_own_folder"
on storage.objects for insert
with check (
  bucket_id = 'speaker-documents'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "speaker_documents_select_own_or_ppd" on storage.objects;
create policy "speaker_documents_select_own_or_ppd"
on storage.objects for select
using (
  bucket_id = 'speaker-documents'
  and (
    auth.uid()::text = (storage.foldername(name))[1]
    or public.is_ppd()
  )
);

drop policy if exists "speaker_documents_update_own_folder" on storage.objects;
create policy "speaker_documents_update_own_folder"
on storage.objects for update
using (
  bucket_id = 'speaker-documents'
  and auth.uid()::text = (storage.foldername(name))[1]
);

-- Jalankan arahan ini selepas akaun PPD pertama didaftarkan:
-- update public.profiles set role = 'ppd' where email = 'email-pegawai-ppd@example.com';
