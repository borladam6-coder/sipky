-- =====================================================================
--  Šipky – sdílená databáze pro kancelář (Supabase / Postgres)
--  Spusť celé jednou v Supabase: SQL Editor → New query → vložit → Run.
--  Skript jde spustit i opakovaně (nic nesmaže).
-- =====================================================================

-- ---------- tabulky ----------
create table if not exists public.offices (
  id         uuid primary key default gen_random_uuid(),
  code       text not null unique check (code ~ '^[A-Z0-9]{4,12}$'),
  created_at timestamptz not null default now()
);

create table if not exists public.members (
  user_id   uuid not null,
  office_id uuid not null references public.offices(id) on delete cascade,
  device    text,
  joined_at timestamptz not null default now(),
  primary key (user_id, office_id)
);

create table if not exists public.players (
  id         text primary key,
  office_id  uuid not null references public.offices(id) on delete cascade,
  name       text not null check (length(name) between 1 and 20),
  color      text,
  archived   boolean not null default false,
  updated_at timestamptz not null default now()
);
create index if not exists players_office on public.players(office_id);

create table if not exists public.games (
  id         text primary key,
  office_id  uuid not null references public.offices(id) on delete cascade,
  type       text not null check (type in ('x01','cricket','countup')),
  settings   jsonb not null,
  sides      jsonb not null,
  status     text not null default 'live' check (status in ('live','done','void')),
  result     jsonb,
  created_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists games_office_status on public.games(office_id, status);

-- Každá šipka = jeden řádek. "seq" je pořadí šipky ve hře.
-- Zpět šipku nesmaže, jen označí undone = true (historie zůstane).
create table if not exists public.throws (
  id         bigint generated always as identity primary key,
  game_id    text not null references public.games(id) on delete cascade,
  office_id  uuid not null references public.offices(id) on delete cascade,
  seq        int  not null check (seq > 0),
  n          smallint not null check (n in (0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,25)),
  m          smallint not null check (m between 1 and 3),
  device     text,
  who        text,
  undone     boolean not null default false,
  undone_by  text,
  created_at timestamptz not null default now()
);
-- Jedna platná šipka na pořadí: druhý telefon se stejným seq dostane chybu 23505.
create unique index if not exists throws_live_seq on public.throws(game_id, seq) where not undone;
create index if not exists throws_office on public.throws(office_id);

create table if not exists public.heartbeat (
  id int primary key,
  at timestamptz not null
);

-- ---------- pomocná funkce: kanceláře přihlášeného telefonu ----------
create or replace function public.my_offices()
returns setof uuid language sql stable security definer set search_path = public as $$
  select office_id from public.members where user_id = auth.uid()
$$;

-- ---------- práva a pravidla (row level security) ----------
alter table public.offices   enable row level security;
alter table public.members   enable row level security;
alter table public.players   enable row level security;
alter table public.games     enable row level security;
alter table public.throws    enable row level security;
alter table public.heartbeat enable row level security;

revoke all on public.offices, public.members, public.players, public.games, public.throws, public.heartbeat from anon, authenticated;
grant select on public.offices, public.members to authenticated;
grant select, insert, update on public.players, public.games to authenticated;
grant select, insert on public.throws to authenticated;

drop policy if exists offices_read on public.offices;
create policy offices_read on public.offices for select to authenticated using (id in (select public.my_offices()));
drop policy if exists members_read on public.members;
create policy members_read on public.members for select to authenticated using (user_id = auth.uid());

drop policy if exists players_all on public.players;
create policy players_all on public.players for all to authenticated
  using (office_id in (select public.my_offices())) with check (office_id in (select public.my_offices()));
drop policy if exists games_all on public.games;
create policy games_all on public.games for all to authenticated
  using (office_id in (select public.my_offices())) with check (office_id in (select public.my_offices()));
drop policy if exists throws_read on public.throws;
create policy throws_read on public.throws for select to authenticated using (office_id in (select public.my_offices()));
drop policy if exists throws_add on public.throws;
create policy throws_add on public.throws for insert to authenticated
  with check (office_id in (select public.my_offices()) and not undone
              and exists (select 1 from public.games g where g.id = game_id and g.office_id = throws.office_id and g.status = 'live'));

-- ---------- funkce volané z aplikace ----------
-- Kancelář nejde založit z aplikace – zakládá ji jen správce v SQL Editoru (viz konec souboru).
drop function if exists public.create_office(text, text);

-- Připojí telefon ke kanceláři podle kódu.
create or replace function public.join_office(p_code text, p_device text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'not_signed_in'; end if;
  select id into v_id from public.offices where code = upper(trim(p_code));
  if v_id is null then raise exception 'office_not_found'; end if;
  insert into public.members(user_id, office_id, device) values (auth.uid(), v_id, p_device)
    on conflict (user_id, office_id) do update set device = excluded.device;
  return v_id;
end $$;

-- Zpět: vrátí poslední šipku hry, jen když je pořád poslední (jinak false).
create or replace function public.undo_last(p_game text, p_seq int, p_who text default null)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_office uuid; v_max int;
begin
  select office_id into v_office from public.games where id = p_game and status = 'live';
  if v_office is null or v_office not in (select public.my_offices()) then return false; end if;
  select max(seq) into v_max from public.throws where game_id = p_game and not undone;
  if v_max is null or v_max <> p_seq then return false; end if;
  update public.throws set undone = true, undone_by = p_who where game_id = p_game and seq = p_seq and not undone;
  return true;
end $$;

-- Udržování naživu (volá GitHub Actions každé 3 dny).
create or replace function public.heartbeat()
returns timestamptz language sql security definer set search_path = public as $$
  insert into public.heartbeat(id, at) values (1, now())
  on conflict (id) do update set at = excluded.at
  returning at
$$;

revoke all on function public.my_offices() from public, anon;
revoke all on function public.join_office(text, text), public.undo_last(text, int, text) from public, anon;
revoke all on function public.heartbeat() from public;
grant execute on function public.my_offices() to authenticated;
grant execute on function public.join_office(text, text), public.undo_last(text, int, text) to authenticated;
grant execute on function public.heartbeat() to anon, authenticated;

-- ---------- živé změny (realtime) ----------
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
  begin alter publication supabase_realtime add table public.players; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.games;   exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.throws;  exception when duplicate_object then null; end;
end $$;

-- ---------- založení kanceláře (jen správce) ----------
-- Kód: 8–12 velkých písmen/číslic. Spusť jednou, s vlastním kódem:
-- insert into public.offices(code) values ('TK4GYTHFJT');
-- Seznam kanceláří:   select code, created_at from public.offices;
-- Zrušit kancelář:     delete from public.offices where code = 'KOD';   (smaže i její hráče a hry)
