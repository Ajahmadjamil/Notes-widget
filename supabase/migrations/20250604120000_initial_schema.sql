-- Notes Widget App — initial Supabase schema
-- Run via: Supabase SQL Editor, or `supabase db push` after `supabase link`

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Profiles (replaces RTDB /users/{uid} + /usernames + /emails indexes)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text unique,
  username text unique,
  display_name text,
  photo_url text,
  fcm_token text,
  fcm_token_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format check (
    username is null
    or (
      char_length(username) between 3 and 20
      and username ~ '^[a-z0-9_]+$'
    )
  )
);

create index profiles_email_lower_idx on public.profiles (lower(email));
create index profiles_username_lower_idx on public.profiles (lower(username));

comment on table public.profiles is 'App user profile; one row per auth.users.id';

-- Auto-create profile row on sign-up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name, photo_url)
  values (
    new.id,
    lower(trim(new.email)),
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do update set
    email = coalesce(excluded.email, public.profiles.email),
    display_name = coalesce(excluded.display_name, public.profiles.display_name),
    photo_url = coalesce(excluded.photo_url, public.profiles.photo_url),
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep updated_at fresh
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Personal notes cloud backup (replaces RTDB /notes/{uid}/{noteId})
-- SQLite remains primary offline store in the app.
-- ---------------------------------------------------------------------------
create table public.personal_notes (
  id text not null,
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null default '',
  body text not null default '',
  created_at bigint not null,
  updated_at bigint not null,
  primary key (user_id, id)
);

create index personal_notes_user_updated_idx
  on public.personal_notes (user_id, updated_at desc);

-- ---------------------------------------------------------------------------
-- Friendships (replaces /friendRequests + symmetric /friends/{uid}/{friendUid})
-- Pending: requester = user_id, recipient = friend_id
-- Accepted: same row, status = accepted, plus one shared_notes row
-- ---------------------------------------------------------------------------
create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  friend_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  constraint friendships_no_self check (user_id <> friend_id),
  constraint friendships_unique_pair unique (user_id, friend_id)
);

create index friendships_user_id_status_idx
  on public.friendships (user_id, status);

create index friendships_friend_id_status_idx
  on public.friendships (friend_id, status);

create index friendships_accepted_members_idx
  on public.friendships (status)
  where status = 'accepted';

-- ---------------------------------------------------------------------------
-- Shared notes — one note per accepted friendship (replaces /sharedNotes/{pairId})
-- ---------------------------------------------------------------------------
create table public.shared_notes (
  id uuid primary key default gen_random_uuid(),
  friendship_id uuid not null unique references public.friendships (id) on delete cascade,
  title text not null default 'Shared note',
  body text not null default '',
  updated_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger shared_notes_set_updated_at
  before update on public.shared_notes
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- RLS helpers
-- ---------------------------------------------------------------------------
create or replace function public.is_friendship_member(p_friendship_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.friendships f
    where f.id = p_friendship_id
      and f.status = 'accepted'
      and (f.user_id = auth.uid() or f.friend_id = auth.uid())
  );
$$;

create or replace function public.friendship_involves_me(p_user_id uuid, p_friend_id uuid)
returns boolean
language sql
stable
as $$
  select auth.uid() in (p_user_id, p_friend_id);
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.personal_notes enable row level security;
alter table public.friendships enable row level security;
alter table public.shared_notes enable row level security;

-- Profiles: any signed-in user can read (friend search); only own row writable
create policy "profiles_select_authenticated"
  on public.profiles for select
  to authenticated
  using (true);

create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Personal notes: owner only
create policy "personal_notes_all_own"
  on public.personal_notes for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Friendships: see rows you are part of; create outgoing requests; update as recipient
create policy "friendships_select_involved"
  on public.friendships for select
  to authenticated
  using (public.friendship_involves_me(user_id, friend_id));

create policy "friendships_insert_requester"
  on public.friendships for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and status = 'pending'
  );

create policy "friendships_update_involved"
  on public.friendships for update
  to authenticated
  using (public.friendship_involves_me(user_id, friend_id))
  with check (public.friendship_involves_me(user_id, friend_id));

create policy "friendships_delete_involved"
  on public.friendships for delete
  to authenticated
  using (public.friendship_involves_me(user_id, friend_id));

-- Shared notes: only members of the accepted friendship
create policy "shared_notes_select_member"
  on public.shared_notes for select
  to authenticated
  using (public.is_friendship_member(friendship_id));

create policy "shared_notes_insert_member"
  on public.shared_notes for insert
  to authenticated
  with check (public.is_friendship_member(friendship_id));

create policy "shared_notes_update_member"
  on public.shared_notes for update
  to authenticated
  using (public.is_friendship_member(friendship_id))
  with check (public.is_friendship_member(friendship_id));

-- ---------------------------------------------------------------------------
-- Realtime (replaces RTDB onValue on /sharedNotes)
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table public.shared_notes;

-- Optional: live friend request inbox
alter publication supabase_realtime add table public.friendships;

-- ---------------------------------------------------------------------------
-- Accept friend request: creates shared_notes in one transaction
-- Call from Flutter via supabase.rpc('accept_friend_request', {'p_friendship_id': ...})
-- ---------------------------------------------------------------------------
create or replace function public.accept_friend_request(p_friendship_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_friendship public.friendships%rowtype;
  v_note_id uuid;
begin
  select * into v_friendship
  from public.friendships
  where id = p_friendship_id
    and status = 'pending'
    and friend_id = auth.uid()
  for update;

  if not found then
    raise exception 'Friend request not found or not addressed to you';
  end if;

  update public.friendships
  set status = 'accepted', accepted_at = now()
  where id = p_friendship_id;

  insert into public.shared_notes (friendship_id, title, body, updated_by)
  values (p_friendship_id, 'Shared note', '', auth.uid())
  returning id into v_note_id;

  return v_note_id;
end;
$$;

grant execute on function public.accept_friend_request(uuid) to authenticated;

-- Search helper (replaces base64 email index + username index)
create or replace function public.search_profile(p_query text)
returns setof public.profiles
language sql
stable
security definer
set search_path = public
as $$
  select p.*
  from public.profiles p
  where
    auth.uid() is not null
    and (
      (p_query like '%@%' and lower(p.email) = lower(trim(p_query)))
      or (
        p_query not like '%@%'
        and lower(p.username) = lower(trim(both '@' from p_query))
      )
    )
  limit 1;
$$;

grant execute on function public.search_profile(text) to authenticated;
