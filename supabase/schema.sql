-- DFLES (PROMAS Digital Farmer Learning and Extension System) — Supabase schema v1.0.0
-- One Supabase project = the mixer. Public kit (Deck A) can only INSERT; back office (Deck B) reads/edits by role.
-- Idempotent: safe to run twice. Paste the CONTENTS of this file into the SQL editor (not the file name).

create extension if not exists pgcrypto;

-- ============ Roles ============
create table if not exists public.admin_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('viewer','editor','owner')),
  agrodealer_id uuid,               -- null = sees all partners (PROMAS team)
  created_at timestamptz not null default now()
);
create table if not exists public.admin_audit_log (
  id bigint generated always as identity primary key,
  actor uuid default auth.uid(), action text not null, detail jsonb default '{}'::jsonb,
  at timestamptz not null default now()
);

create or replace function public.my_role() returns text language sql stable security definer set search_path=public as
$$ select role from public.admin_roles where user_id = auth.uid() $$;
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as
$$ select exists(select 1 from public.admin_roles where user_id = auth.uid()) $$;
create or replace function public.can_edit() returns boolean language sql stable security definer set search_path=public as
$$ select coalesce(public.my_role() in ('editor','owner'), false) $$;

-- First signed-in account becomes owner (works once)
create or replace function public.claim_first_owner() returns text language plpgsql security definer set search_path=public as $$
begin
  if auth.uid() is null then raise exception 'sign in first' using errcode='42501'; end if;
  if exists(select 1 from admin_roles) then return 'already_claimed'; end if;
  insert into admin_roles(user_id, role) values (auth.uid(), 'owner');
  insert into admin_audit_log(action) values ('claim_first_owner');
  return 'owner';
end $$;

create or replace function public.set_admin_role(target uuid, new_role text, dealer uuid default null) returns void
language plpgsql security definer set search_path=public as $$
begin
  if public.my_role() is distinct from 'owner' then raise exception 'owner only' using errcode='42501'; end if;
  if new_role is null then delete from admin_roles where user_id = target;
  else insert into admin_roles(user_id, role, agrodealer_id) values (target, new_role, dealer)
       on conflict (user_id) do update set role = excluded.role, agrodealer_id = excluded.agrodealer_id; end if;
  insert into admin_audit_log(action, detail) values ('set_admin_role', jsonb_build_object('target',target,'role',new_role,'dealer',dealer));
end $$;

-- ============ Private tables (back office) ============
create table if not exists public.agrodealers (
  id uuid primary key default gen_random_uuid(),
  name text not null, district text, province text default 'Niassa',
  partnership_season int not null default 1 check (partnership_season between 1 and 10),
  contact_phone text, is_sample boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.technicians (
  id uuid primary key default gen_random_uuid(),
  agrodealer_id uuid references public.agrodealers(id) on delete set null,
  name text not null, phone text, is_sample boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.lead_farmers (
  id uuid primary key default gen_random_uuid(),
  agrodealer_id uuid references public.agrodealers(id) on delete set null,
  technician_id uuid references public.technicians(id) on delete set null,
  name text not null, sex text check (sex in ('f','m') or sex is null), village text, district text,
  phone text, languages text[] default '{}', device_id text, has_smartphone boolean default true,
  is_sample boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.demo_plots (
  id uuid primary key default gen_random_uuid(),
  lead_farmer_id uuid references public.lead_farmers(id) on delete set null,
  agrodealer_id uuid references public.agrodealers(id) on delete set null,
  season text not null default '2026/27' check (season ~ '^\d{4}/\d{2}$'),
  crop text not null check (crop ~ '^[a-z_]{2,20}$'), variety text,
  lat double precision check (lat between -90 and 90), lon double precision check (lon between -180 and 180),
  planting_date date, inputs jsonb default '[]'::jsonb,       -- [{item, qty, unit, date}]
  final_yield_kg_ha numeric check (final_yield_kg_ha >= 0), farmer_observations text,
  status text not null default 'planned' check (status in ('planned','established','harvested','abandoned')),
  is_sample boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.plot_observations (
  id uuid primary key default gen_random_uuid(),
  plot_id uuid not null references public.demo_plots(id) on delete cascade,
  observed_on date not null default current_date,
  stage text, operation text, pest_disease text, severity int check (severity between 0 and 3),
  photo_url text, notes text, recorded_by uuid default auth.uid(),
  is_sample boolean not null default false, created_at timestamptz not null default now()
);

-- ============ Public insert-only tables (Lead Farmer Kit) ============
create table if not exists public.demo_events (
  id bigint generated always as identity primary key,
  device_id text not null check (length(device_id) between 6 and 64),
  event text not null check (event ~ '^[a-z_]{2,40}$'), view text, meta jsonb default '{}'::jsonb,
  app_version text, created_at timestamptz not null default now()
);
create table if not exists public.training_sessions (
  id bigint generated always as identity primary key,
  device_id text not null check (length(device_id) between 6 and 64),
  lead_farmer text, village text, district text,
  crop text not null check (crop ~ '^[a-z_]{2,20}$'),
  module_id text not null check (module_id ~ '^m[0-9]{1,2}$'),
  steps_completed int not null check (steps_completed between 0 and 6),
  farmers_present int not null check (farmers_present between 0 and 500),
  women_present int not null default 0 check (women_present >= 0 and women_present <= farmers_present),
  could_demonstrate int not null default 0 check (could_demonstrate >= 0 and could_demonstrate <= farmers_present),
  started_at timestamptz, finished_at timestamptz, lang text check (lang ~ '^[a-z]{2,8}$'), app_version text,
  is_sample boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.feedback (
  id bigint generated always as identity primary key,
  device_id text not null check (length(device_id) between 6 and 64),
  kind text not null default 'question' check (kind in ('question','problem','photo','idea')),
  message text not null check (length(message) between 1 and 2000),
  village text, district text, app_version text,
  status text not null default 'open' check (status in ('open','answered','escalated')),
  answer text, answered_by uuid, answered_at timestamptz,
  is_sample boolean not null default false, created_at timestamptz not null default now()
);

-- Device rate limit: 60 rows per hour per table
create or replace function public.rate_limit_device() returns trigger language plpgsql security definer set search_path=public as $$
declare n int;
begin
  if auth.role() = 'anon' or auth.uid() is null then
    execute format('select count(*) from public.%I where device_id = $1 and created_at > now() - interval ''1 hour''', TG_TABLE_NAME)
      into n using NEW.device_id;
    if n >= 60 then raise exception 'rate limit' using errcode='42501'; end if;
    NEW.is_sample := false;  -- anon can never flag sample rows
  end if;
  return NEW;
end $$;

-- demo_events has no is_sample column, so give it its own trigger function
create or replace function public.rate_limit_events() returns trigger language plpgsql security definer set search_path=public as $$
declare n int;
begin
  select count(*) into n from public.demo_events where device_id = NEW.device_id and created_at > now() - interval '1 hour';
  if n >= 60 then raise exception 'rate limit' using errcode='42501'; end if;
  return NEW;
end $$;

drop trigger if exists rl on public.training_sessions;
create trigger rl before insert on public.training_sessions for each row execute function public.rate_limit_device();
drop trigger if exists rl on public.feedback;
create trigger rl before insert on public.feedback for each row execute function public.rate_limit_device();
drop trigger if exists rl on public.demo_events;
create trigger rl before insert on public.demo_events for each row execute function public.rate_limit_events();

-- ============ RLS ============
do $$ declare t text;
begin
  -- private tables: admins read, editors write
  foreach t in array array['agrodealers','technicians','lead_farmers','demo_plots','plot_observations'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists adm_read on public.%I', t);
    execute format('drop policy if exists adm_write on public.%I', t);
    execute format('create policy adm_read on public.%I for select to authenticated using (public.is_admin())', t);
    execute format('create policy adm_write on public.%I for all to authenticated using (public.can_edit()) with check (public.can_edit())', t);
  end loop;
  -- public tables: anyone inserts, only admins read, editors update/delete
  foreach t in array array['demo_events','training_sessions','feedback'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists pub_insert on public.%I', t);
    execute format('drop policy if exists adm_read on public.%I', t);
    execute format('drop policy if exists adm_edit on public.%I', t);
    execute format('drop policy if exists adm_del on public.%I', t);
    execute format('create policy pub_insert on public.%I for insert to anon, authenticated with check (true)', t);
    execute format('create policy adm_read on public.%I for select to authenticated using (public.is_admin())', t);
    execute format('create policy adm_edit on public.%I for update to authenticated using (public.can_edit()) with check (public.can_edit())', t);
    execute format('create policy adm_del on public.%I for delete to authenticated using (public.can_edit())', t);
  end loop;
end $$;

alter table public.admin_roles enable row level security;
drop policy if exists self_read on public.admin_roles;
create policy self_read on public.admin_roles for select to authenticated using (user_id = auth.uid() or public.my_role() = 'owner');
alter table public.admin_audit_log enable row level security;
drop policy if exists owner_read on public.admin_audit_log;
create policy owner_read on public.admin_audit_log for select to authenticated using (public.my_role() = 'owner');

revoke all on public.admin_roles, public.admin_audit_log from anon;
grant insert on public.demo_events, public.training_sessions, public.feedback to anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage on all sequences in schema public to anon, authenticated;
grant execute on function public.claim_first_owner(), public.set_admin_role(uuid,text,uuid), public.is_admin(), public.can_edit(), public.my_role() to authenticated;

-- ============ Indicators view (the doc's 8 dimensions, the measurable ones) ============
create or replace view public.v_indicators with (security_invoker = true) as
select
  (select coalesce(sum(farmers_present),0) from training_sessions)                         as reach_farmers,
  (select coalesce(sum(women_present),0) from training_sessions)                           as reach_women,
  (select count(distinct device_id) from training_sessions where created_at > now() - interval '30 days') as active_lead_farmers_30d,
  (select count(*) from lead_farmers)                                                       as lead_farmers_total,
  (select round(100.0 * avg((steps_completed = 6)::int), 1) from training_sessions)         as quality_pct_full_sequence,
  (select round(100.0 * sum(could_demonstrate) / nullif(sum(farmers_present),0), 1) from training_sessions) as learning_pct_demonstrate,
  (select count(*) from demo_plots where status in ('established','harvested'))             as plots_active,
  (select count(*) from feedback where status = 'open')                                     as questions_open;
grant select on public.v_indicators to authenticated;

-- ============ Sample data (clearly flagged; remove with remove_samples.sql) ============
insert into public.agrodealers (id, name, district, partnership_season, is_sample) values
  ('00000000-0000-4000-8000-000000000001','Exemplo Agro Lichinga','Lichinga',1,true),
  ('00000000-0000-4000-8000-000000000002','Exemplo Agro Cuamba','Cuamba',3,true)
on conflict (id) do nothing;
-- MDF 1.2.0: farmer photos/videos per lesson step and demo plot.
-- Files go to a PRIVATE storage bucket; phones (anon) can only upload into it, never list or read.
-- Only signed-in admins can view (via signed URLs). Idempotent.

create table if not exists public.step_media (
  id bigint generated always as identity primary key,
  device_id text not null check (length(device_id) between 6 and 64),
  storage_path text not null unique check (storage_path ~ '^[A-Za-z0-9_-]{6,64}/[0-9]{8}/[A-Za-z0-9_.-]{6,80}$'),
  kind text not null check (kind in ('photo','video')),
  mime text not null check (mime in ('image/jpeg','image/webp','video/mp4','video/webm','video/quicktime')),
  bytes int not null check (bytes between 1 and 20000000),
  crop text check (crop ~ '^[a-z_]{2,20}$'),
  module_id text check (module_id ~ '^m[0-9]{1,2}$'),
  step_id text not null check (step_id in ('introduce','explain','demonstrate','practice','check','reinforce','plot')),
  plot_code text check (length(plot_code) <= 40),
  lead_farmer text, village text, district text,
  caption text check (length(caption) <= 500),
  taken_at timestamptz,
  review text not null default 'new' check (review in ('new','good','needs_help','hidden')),
  reviewer_note text,
  app_version text,
  is_sample boolean not null default false,
  created_at timestamptz not null default now()
);

drop trigger if exists rl on public.step_media;
create trigger rl before insert on public.step_media for each row execute function public.rate_limit_device();

alter table public.step_media enable row level security;
drop policy if exists pub_insert on public.step_media;
drop policy if exists adm_read on public.step_media;
drop policy if exists adm_edit on public.step_media;
drop policy if exists adm_del on public.step_media;
create policy pub_insert on public.step_media for insert to anon, authenticated with check (review = 'new');
create policy adm_read on public.step_media for select to authenticated using (public.is_admin());
create policy adm_edit on public.step_media for update to authenticated using (public.can_edit()) with check (public.can_edit());
create policy adm_del on public.step_media for delete to authenticated using (public.can_edit());
grant insert on public.step_media to anon;
grant select, insert, update, delete on public.step_media to authenticated;
grant usage on all sequences in schema public to anon, authenticated;

-- Private bucket, 20 MB cap, only compressed photo + short video types
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('step-media', 'step-media', false, 20000000,
        array['image/jpeg','image/webp','video/mp4','video/webm','video/quicktime'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "mdf media anon upload" on storage.objects;
drop policy if exists "mdf media admin read" on storage.objects;
drop policy if exists "mdf media editor delete" on storage.objects;
create policy "mdf media anon upload" on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'step-media' and name ~ '^[A-Za-z0-9_-]{6,64}/[0-9]{8}/[A-Za-z0-9_.-]{6,80}$');
create policy "mdf media admin read" on storage.objects for select to authenticated
  using (bucket_id = 'step-media' and public.is_admin());
create policy "mdf media editor delete" on storage.objects for delete to authenticated
  using (bucket_id = 'step-media' and public.can_edit());

-- Indicator: how many sessions came back with visual evidence
create or replace view public.v_media_by_step with (security_invoker = true) as
select module_id, step_id, kind, count(*) as items, count(distinct device_id) as lead_farmers, max(created_at) as latest
from public.step_media where review <> 'hidden' group by 1,2,3;
grant select on public.v_media_by_step to authenticated;

-- ============ 1.3.0: team by email (same as migrations/20261127000000_team_by_email.sql) ============

create or replace function public.admin_grant(p_email text, p_role text default 'editor') returns text
language plpgsql security definer set search_path = '' as $$
declare uid uuid;
begin
  if public.my_role() is distinct from 'owner' then raise exception 'Only the owner can add team members' using errcode = '42501'; end if;
  if p_role is null or p_role not in ('viewer','editor','owner') then raise exception 'Role must be viewer, editor or owner' using errcode = '22023'; end if;
  select u.id into uid from auth.users u where lower(u.email) = lower(trim(p_email)) limit 1;
  if uid is null then return 'no_account'; end if;
  insert into public.admin_roles(user_id, role) values (uid, p_role)
    on conflict (user_id) do update set role = excluded.role;
  insert into public.admin_audit_log(action, detail) values ('admin_grant', jsonb_build_object('target', uid, 'role', p_role));
  return p_role;
end $$;

create or replace function public.admin_team() returns table(email text, role text, since timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then raise exception 'Admins only' using errcode = '42501'; end if;
  return query select u.email::text, r.role, r.created_at from public.admin_roles r join auth.users u on u.id = r.user_id order by r.created_at;
end $$;

revoke all on function public.admin_grant(text, text), public.admin_team() from public, anon;
grant execute on function public.admin_grant(text, text), public.admin_team() to authenticated;
notify pgrst, 'reload schema';
