-- MyPA — Migration 4: Indexes & Performance
-- Ref: Technical Design Document (TDD) v1.3, Section 10

-- Every RLS policy and common query filters on these workspace columns
create index idx_content_items_client_ws on content_items (client_workspace_id);
create index idx_content_items_team_ws on content_items (team_workspace_id);
create index idx_content_platform_versions_content_item on content_platform_versions (content_item_id);
create index idx_social_connections_client_ws on social_connections (client_workspace_id);
create index idx_social_connections_team_ws on social_connections (team_workspace_id);
create index idx_brand_assets_client_ws on brand_assets (client_workspace_id);
create index idx_brand_assets_team_ws on brand_assets (team_workspace_id);

-- Usage analytics and audit lookups
create index idx_ai_generation_logs_account_created on ai_generation_logs (account_id, created_at);

-- Scheduler job that triggers due publishes
create index idx_content_platform_versions_scheduled on content_platform_versions (scheduled_at)
  where status = 'scheduled';

-- Ads: partial index keeps the active-ads lookup fast without scanning expired rows
create index idx_ads_active_window on ads (placement, starts_at, ends_at) where is_active;

-- account_credits is already keyed by account_id (primary key) — O(1) balance lookups
-- on the hottest path in the credit system, no additional index needed.

-- Workspace membership lookups (used in nearly every RLS policy)
create index idx_client_workspaces_consultant on client_workspaces (consultant_account_id);
create index idx_client_workspace_collab_user on client_workspace_collaborators (user_id);
create index idx_team_workspaces_business on team_workspaces (business_account_id);
create index idx_team_members_user on team_members (user_id);
