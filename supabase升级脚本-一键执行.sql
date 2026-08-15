-- ============================================================
-- KMC 车辆调度系统 · 云端表结构升级脚本（一键执行）
-- 执行位置：Supabase 控制台 → SQL Editor → 粘贴全文 → Run
-- 生成时间：2026-08-15
-- 说明：修复前云端 vehicles 缺 4 列、dispatches 缺 8 列，
--       前端写入新字段报 PGRST204，导致云同步"假成功"。
--       本脚本为幂等升级（IF NOT EXISTS），可重复执行。
-- ============================================================

-- 1. vehicles 补列（P0：车辆状态 + 维保字段）
alter table vehicles add column if not exists status text default 'idle';
alter table vehicles add column if not exists "insuranceExpire" text default '';
alter table vehicles add column if not exists "inspectionExpire" text default '';
alter table vehicles add column if not exists "lastServiceKm" text default '';

-- 2. dispatches 补列（P0/P1：里程油耗 / DVIR 出车检查 / 费用台账）
alter table dispatches add column if not exists "startKm" int;
alter table dispatches add column if not exists "endKm" int;
alter table dispatches add column if not exists "fuelL" numeric;
alter table dispatches add column if not exists "dvir" jsonb default '[]';
alter table dispatches add column if not exists "dvirDate" text default '';
alter table dispatches add column if not exists "costFuel" numeric;
alter table dispatches add column if not exists "costRepair" numeric;
alter table dispatches add column if not exists "costToll" numeric;

-- ============================================================
-- 验证（Run 后可在 SQL Editor 下方结果区看到两行查询结果）：
--   vehicles  应有 8 列
--   dispatches 应有 19 列
-- ============================================================
select 'vehicles' as tbl, count(*) as col_count
from information_schema.columns
where table_schema='public' and table_name='vehicles'
union all
select 'dispatches' as tbl, count(*) as col_count
from information_schema.columns
where table_schema='public' and table_name='dispatches';
