-- ============================================================
-- KMC 车辆调度系统 · Supabase 建表 SQL
-- 用途：多人同步的云端数据库（7 张表 + RLS 授权）
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

-- 3b. 规则文案表（管理员在设置页编辑提交页规则/提示文案，游客与员工实时生效）
--     cn/en 为文案正文；{ct} 为截止时间占位符，前端渲染时替换为当前截止时间
create table if not exists rules (
  key text primary key,
  cn text default '',
  en text default '',
  "updatedAt" text default ''
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

-- 6. 派车表（含 P0 里程 / P1 DVIR / 费用台账列 / 司机确认列）
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
  "costToll" numeric,
  "driverSig" text default '',
  "driverConfirmed" boolean default false,
  "driverSigDate" text default ''
);

-- ============================================================
-- 已有库升级脚本（若此前已建表，直接执行本段即可补齐新列）
-- ============================================================
-- 规则文案默认值（12 条；{ct} 为截止时间占位符，前端渲染时替换为当前截止时间）
insert into rules(key,cn,en) values
  ('rule_cutoff_1','• 截止时间前未提交的需求视为无需求','• No submission before cutoff = no request'),
  ('rule_cutoff_2','• 截止后提交的，次日统一调度，紧急用车由申请部门自行解决','• After cutoff, processed next day; emergencies must be self-resolved'),
  ('rule_cutoff_3','• 因未按时提交造成延误的，相关责任与成本由申请部门承担','• Late-submission delays: responsibility & cost belong to requesting dept'),
  ('hint_submitter_loggedin','已登录用户无需填写提交人信息，需求自动记录为当前身份；如需更换请先退出登录','Logged-in users need not fill submitter info; the request is recorded under your current identity. Log out first to switch.'),
  ('hint_submitter_guest','无需登录，选择所在部门并填写姓名即可提交，需求将自动记录提交人','No login needed — pick your dept and enter your name to submit; you are recorded as the submitter'),
  ('hint_task_type','选择类型后自动填充常用文案，可再修改','Selecting a type auto-fills common text, editable afterwards'),
  ('hint_date','<b>选择需要用车的日期</b>。默认显示今日；超过 {ct} 截止后只能选明日/后天；长期保障任务可不填日期','<b>Pick the date you need the vehicle</b>. Today is default; after {ct} cutoff only tomorrow/day-after; long-term tasks may skip date'),
  ('hint_time','<b>填写预计出发与返程时间</b>。将用于 GPS 轨迹比对；返程可临时调整','<b>Enter estimated departure & return</b>. Used for GPS cross-check; return time can be adjusted later'),
  ('hint_pax','<b>点 ± 调整乘车人数</b>。填好人数后点"生成乘车人员名单"按人填写姓名','<b>Click ± to adjust count</b>. After setting count, click "Generate Passenger List" to fill in names'),
  ('hint_dest','<b>明确标注出发地 → 目的地</b>。例如：Kamativi → 瀑布城机场；模糊词（外出/办事）会被驳回','<b>Specify origin → destination</b>. e.g., Kamativi → Vic Falls Airport; vague terms (outing/errand) will be rejected'),
  ('hint_bilingual','<b>必填中英双语</b>。填写当前语言后点 🔄 自动翻译并切换到另一种语言；或直接双语手填','<b>Both CN & EN required</b>. Fill active language, click 🔄 to auto-translate and switch; or fill manually'),
  ('hint_signature','<b>点"点击展开签字面板"按钮</b>，用手指/鼠标在白色区域签字后点"保存"','<b>Click "Open Signature Panel" button</b>, use finger/mouse to sign in the white area, then click "Save"')
on conflict (key) do nothing;

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
alter table dispatches add column if not exists "driverSig" text default '';
alter table dispatches add column if not exists "driverConfirmed" boolean default false;
alter table dispatches add column if not exists "driverSigDate" text default '';

-- ============================================================
-- 启用 RLS 并授权 anon 角色读写（内部工具靠邀请码保护）
-- 注意：前端用 anon key 免登录同步，RLS 需放行 anon；
-- 安全底线：users.password 仅存本地（前端已不推送），云上无明文密码。
-- ============================================================
alter table vehicles enable row level security;
alter table drivers enable row level security;
alter table depts enable row level security;
alter table rules enable row level security;
alter table users enable row level security;
alter table requests enable row level security;
alter table dispatches enable row level security;

grant all on vehicles, drivers, depts, rules, users, requests, dispatches to anon, authenticated;

-- 为每张表创建"允许全部读写"的策略（免 token 多人同步）
-- ⚠ 安全提醒：anon key 公开在 HTML 中，任何拿到该 key 的人可读写全部数据。
--   如需收紧，建议启用 Supabase Auth 并改为按用户行级策略（属后续专项，内部工具可暂缓）。
create policy "anon_all" on vehicles for all using (true) with check (true);
create policy "anon_all" on drivers for all using (true) with check (true);
create policy "anon_all" on depts for all using (true) with check (true);
create policy "anon_all" on rules for all using (true) with check (true);
create policy "anon_all" on users for all using (true) with check (true);
create policy "anon_all" on requests for all using (true) with check (true);
create policy "anon_all" on dispatches for all using (true) with check (true);
