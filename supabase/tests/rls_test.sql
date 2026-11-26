\set ON_ERROR_STOP 1
-- idempotent re-run
\i ../schema.sql
insert into auth.users values ('11111111-1111-4111-8111-111111111111'),('22222222-2222-4222-8222-222222222222');
-- anon inserts work, reads return 0
set role anon; select set_config('request.jwt.role','anon',false);
insert into training_sessions(device_id,crop,module_id,steps_completed,farmers_present,women_present,could_demonstrate,is_sample) values ('dev-abc-123','maize','m2',6,30,18,21,true);
insert into feedback(device_id,message) values ('dev-abc-123','Folhas com furos, o que faço?');
insert into demo_events(device_id,event) values ('dev-abc-123','lesson_start');
do $$ begin perform 1 from training_sessions; raise exception 'anon could read'; exception when insufficient_privilege then raise notice 'PASS anon cannot read sessions'; end $$;
do $$ begin insert into training_sessions(device_id,crop,module_id,steps_completed,farmers_present,could_demonstrate) values ('dev-abc-123','maize','m2',6,5,9); raise exception 'bad row accepted'; exception when check_violation then raise notice 'PASS could_demonstrate <= present enforced'; end $$;
do $$ begin perform 1 from agrodealers; raise exception 'anon read private'; exception when insufficient_privilege then raise notice 'PASS anon cannot read private'; end $$;
reset role;
-- rate limit
set role anon;
do $$ begin for i in 1..61 loop insert into demo_events(device_id,event) values ('dev-rl-0001','tap'); end loop; raise exception 'no limit'; exception when insufficient_privilege then raise notice 'PASS rate limit at 60/hour'; end $$;
reset role;
-- authenticated non-admin sees nothing
set role authenticated; select set_config('request.jwt.sub','22222222-2222-4222-8222-222222222222',false), set_config('request.jwt.role','authenticated',false);
select 'non-admin sees sessions: '||count(*) from training_sessions;
reset role;
-- first owner claim
set role authenticated; select set_config('request.jwt.sub','11111111-1111-4111-8111-111111111111',false);
select claim_first_owner();
select 'owner sees sessions: '||count(*) from training_sessions;
select 'sample flag forced false for anon: '||bool_and(not is_sample) from training_sessions;
select * from v_indicators;
insert into demo_plots(crop,variety,planting_date,lat,lon,status) values ('maize','PAN 53',current_date-20,-13.31,35.24,'established');
reset role;
set role authenticated; select set_config('request.jwt.sub','22222222-2222-4222-8222-222222222222',false);
select claim_first_owner() as second_claim;
do $$ begin perform set_admin_role('22222222-2222-4222-8222-222222222222','owner'); raise exception 'non-owner promoted'; exception when insufficient_privilege then raise notice 'PASS only owner sets roles'; end $$;
reset role;
\i ../remove_samples.sql
select 'agrodealers after remove: '||count(*) from agrodealers;
