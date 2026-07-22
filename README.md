# MyPA — Your Personal & Business AI Assistant

MyPA is a cross-platform AI and voice-enabled assistant, built with Flutter (Android, iOS, iPadOS, macOS, Windows) and Supabase (auth, database, storage, edge functions, realtime). The first delivered capability is the AI Social Media Marketing module.

**Current status: Phase 0 (Foundation) in progress.** The Supabase schema (all migrations) is written and verified against a real Postgres 16 instance. The Flutter app has a working skeleton — auth, routing, the Home screen shell (voice search, profile menu, database-driven ad banners, settings-driven bottom nav) — but most feature screens (Create, Library, Calendar, Admin) are intentionally-marked stubs, not yet implemented. See docs/01-business/ for the full Project Plan.

## Repository structure

```
MyPA/
├── app/                     Flutter application (skeleton implemented — see Status below)
│   ├── lib/
│   │   ├── core/             Supabase bootstrap, theme, router
│   │   ├── domain/entities/  Pure-Dart business entities
│   │   ├── data/repositories/  Supabase-facing data access
│   │   ├── application/providers/  Riverpod state
│   │   └── presentation/     Screens & widgets
│   └── test/
├── supabase/
│   └── migrations/           5 migrations: types, schema, RLS, indexes, seed data — verified
├── docs/                     All project documentation (see index below)
└── .github/workflows/        CI/CD pipelines (not yet implemented)
```

## Documentation index

| Folder | Contents |
|---|---|
| `docs/01-business/` | Business Requirements Document (BRD) v1.1, Project Plan & Release Roadmap |
| `docs/02-architecture/` | Architecture Document v1.4, Technical Design Document (TDD) v1.3 |
| `docs/03-design/` | Functional Design Document (FDD), Functional/Technical/Data Flow Diagrams |
| `docs/04-qa/` | Test Plan / QA Document |
| `docs/05-user-docs/` | User Guide, Prompt Library, Prompts, Tips & Tricks, Troubleshooting Guide, Common Issues, FAQ |
| `docs/06-environment/` | Environment Setup Guide — start here to set up a dev machine |

## Getting started (for developers)

Read `docs/06-environment/MyPA_Environment_Setup_v1.0.docx` first — it covers required accounts, local toolchain, repository setup, Supabase configuration, secrets management, and a verification checklist.

Then, to bring up what's already built:

```bash
# 1. Apply the database schema (already written and verified — see below)
cd supabase
supabase link --project-ref <your-project-ref>
supabase db push

# 2. Set Edge Function secrets (never commit these — see .gitignore)
supabase secrets set OPENROUTER_API_KEY=sk-or-...
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=eyJ...   # from project API settings
supabase secrets set CRON_SHARED_SECRET=$(openssl rand -hex 32)
# Social platform secrets (META_APP_SECRET, LINKEDIN_CLIENT_SECRET, etc.) can
# wait until each platform's developer approval is in hand — the adapters
# fail gracefully with a clear message until then.

# 3. Deploy Edge Functions (or let supabase-deploy.yml do this on push to main)
supabase functions deploy ai-generate
supabase functions deploy repurpose
supabase functions deploy publish
supabase functions deploy connect-social-account
supabase functions deploy team-invite
supabase functions deploy approve-content
supabase functions deploy sync-model-pricing --no-verify-jwt

# 4. Turn the app/ folder into a real Flutter project
cd ../app
flutter create . --project-name mypa --org com.yourcompany
flutter pub get
flutter analyze          # run this first — the code here was written
                          # without a local Flutter SDK to verify against
flutter test

# 5. Run it
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

**Note:** `flutter create .` will generate the platform folders (`android/`, `ios/`, `macos/`, `windows/`) and may create its own `pubspec.yaml`/`analysis_options.yaml` — keep the versions already in this repo (they're pre-configured with the correct dependencies and lint rules) rather than letting `flutter create` overwrite them.

## Status

- **Database (supabase/migrations/):** All 19 tables, RLS policies, indexes, and seed data written and verified end-to-end against a real Postgres 16 instance, including two bootstrap triggers (new accounts get a Free subscription + credit row; new team workspaces auto-add the creator as admin).
- **Edge Functions (supabase/functions/):** All 7 functions written — `ai-generate`, `repurpose`, `publish`, `connect-social-account`, `team-invite`, `approve-content`, `sync-model-pricing` — plus shared modules and the OpenRouter/social-platform adapters. All type-checked and linted clean with Deno. Social platform adapters (Meta, LinkedIn, X, TikTok, YouTube) are honest stubs pending each platform's developer API approval (see BRD v1.1 risk register) — the request/response shapes are real, the actual network calls throw a clear "not yet functional" error until real credentials and approval are in place.
- **App (app/lib/):** Working skeleton — Supabase-backed auth with routing redirects, the Home screen shell (voice search bar, profile menu, live database-driven ad banners top/bottom, settings-driven bottom nav), and Riverpod providers wired to real repositories. Verified clean with `flutter analyze` (0 issues) and `flutter test` (all passing) on a real Flutter 3.44.7 toolchain. Create, Library, Calendar, and Admin screens are marked stubs with TODOs pointing at the relevant FDD/TDD sections.
- **CI/CD (.github/workflows/):** Three workflows — `flutter-ci.yml` (analyze/test gate, then Android/Windows/macOS/iOS build jobs), `supabase-deploy.yml` (migrations + function deploys on push to main), `sync-model-pricing.yml` (nightly cron calling the pricing sync function). All validated with `actionlint`.
- **Not yet started:** real social platform app registrations/credentials, store submission/signing configuration, remaining feature screens (Create/Library/Calendar/Admin UI logic).

## Key architectural decisions (see Architecture Document v1.4 for full detail)

- Single Flutter codebase across all 6 target platforms; Riverpod for state management
- Supabase as the sole backend platform (no custom server)
- Multi-provider AI Model Marketplace (OpenAI, Google AI Studio, Hugging Face, Llama, Qwen, DeepSeek, Mistral, Gemma) routed through OpenRouter, billed on actual per-call token usage with live-synced pricing; Free tier has no AI access
- Separate data models for consultant-client workspaces vs. business-team workspaces
- Adapter pattern for both social platform integrations and AI providers
- Database-driven Ads module for Home screen promotional content
