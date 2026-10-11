-- Apartment Shortlist: database setup for Supabase.
-- Run once in Supabase > SQL Editor. First replace the two emails and names at the bottom.

-- People allowed to open the shortlist.
create table if not exists public.members (
  email text primary key,
  name  text not null
);

-- One row per apartment; every field from the form lives in `data`.
create table if not exists public.apartments (
  id         uuid primary key default gen_random_uuid(),
  data       jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- One row per person, apartment and criterion (layout, location, vibe, noise).
create table if not exists public.ratings (
  apartment_id uuid not null references public.apartments(id) on delete cascade,
  rater        text not null,
  criterion    text not null,
  score        int  not null check (score between 1 and 5),
  updated_at   timestamptz not null default now(),
  primary key (apartment_id, rater, criterion)
);

-- Helpers ------------------------------------------------------------------
create or replace function public.my_email() returns text
language sql stable as $$ select lower(coalesce(auth.jwt() ->> 'email', '')) $$;

create or replace function public.is_member() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from members where lower(email) = my_email())
$$;

-- Have I rated this criterion yet? (Used to keep the partner's score hidden until then.)
create or replace function public.i_rated(apt uuid, crit text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from ratings where apartment_id = apt and criterion = crit and rater = my_email())
$$;

-- Which criteria someone else has rated, without revealing the score.
create or replace function public.others_rated() returns table (apartment_id uuid, criterion text)
language sql stable security definer set search_path = public as $$
  select distinct r.apartment_id, r.criterion from ratings r
  where is_member() and r.rater <> my_email()
$$;

revoke all on function public.is_member(), public.i_rated(uuid, text), public.others_rated() from public, anon;
grant execute on function public.my_email(), public.is_member(), public.i_rated(uuid, text), public.others_rated() to authenticated;

-- Row level security ---------------------------------------------------------
alter table public.members    enable row level security;
alter table public.apartments enable row level security;
alter table public.ratings    enable row level security;

drop policy if exists "members read" on public.members;
create policy "members read" on public.members for select to authenticated using (public.is_member());

drop policy if exists "apartments all" on public.apartments;
create policy "apartments all" on public.apartments for all to authenticated
  using (public.is_member()) with check (public.is_member());

drop policy if exists "ratings read" on public.ratings;
create policy "ratings read" on public.ratings for select to authenticated
  using (public.is_member() and (rater = public.my_email() or public.i_rated(apartment_id, criterion)));

drop policy if exists "ratings insert own" on public.ratings;
create policy "ratings insert own" on public.ratings for insert to authenticated
  with check (public.is_member() and rater = public.my_email());

drop policy if exists "ratings update own" on public.ratings;
create policy "ratings update own" on public.ratings for update to authenticated
  using (rater = public.my_email()) with check (rater = public.my_email());

drop policy if exists "ratings delete own" on public.ratings;
create policy "ratings delete own" on public.ratings for delete to authenticated
  using (rater = public.my_email());

-- Live updates between the two of you.
alter publication supabase_realtime add table public.apartments, public.ratings;

-- Who may sign in: REPLACE these two rows (lowercase emails) ----------------
insert into public.members (email, name) values
  ('julialimbekov@gmail.com', 'Yuliya'),
  ('lugovsky.v@gmail.com', 'Vlad')
on conflict (email) do update set name = excluded.name;
