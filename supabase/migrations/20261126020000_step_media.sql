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
