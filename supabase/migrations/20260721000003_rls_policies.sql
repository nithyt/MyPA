-- MyPA — Migration 3: Row Level Security Policies
-- Ref: Technical Design Document (TDD) v1.3, Section 4

-- ============================================================
-- 4.1 Client Workspaces — consultant owner + optional collaborators
-- ============================================================
alter table client_workspaces enable row level security;

create policy client_workspace_access on client_workspaces
  for all using (
    consultant_account_id in (
      select id from accounts where owner_user_id = auth.uid()
    )
    or id in (
      select client_workspace_id from client_workspace_collaborators
      where user_id = auth.uid()
    )
  );

alter table client_workspace_collaborators enable row level security;
create policy client_workspace_collaborators_access on client_workspace_collaborators
  for select using (
    user_id = auth.uid()
    or client_workspace_id in (
      select id from client_workspaces where consultant_account_id in (
        select id from accounts where owner_user_id = auth.uid()
      )
    )
  );

-- ============================================================
-- 4.2 Team Workspaces — role-based membership
-- ============================================================
alter table team_workspaces enable row level security;

create policy team_workspace_access on team_workspaces
  for select using (
    id in (select team_workspace_id from team_members where user_id = auth.uid())
  );

-- Writes restricted to admin/manager roles
create policy team_workspace_write on team_workspaces
  for update using (
    id in (
      select team_workspace_id from team_members
      where user_id = auth.uid() and role in ('admin', 'manager')
    )
  );

-- A business account owner can create a new team workspace
create policy team_workspace_insert on team_workspaces
  for insert with check (
    business_account_id in (select id from accounts where owner_user_id = auth.uid())
  );

-- Only an admin member can delete the workspace
create policy team_workspace_delete on team_workspaces
  for delete using (
    id in (
      select team_workspace_id from team_members
      where user_id = auth.uid() and role = 'admin'
    )
  );

-- Bootstrap problem: team_members_write (below) requires an existing admin/manager
-- row to insert a new one — but the very first member of a brand-new team_workspace
-- has no such row yet. Resolve this with a trigger that auto-adds the creating
-- business account's owner as 'admin' the moment a team_workspace is inserted,
-- rather than relying on a client-side insert into team_members for that first row.
create or replace function fn_bootstrap_team_admin()
returns trigger as $$
begin
  insert into team_members (team_workspace_id, user_id, role)
  select new.id, a.owner_user_id, 'admin'
  from accounts a
  where a.id = new.business_account_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_bootstrap_team_admin
  after insert on team_workspaces
  for each row execute function fn_bootstrap_team_admin();

alter table team_members enable row level security;
create policy team_members_access on team_members
  for select using (
    team_workspace_id in (select team_workspace_id from team_members where user_id = auth.uid())
  );
create policy team_members_write on team_members
  for all using (
    team_workspace_id in (
      select team_workspace_id from team_members
      where user_id = auth.uid() and role in ('admin', 'manager')
    )
  );

-- ============================================================
-- 4.3 Content Items — derived from whichever workspace it belongs to
-- ============================================================
alter table content_items enable row level security;

create policy content_items_access on content_items
  for all using (
    (client_workspace_id is not null and client_workspace_id in (
      select id from client_workspaces where consultant_account_id in (
        select id from accounts where owner_user_id = auth.uid()
      )
      union
      select client_workspace_id from client_workspace_collaborators
      where user_id = auth.uid()
    ))
    or
    (team_workspace_id is not null and team_workspace_id in (
      select team_workspace_id from team_members where user_id = auth.uid()
    ))
  );

-- content_platform_versions, approval_requests: derived via content_items join
alter table content_platform_versions enable row level security;
create policy content_platform_versions_access on content_platform_versions
  for all using (
    content_item_id in (select id from content_items)  -- content_items RLS already filters visibility
  );

alter table approval_requests enable row level security;
create policy approval_requests_access on approval_requests
  for all using (
    content_item_id in (select id from content_items)
  );

-- social_connections, brand_assets: same workspace-membership predicate pattern
alter table social_connections enable row level security;
create policy social_connections_access on social_connections
  for all using (
    (client_workspace_id is not null and client_workspace_id in (
      select id from client_workspaces where consultant_account_id in (
        select id from accounts where owner_user_id = auth.uid()
      )
      union
      select client_workspace_id from client_workspace_collaborators
      where user_id = auth.uid()
    ))
    or
    (team_workspace_id is not null and team_workspace_id in (
      select team_workspace_id from team_members where user_id = auth.uid()
    ))
  );

alter table brand_assets enable row level security;
create policy brand_assets_access on brand_assets
  for all using (
    (client_workspace_id is not null and client_workspace_id in (
      select id from client_workspaces where consultant_account_id in (
        select id from accounts where owner_user_id = auth.uid()
      )
      union
      select client_workspace_id from client_workspace_collaborators
      where user_id = auth.uid()
    ))
    or
    (team_workspace_id is not null and team_workspace_id in (
      select team_workspace_id from team_members where user_id = auth.uid()
    ))
  );

-- ============================================================
-- 4.4 Ads & AI Models — public read, admin write
-- ============================================================
alter table ads enable row level security;
alter table ai_models enable row level security;

-- Any authenticated user can read active ads / the model catalog
create policy ads_public_read on ads
  for select using (is_active and now() between starts_at and ends_at);

create policy ai_models_public_read on ai_models
  for select using (is_active);

-- Writes restricted to a platform-level admin claim (not a workspace role)
create policy ads_admin_write on ads
  for all using (coalesce(auth.jwt() ->> 'platform_role', '') = 'admin');

create policy ai_models_admin_write on ai_models
  for all using (coalesce(auth.jwt() ->> 'platform_role', '') = 'admin');

-- ============================================================
-- Accounts, subscriptions, credits, logs — owner-only access
-- ============================================================
alter table accounts enable row level security;
create policy accounts_owner_access on accounts
  for all using (owner_user_id = auth.uid());

-- Bootstrap: every new account gets a Free subscription row and a zero-balance
-- credits row automatically, rather than requiring the client to insert them
-- (subscriptions/account_credits have no client-facing insert policy by design —
-- tier changes and credit top-ups are handled by billing logic, not direct writes).
create or replace function fn_bootstrap_account_defaults()
returns trigger as $$
begin
  insert into subscriptions (account_id, tier, status) values (new.id, 'free', 'active');
  insert into account_credits (account_id, balance) values (new.id, 0);
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_bootstrap_account_defaults
  after insert on accounts
  for each row execute function fn_bootstrap_account_defaults();

alter table subscriptions enable row level security;
create policy subscriptions_owner_access on subscriptions
  for select using (
    account_id in (select id from accounts where owner_user_id = auth.uid())
  );

alter table account_credits enable row level security;
create policy account_credits_owner_access on account_credits
  for select using (
    account_id in (select id from accounts where owner_user_id = auth.uid())
  );

alter table credit_transactions enable row level security;
create policy credit_transactions_owner_access on credit_transactions
  for select using (
    account_id in (select id from accounts where owner_user_id = auth.uid())
  );

alter table ai_generation_logs enable row level security;
create policy ai_generation_logs_owner_access on ai_generation_logs
  for select using (
    account_id in (select id from accounts where owner_user_id = auth.uid())
  );

alter table publish_logs enable row level security;
create policy publish_logs_access on publish_logs
  for select using (
    content_platform_version_id in (select id from content_platform_versions)
  );

alter table prompt_library enable row level security;
create policy prompt_library_read on prompt_library
  for select using (
    is_system = true
    or account_id in (select id from accounts where owner_user_id = auth.uid())
  );
create policy prompt_library_write_own on prompt_library
  for all using (
    account_id in (select id from accounts where owner_user_id = auth.uid())
  );

-- platform_settings: readable by any authenticated user (needed client-side for
-- e.g. displaying margin-inclusive credit estimates), admin-write only
alter table platform_settings enable row level security;
create policy platform_settings_read on platform_settings
  for select using (auth.uid() is not null);
create policy platform_settings_admin_write on platform_settings
  for all using (coalesce(auth.jwt() ->> 'platform_role', '') = 'admin');
