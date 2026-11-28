\set ON_ERROR_STOP 1
-- run after rls_test.sql (owner 1111 exists, 2222 is a plain account)
alter table auth.users add column if not exists email text;
update auth.users set email = 'owner@example.org' where id = '11111111-1111-4111-8111-111111111111';
update auth.users set email = 'Tech@Example.org' where id = '22222222-2222-4222-8222-222222222222';
\i ../migrations/20261127000000_team_by_email.sql
\i ../migrations/20261127000000_team_by_email.sql
set role anon; select set_config('request.jwt.sub','',false), set_config('request.jwt.role','anon',false);
do $$ begin perform public.admin_grant('tech@example.org'); raise exception 'anon could grant'; exception when insufficient_privilege then raise notice 'PASS anon cannot grant'; end $$;
reset role;
set role authenticated; select set_config('request.jwt.sub','22222222-2222-4222-8222-222222222222',false), set_config('request.jwt.role','authenticated',false);
do $$ begin perform public.admin_grant('tech@example.org','owner'); raise exception 'non-owner could grant'; exception when insufficient_privilege then raise notice 'PASS non-owner cannot grant'; end $$;
do $$ begin perform public.admin_team(); raise exception 'non-admin listed team'; exception when insufficient_privilege then raise notice 'PASS non-admin cannot list team'; end $$;
reset role;
set role authenticated; select set_config('request.jwt.sub','11111111-1111-4111-8111-111111111111',false);
do $$ begin if public.admin_grant('nobody@example.org') <> 'no_account' then raise exception 'expected no_account'; end if; raise notice 'PASS unknown email returns no_account'; end $$;
do $$ begin perform public.admin_grant('tech@example.org','boss'); raise exception 'bad role accepted'; exception when invalid_parameter_value then raise notice 'PASS bad role rejected'; end $$;
do $$ begin if public.admin_grant('  TECH@example.org ','editor') <> 'editor' then raise exception 'grant failed'; end if; raise notice 'PASS owner adds editor by email (case/space-insensitive)'; end $$;
do $$ begin if (select count(*) from public.admin_team()) <> 2 then raise exception 'team count wrong'; end if; raise notice 'PASS team lists 2 people'; end $$;
reset role;
set role authenticated; select set_config('request.jwt.sub','22222222-2222-4222-8222-222222222222',false);
do $$ begin if not public.can_edit() then raise exception 'editor cannot edit'; end if; raise notice 'PASS new editor can edit'; end $$;
reset role;
