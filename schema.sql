-- Marginalia / social reading annotations
-- Run this in your Supabase project: Dashboard -> SQL Editor -> New query -> paste -> Run

create extension if not exists "pgcrypto";

-- A book is just a title/author pair. No book text is stored here —
-- every excerpt a reader wants to discuss comes from the reader themselves,
-- attached directly to their comment.
create table books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author text,
  created_at timestamptz not null default now()
);

create table groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text not null unique,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  joined_at timestamptz not null default now(),
  unique (group_id, user_id)
);

create table comments (
  id uuid primary key default gen_random_uuid(),
  book_id uuid not null references books(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  group_id uuid references groups(id), -- null = visible to everyone
  anchor_text text not null,           -- the excerpt the reader is reacting to
  position_percent numeric not null,   -- 0-100, where this falls in the book
  body text not null,
  is_chapter_end boolean not null default false,
  created_at timestamptz not null default now()
);

create index on comments (book_id, position_percent);

-- ---------- Row Level Security ----------
-- This is what actually enforces "public comments vs. group-only comments" —
-- the client just queries comments for a book, and Postgres only returns
-- the rows this user is allowed to see.

alter table books enable row level security;
alter table groups enable row level security;
alter table group_members enable row level security;
alter table comments enable row level security;

create policy "books readable by signed-in users"
  on books for select using (auth.role() = 'authenticated');
create policy "books insertable by signed-in users"
  on books for insert with check (auth.role() = 'authenticated');

create policy "groups readable by members or creator"
  on groups for select using (
    created_by = auth.uid()
    or exists (select 1 from group_members gm where gm.group_id = groups.id and gm.user_id = auth.uid())
  );
create policy "groups insertable by their creator"
  on groups for insert with check (created_by = auth.uid());

create policy "memberships readable by self or group creator"
  on group_members for select using (
    user_id = auth.uid()
    or exists (select 1 from groups g where g.id = group_members.group_id and g.created_by = auth.uid())
  );
create policy "memberships insertable by self"
  on group_members for insert with check (user_id = auth.uid());

create policy "comments readable if public or member"
  on comments for select using (
    group_id is null
    or exists (select 1 from group_members gm where gm.group_id = comments.group_id and gm.user_id = auth.uid())
  );
create policy "comments insertable by their author"
  on comments for insert with check (user_id = auth.uid());

-- Joining a group by invite code has to bypass the "members only" read policy
-- above (you're not a member yet), so it's done through a function that
-- runs with elevated privileges instead of through a direct table query.
create or replace function join_group_by_code(code text)
returns groups
language plpgsql
security definer
set search_path = public
as $$
declare
  g groups;
begin
  select * into g from groups where invite_code = code;
  if g.id is null then
    raise exception 'No group found for that invite code';
  end if;
  insert into group_members (group_id, user_id)
  values (g.id, auth.uid())
  on conflict (group_id, user_id) do nothing;
  return g;
end;
$$;

grant execute on function join_group_by_code(text) to authenticated;
