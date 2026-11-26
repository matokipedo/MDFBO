\set ON_ERROR_STOP 1
drop schema public cascade; create schema public; grant usage on schema public to anon, authenticated; truncate auth.users cascade;
\i /var/tmp/dflespg/storage_stub.sql
\i /var/tmp/dflespg/20261126000000_mdf_init.sql
\i /var/tmp/dflespg/20261126020000_step_media.sql
\i /var/tmp/dflespg/20261126020000_step_media.sql
insert into auth.users values ('11111111-1111-4111-8111-111111111111');
set role anon; select set_config('request.jwt.role','anon',false);
insert into storage.objects(bucket_id,name) values ('step-media','dev-abc-123/20261126/m2-practice-1732.jpg');
insert into step_media(device_id,storage_path,kind,mime,bytes,module_id,step_id,plot_code,village) values ('dev-abc-123','dev-abc-123/20261126/m2-practice-1732.jpg','photo','image/jpeg',148000,'m2','practice','LCH-01','Chiuaula');
do $$ begin perform 1 from step_media; raise exception 'anon read'; exception when insufficient_privilege then raise notice 'PASS anon cannot read step_media'; end $$;
select 'PASS anon sees 0 storage objects: '||count(*) from storage.objects;
do $$ begin insert into storage.objects(bucket_id,name) values ('step-media','../../etc/passwd'); raise exception 'bad path'; exception when insufficient_privilege then raise notice 'PASS bad path refused'; end $$;
do $$ begin insert into storage.objects(bucket_id,name) values ('other-bucket','dev-abc-123/20261126/x-file.jpg'); raise exception 'other bucket'; exception when insufficient_privilege then raise notice 'PASS other bucket refused'; end $$;
do $$ begin insert into step_media(device_id,storage_path,kind,mime,bytes,step_id,review) values ('dev-abc-123','dev-abc-123/20261126/m2-x-17.jpg','photo','image/jpeg',10,'practice','good'); raise exception 'anon set review'; exception when insufficient_privilege then raise notice 'PASS anon cannot pre-approve'; end $$;
do $$ begin insert into step_media(device_id,storage_path,kind,mime,bytes,step_id) values ('dev-abc-123','dev-abc-123/20261126/m2-y-17.exe','photo','application/x-msdownload',10,'practice'); raise exception 'bad mime'; exception when check_violation then raise notice 'PASS bad mime refused'; end $$;
reset role;
set role authenticated; select set_config('request.jwt.sub','11111111-1111-4111-8111-111111111111',false), set_config('request.jwt.role','authenticated',false);
select claim_first_owner();
select 'owner sees media: '||count(*) from step_media; select 'owner sees objects: '||count(*) from storage.objects;
select * from v_media_by_step;
