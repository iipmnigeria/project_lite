-- ProjectLite production MVP schema
-- Run this complete script once in Supabase Dashboard > SQL Editor.

create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','admin','project_manager','cost_controller','member','viewer')),
  team text not null default 'Delivery',
  joined_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  name text not null,
  code text not null,
  description text not null default '',
  status text not null default 'planning' check (status in ('planning','active','on_hold','completed','archived')),
  budget numeric(18,2) not null default 0,
  start_date date,
  finish_date date,
  project_data jsonb not null default '{"tasks":[],"changes":[],"activities":[]}'::jsonb,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, code)
);

create table if not exists public.workspace_invitations (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  email text not null,
  role text not null default 'member' check (role in ('admin','project_manager','cost_controller','member','viewer')),
  team text not null default 'Delivery',
  status text not null default 'pending' check (status in ('pending','accepted','revoked')),
  invited_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  unique (workspace_id, email)
);

create index if not exists projects_workspace_idx on public.projects(workspace_id);
create index if not exists members_user_idx on public.workspace_members(user_id);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.create_workspace(workspace_name text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  new_id uuid;
  base_slug text;
begin
  base_slug := lower(regexp_replace(trim(workspace_name), '[^a-zA-Z0-9]+', '-', 'g'));
  insert into public.workspaces (name, slug, created_by)
  values (trim(workspace_name), trim(both '-' from base_slug) || '-' || substr(gen_random_uuid()::text,1,6), auth.uid())
  returning id into new_id;
  insert into public.workspace_members (workspace_id, user_id, role, team)
  values (new_id, auth.uid(), 'owner', 'Management');
  return new_id;
end;
$$;

alter table public.profiles enable row level security;
alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.projects enable row level security;
alter table public.workspace_invitations enable row level security;

create or replace function public.is_workspace_member(target_workspace uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists(select 1 from public.workspace_members where workspace_id=target_workspace and user_id=auth.uid());
$$;

create or replace function public.workspace_role(target_workspace uuid)
returns text language sql security definer stable set search_path = public as $$
  select role from public.workspace_members where workspace_id=target_workspace and user_id=auth.uid() limit 1;
$$;

drop policy if exists "profiles readable by authenticated users" on public.profiles;
create policy "profiles readable by authenticated users" on public.profiles for select to authenticated using (true);
drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "members view workspaces" on public.workspaces;
create policy "members view workspaces" on public.workspaces for select to authenticated
using (public.is_workspace_member(id));

drop policy if exists "members view memberships" on public.workspace_members;
create policy "members view memberships" on public.workspace_members for select to authenticated
using (user_id=auth.uid() or public.is_workspace_member(workspace_id));

drop policy if exists "owners manage memberships" on public.workspace_members;
create policy "owners manage memberships" on public.workspace_members for all to authenticated
using (public.workspace_role(workspace_id) in ('owner','admin'))
with check (public.workspace_role(workspace_id) in ('owner','admin'));

drop policy if exists "members view projects" on public.projects;
create policy "members view projects" on public.projects for select to authenticated
using (public.is_workspace_member(workspace_id));
drop policy if exists "project managers create projects" on public.projects;
create policy "project managers create projects" on public.projects for insert to authenticated
with check (created_by=auth.uid() and public.workspace_role(workspace_id) in ('owner','admin','project_manager'));
drop policy if exists "project teams update projects" on public.projects;
create policy "project teams update projects" on public.projects for update to authenticated
using (public.workspace_role(workspace_id) <> 'viewer')
with check (public.workspace_role(workspace_id) <> 'viewer');
drop policy if exists "admins delete projects" on public.projects;
create policy "admins delete projects" on public.projects for delete to authenticated
using (public.workspace_role(workspace_id) in ('owner','admin'));

drop policy if exists "members view invitations" on public.workspace_invitations;
create policy "members view invitations" on public.workspace_invitations for select to authenticated
using (public.is_workspace_member(workspace_id));
drop policy if exists "admins manage invitations" on public.workspace_invitations;
create policy "admins manage invitations" on public.workspace_invitations for all to authenticated
using (public.workspace_role(workspace_id) in ('owner','admin'))
with check (invited_by=auth.uid() and public.workspace_role(workspace_id) in ('owner','admin'));

grant execute on function public.create_workspace(text) to authenticated;
grant execute on function public.is_workspace_member(uuid) to authenticated;
grant execute on function public.workspace_role(uuid) to authenticated;
