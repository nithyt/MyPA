-- MyPA — Migration 2: Core Schema
-- Ref: Technical Design Document (TDD) v1.3, Section 3

-- ============================================================
-- 3.1 Accounts & Subscriptions
-- ============================================================
create table accounts (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id),
  account_type account_type not null,
  display_name text not null,
  created_at timestamptz not null default now()
);

create table subscriptions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references accounts(id) on delete cascade,
  tier subscription_tier not null default 'free',
  status text not null default 'active',
  current_period_end timestamptz,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 3.2 Consultant-Client Workspace Model
-- ============================================================
create table client_workspaces (
  id uuid primary key default gen_random_uuid(),
  consultant_account_id uuid not null references accounts(id) on delete cascade,
  client_name text not null,
  brand_tone text,
  created_at timestamptz not null default now()
);

create table client_workspace_collaborators (
  client_workspace_id uuid not null references client_workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  added_at timestamptz not null default now(),
  primary key (client_workspace_id, user_id)
);

-- ============================================================
-- 3.3 Business-Team Workspace Model
-- ============================================================
create table team_workspaces (
  id uuid primary key default gen_random_uuid(),
  business_account_id uuid not null references accounts(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create table team_members (
  team_workspace_id uuid not null references team_workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  role team_role not null default 'contributor',
  invited_at timestamptz not null default now(),
  primary key (team_workspace_id, user_id)
);

-- ============================================================
-- 3.4 Content & Publishing
-- ============================================================
create table content_items (
  id uuid primary key default gen_random_uuid(),
  client_workspace_id uuid references client_workspaces(id) on delete cascade,
  team_workspace_id uuid references team_workspaces(id) on delete cascade,
  created_by uuid not null references auth.users(id),
  goal text,               -- 'engagement' | 'sales' | 'awareness' | 'brand_voice'
  tone text,
  source_text text,
  ai_generated boolean not null default false,
  status content_status not null default 'draft',
  created_at timestamptz not null default now(),
  constraint content_items_one_workspace_only check (
    (client_workspace_id is not null)::int + (team_workspace_id is not null)::int = 1
  )
);

create table content_platform_versions (
  id uuid primary key default gen_random_uuid(),
  content_item_id uuid not null references content_items(id) on delete cascade,
  platform social_platform not null,
  body_text text,
  media_url text,
  scheduled_at timestamptz,
  published_at timestamptz,
  platform_post_id text,
  status content_status not null default 'draft',
  created_at timestamptz not null default now()
);

create table approval_requests (
  id uuid primary key default gen_random_uuid(),
  content_item_id uuid not null references content_items(id) on delete cascade,
  requested_by uuid not null references auth.users(id),
  status text not null default 'pending',  -- 'pending' | 'approved' | 'rejected'
  approver_id uuid references auth.users(id),
  decided_at timestamptz,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 3.5 Social Connections, Brand Assets, Prompts
-- ============================================================
create table social_connections (
  id uuid primary key default gen_random_uuid(),
  client_workspace_id uuid references client_workspaces(id) on delete cascade,
  team_workspace_id uuid references team_workspaces(id) on delete cascade,
  platform social_platform not null,
  access_token_encrypted text not null,
  refresh_token_encrypted text,
  connected_by uuid not null references auth.users(id),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  constraint social_connections_one_workspace_only check (
    (client_workspace_id is not null)::int + (team_workspace_id is not null)::int = 1
  )
);

create table brand_assets (
  id uuid primary key default gen_random_uuid(),
  client_workspace_id uuid references client_workspaces(id) on delete cascade,
  team_workspace_id uuid references team_workspaces(id) on delete cascade,
  asset_type text not null,  -- 'logo' | 'color' | 'font' | 'tone_guide'
  storage_path text,
  value text,
  created_at timestamptz not null default now()
);

create table prompt_library (
  id uuid primary key default gen_random_uuid(),
  category text not null,     -- 'engagement' | 'sales' | 'awareness' | 'brand_voice'
  title text not null,
  prompt_text text not null,
  is_system boolean not null default true,
  account_id uuid references accounts(id),  -- null for system-wide prompts
  created_at timestamptz not null default now()
);

-- ============================================================
-- 3.7 AI Model Marketplace & Credits (Architecture v1.4)
-- ============================================================
create table ai_models (
  id uuid primary key default gen_random_uuid(),
  provider text not null,       -- 'openai' | 'google_ai_studio' | 'huggingface' |
                                 -- 'llama' | 'qwen' | 'deepseek' | 'mistral' | 'gemma'
  display_name text not null,   -- e.g. 'OpenAI GPT-5.6 Terra'
  openrouter_slug text,          -- e.g. 'openai/gpt-4o' -- null only for a direct-adapter fallback
  is_free boolean not null default false,
  input_rate_per_million numeric(10,4) not null default 0,   -- USD, synced from OpenRouter
  output_rate_per_million numeric(10,4) not null default 0,  -- USD, synced from OpenRouter
  last_synced_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table account_credits (
  account_id uuid primary key references accounts(id) on delete cascade,
  balance int not null default 0,
  updated_at timestamptz not null default now()
);

-- ============================================================
-- 3.6 AI Usage, Publishing, and Approval Logs
-- (created after ai_models since it references it)
-- ============================================================
create table ai_generation_logs (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references accounts(id),
  user_id uuid not null references auth.users(id),
  client_workspace_id uuid references client_workspaces(id),
  team_workspace_id uuid references team_workspaces(id),
  ai_model_id uuid not null references ai_models(id),
  tokens_used int,
  credits_used int not null,
  created_at timestamptz not null default now()
);

create table publish_logs (
  id uuid primary key default gen_random_uuid(),
  content_platform_version_id uuid not null references content_platform_versions(id) on delete cascade,
  status text not null,       -- 'success' | 'failed'
  response_payload jsonb,
  created_at timestamptz not null default now()
);

create table credit_transactions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references accounts(id) on delete cascade,
  ai_generation_log_id uuid references ai_generation_logs(id),
  amount int not null,          -- negative for spend, positive for top-up/replenish
  reason text not null,         -- 'generation' | 'monthly_replenish' | 'purchase' | 'admin_adjustment'
  created_at timestamptz not null default now()
);

create table platform_settings (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

-- ============================================================
-- 3.8 Ads
-- ============================================================
create table ads (
  id uuid primary key default gen_random_uuid(),
  placement text not null,      -- 'top' | 'bottom'
  advertiser_name text,         -- internal campaign/advertiser label
  title text not null,
  body_text text,
  image_url text,
  target_url text,
  starts_at timestamptz not null,
  duration_days int not null,    -- the number entered by the admin, e.g. 1, 2, 7
  ends_at timestamptz not null,   -- computed by trg_compute_ads_end_date, TDD/Migration 3
  is_active boolean not null default true,   -- manual pause override, independent of dates
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  constraint ads_valid_placement check (placement in ('top', 'bottom')),
  constraint ads_valid_duration check (duration_days > 0)
);

-- ends_at cannot be a generated column: timestamptz + interval arithmetic is
-- STABLE (timezone-dependent), not IMMUTABLE, which Postgres generated columns
-- require. A trigger has no such restriction.
create or replace function fn_compute_ads_end_date()
returns trigger as $$
begin
  new.ends_at := new.starts_at + make_interval(days => new.duration_days);
  return new;
end;
$$ language plpgsql;

create trigger trg_compute_ads_end_date
  before insert or update of starts_at, duration_days on ads
  for each row execute function fn_compute_ads_end_date();
