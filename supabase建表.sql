-- ============================================================
-- KMC 车辆调度系统 · Supabase 建表 SQL
-- 用途：多人同步的云端数据库（6 张表 + RLS 授权）
-- 执行方式：Supabase 后台 → SQL Editor → 粘贴全文 → Run
-- ============================================================

-- 1. 车辆表（含 P0 维保/状态字段）
create table if not exists vehicles (
  plate text primary key,
  type text default '',
  "typeEn" text default '',
  seats int default 5,
  status text default 'idle',
  "insuranceExpire" text default '',
  "inspectionExpire" text default '',
  "lastServiceKm" text default ''
);

-- 2. 司机表
create table if not exists drivers (
  name text primary key
);

-- 3. 部门表
create table if not exists depts (
  cn text primary key,
  en text default ''
);

-- 4. 人员表
create table if not exists users (
  name text,
  department text,
  role text default 'user',
  password text default '',
  "firstLogin" text,
  "lastLogin" text,
  primary key (name, department)
);

-- 5. 需求表
create table if not exists requests (
  id text primary key,
  type text default '',
  date text default '',
  "timeSlot" text default '',
  passengers int default 1,
  "paxNames" jsonb default '[]',
  purpose text default '',
  "purposeEn" text default '',
  destination text default '',
  "destinationEn" text default '',
  notes text default '',
  "notesEn" text default '',
  approved text default 'no',
  signature text default '',
  department text default '',
  submitter text default '',
  status text default 'pending',
  "mergedToDispatchId" text,
  "createdAt" text default ''
);

-- 6. 派车表（含 P0 里程 / P1 DVIR / 费用台账列）
create table if not exists dispatches (
  id text primary key,
  date text default '',
  vehicle text default '',
  driver text default '',
  "departureTime" text,
  "meetingPoint" text,
  notes text default '',
  "notesEn" text default '',
  signature text default '',
  "requestIds" jsonb default '[]',
  "createdAt" text default '',
  "startKm" int,
  "endKm" int,
  "fuelL" numeric,
  "dvir" jsonb default '[]',
  "dvirDate" text default '',
  "costFuel" numeric,
  "costRepair" numeric,
  "costToll" numeric
);

-- ============================================================
-- 已有库升级脚本（若此前已建表，直接执行本段即可补齐新列）
-- ============================================================
alter table vehicles add column if not exists status text default 'idle';
alter table vehicles add column if not exists "insuranceExpire" text default '';
alter table vehicles add column if not exists "inspectionExpire" text default '';
alter table vehicles add column if not exists "lastServiceKm" text default '';
alter table dispatches add column if not exists "startKm" int;
alter table dispatches add column if not exists "endKm" int;
alter table dispatches add column if not exists "fuelL" numeric;
alter table dispatches add column if not exists "dvir" jsonb default '[]';
alter table dispatches add column if not exists "dvirDate" text default '';
alter table dispatches add column if not exists "costFuel" numeric;
alter table dispatches add column if not exists "costRepair" numeric;
alter table dispatches add column if not exists "costToll" numeric;

-- ============================================================
-- 启用 RLS 并授权 anon 角色读写（内部工具靠邀请码保护）
-- 注意：前端用 anon key 免登录同步，RLS 需放行 anon；
-- 安全底线：users.password 仅存本地（前端已不推送），云上无明文密码。
-- ============================================================
alter table vehicles enable row level security;
alter table drivers enable row level security;
alter table depts enable row level security;
alter table users enable row level security;
alter table requests enable row level security;
alter table dispatches enable row level security;

grant all on vehicles, drivers, depts, users, requests, dispatches to anon, authenticated;

-- 为每张表创建"允许全部读写"的策略（免 token 多人同步）
-- ⚠ 安全提醒：anon key 公开在 HTML 中，任何拿到该 key 的人可读写全部数据。
--   如需收紧，建议启用 Supabase Auth 并改为按用户行级策略（属后续专项，内部工具可暂缓）。
create policy "anon_all" on vehicles for all using (true) with check (true);
create policy "anon_all" on drivers for all using (true) with check (true);
create policy "anon_all" on depts for all using (true) with check (true);
create policy "anon_all" on users for all using (true) with check (true);
create policy "anon_all" on requests for all using (true) with check (true);
create policy "anon_all" on dispatches for all using (true) with check (true);
