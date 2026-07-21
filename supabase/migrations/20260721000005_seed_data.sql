-- MyPA — Migration 5: Seed Data
-- Ref: Technical Design Document (TDD) v1.3, Section 3.7b
-- Ref: Architecture Document v1.4, Section 6.1-6.2

-- ============================================================
-- AI Model Marketplace — all 8 launch providers
-- Rates are real July 2026 pricing at time of writing; immediately
-- superseded by the first run of the sync-model-pricing Edge Function
-- (TDD Section 6.1c) once deployed and scheduled. Do not treat these
-- as permanently fixed.
-- ============================================================
insert into ai_models (provider, display_name, openrouter_slug, is_free, input_rate_per_million, output_rate_per_million) values
  ('openai',           'OpenAI GPT-5.6 Terra',                  'openai/gpt-5.6-terra',        false, 2.50, 15.00),
  ('google_ai_studio', 'Google AI Studio (Gemini 3.5 Flash)',   'google/gemini-3.5-flash',     false, 1.50, 9.00),
  ('qwen',             'Qwen 3.6 Plus (hosted)',                'qwen/qwen3.6-plus',           false, 0.50, 3.00),
  ('huggingface',      'Hugging Face (Llama 3.3 70B pass-through)', 'meta-llama/llama-3.3-70b', false, 0.90, 0.90),
  ('llama',            'Llama 3.3 70B (hosted)',                'meta-llama/llama-3.3-70b',    false, 0.88, 0.88),
  ('deepseek',         'DeepSeek V4 Flash',                     'deepseek/deepseek-v4-flash',  false, 0.14, 0.28),
  ('mistral',          'Mistral Small',                         'mistralai/mistral-small',     false, 0.15, 0.60),
  ('gemma',            'Gemma (community/free-hosted)',         'google/gemma-2-9b',           true,  0.00, 0.00);

-- ============================================================
-- Platform Settings
-- ============================================================
insert into platform_settings (key, value) values
  ('credit_margin_multiplier', '1.0'),   -- 1.0 = no markup; adjust per commercial decision
  ('credit_usd_peg', '0.001'),           -- 1 credit = $0.001 raw provider cost
  ('default_max_output_tokens', '800');  -- pre-check cap default, TDD Section 5

-- ============================================================
-- System Prompt Library (starter set — see MyPA_Prompt_Library
-- and MyPA_Prompts documents in docs/05-user-docs/ for the full
-- documented collection; expand this seed to match as the app builds out)
-- ============================================================
insert into prompt_library (category, title, prompt_text, is_system) values
  ('engagement', 'Relatable question',
   'Write a short, casual social post that asks our audience a relatable question about [topic]. End with a direct question that invites comments.', true),
  ('engagement', 'Myth vs fact',
   'Write a short post correcting a common misconception about [topic], structured as ''Myth: ... Fact: ...'' and inviting people to share other myths they''ve heard.', true),
  ('sales', 'Limited-time offer',
   'Write a short, exciting post announcing a limited-time offer on [product/service]: [offer details]. Include urgency without sounding pushy.', true),
  ('sales', 'Problem-agitate-solve',
   'Write a promotional post for [product] using a problem to agitate to solve structure: name the problem [audience] faces, briefly agitate it, then introduce [product] as the solution.', true),
  ('awareness', 'Brand origin story',
   'Write a short, warm post telling the story of why [business] started, focused on the problem we set out to solve.', true),
  ('awareness', 'Educational tip post',
   'Write an educational post teaching our audience one useful tip about [topic related to our industry], written simply for a beginner.', true),
  ('brand_voice', 'Rewrite in our tone',
   'Rewrite this draft in our brand tone without changing the core message.', true);
