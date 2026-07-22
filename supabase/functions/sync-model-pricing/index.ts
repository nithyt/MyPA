/**
 * MyPA — POST /functions/v1/sync-model-pricing (scheduled, not user-facing)
 * Ref: Technical Design Document v1.3, Section 6.1c
 * Ref: Architecture Document v1.4, Section 6.2 (Live Rate Sync)
 *
 * Triggered by a nightly schedule (see .github/workflows/sync-model-pricing.yml,
 * which curls this endpoint on a cron trigger — see that file for why GitHub
 * Actions is used here instead of pg_cron). Not called by the Flutter client.
 *
 * Pulls OpenRouter's public, unauthenticated pricing catalog and updates
 * every ai_models row that has a non-null openrouter_slug.
 */
import { jsonResponse } from '../_shared/cors.ts';
import { createServiceRoleClient } from '../_shared/supabase.ts';

const OPENROUTER_MODELS_URL = 'https://openrouter.ai/api/v1/models';

interface OpenRouterModel {
  id: string;
  pricing: {
    prompt: string; // USD per token, as a decimal string, e.g. "0.0000025"
    completion: string;
  };
}

Deno.serve(async (req) => {
  // This function is triggered by a scheduled GitHub Actions job with a
  // shared secret, not by end users — see the workflow file for the header
  // this checks.
  const cronSecret = req.headers.get('x-cron-secret');
  const expectedSecret = Deno.env.get('CRON_SHARED_SECRET') ?? '';
  if (!expectedSecret || cronSecret !== expectedSecret) {
    return jsonResponse({ error: 'unauthorized' }, 401);
  }

  const serviceClient = createServiceRoleClient();

  const { data: models, error: modelsError } = await serviceClient
    .from('ai_models')
    .select('id, openrouter_slug')
    .not('openrouter_slug', 'is', null);

  if (modelsError) {
    return jsonResponse({ error: 'db_error', detail: modelsError.message }, 500);
  }

  let openRouterCatalog: OpenRouterModel[];
  try {
    const response = await fetch(OPENROUTER_MODELS_URL);
    if (!response.ok) {
      throw new Error(`OpenRouter responded with ${response.status}`);
    }
    const body = await response.json();
    openRouterCatalog = body.data ?? [];
  } catch (err) {
    return jsonResponse({ error: 'openrouter_fetch_failed', detail: String(err) }, 502);
  }

  const catalogBySlug = new Map(openRouterCatalog.map((m) => [m.id, m]));

  let updated = 0;
  const notFound: string[] = [];
  const now = new Date().toISOString();

  for (const model of models ?? []) {
    const match = catalogBySlug.get(model.openrouter_slug as string);
    if (!match) {
      notFound.push(model.openrouter_slug as string);
      continue;
    }

    const promptRate = parseFloat(match.pricing.prompt) * 1_000_000;
    const completionRate = parseFloat(match.pricing.completion) * 1_000_000;
    const isFree = promptRate === 0 && completionRate === 0;

    const { error: updateError } = await serviceClient
      .from('ai_models')
      .update({
        input_rate_per_million: promptRate,
        output_rate_per_million: completionRate,
        is_free: isFree,
        last_synced_at: now,
      })
      .eq('id', model.id);

    if (!updateError) updated += 1;
  }

  return jsonResponse({ updated, not_found: notFound, synced_at: now }, 200);
});
