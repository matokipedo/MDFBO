-- MDF 1.3.0: add a team member by email from Settings (owner only), and list the team.
-- Before this, the owner needed the SQL editor and a user id. Idempotent; paste the CONTENTS into the SQL editor and Run.

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
