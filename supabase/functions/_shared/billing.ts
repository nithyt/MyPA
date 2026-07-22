/**
 * MyPA — Shared AI generation + actual-usage billing logic.
 * Ref: Technical Design Document v1.3, Section 5.
 * Ref: Architecture Document v1.4, Section 6.3.
 *
 * Factored out of ai-generate so that repurpose (which needs the same
 * tier-check / pre-check-cap / actual-billing sequence once per requested
 * platform) doesn't duplicate this logic.
 */
import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.45.4';
import { OpenRouterAdapter } from './ai-adapter.ts';

const DEFAULT_MAX_OUTPUT_TOKENS = 800;
const DEFAULT_ASSUMED_INPUT_TOKENS = 200;

export interface BillableGenerationParams {
  userClient: SupabaseClient;
  serviceClient: SupabaseClient;
  accountId: string;
  tier: string | undefined;
  aiModelId: string;
  prompt: string;
  maxOutputTokens?: number;
  /** Which workspace column to log against (TDD Section 3.6). */
  workspaceColumn: 'client_workspace_id' | 'team_workspace_id';
  workspaceId: string;
  userId: string;
}

export type BillableGenerationResult =
  | { ok: true; text: string; promptTokens: number; completionTokens: number; creditsUsed: number; creditsRemaining: number }
  | { ok: false; status: number; error: string; detail?: unknown };

/**
 * Runs the full tier-check -> pre-check-cap -> generate -> actual-billing
 * sequence for a single generation. Returns a discriminated result rather
 * than throwing, so callers (ai-generate for one call, repurpose for N
 * calls) can decide how to aggregate partial failures.
 */
export async function generateWithBilling(
  params: BillableGenerationParams,
): Promise<BillableGenerationResult> {
  const {
    userClient,
    serviceClient,
    accountId,
    tier,
    aiModelId,
    prompt,
    workspaceColumn,
    workspaceId,
    userId,
  } = params;
  const maxOutputTokens = params.maxOutputTokens ?? DEFAULT_MAX_OUTPUT_TOKENS;

  if (tier === 'free') {
    return { ok: false, status: 402, error: 'free_tier_not_eligible' };
  }

  const { data: model, error: modelError } = await userClient
    .from('ai_models')
    .select('id, is_free, input_rate_per_million, output_rate_per_million')
    .eq('id', aiModelId)
    .eq('is_active', true)
    .single();

  if (modelError || !model) {
    return { ok: false, status: 404, error: 'model_not_found' };
  }

  const { data: marginRow } = await userClient
    .from('platform_settings')
    .select('value')
    .eq('key', 'credit_margin_multiplier')
    .single();
  const marginMultiplier = marginRow ? parseFloat(marginRow.value) : 1.0;

  const { data: peggRow } = await userClient
    .from('platform_settings')
    .select('value')
    .eq('key', 'credit_usd_peg')
    .single();
  const creditUsdPeg = peggRow ? parseFloat(peggRow.value) : 0.001;

  function computeCredits(promptTokens: number, completionTokens: number): number {
    if (model!.is_free) return 0;
    const rawCost =
      (promptTokens / 1_000_000) * model!.input_rate_per_million +
      (completionTokens / 1_000_000) * model!.output_rate_per_million;
    const credits = Math.ceil((rawCost * marginMultiplier) / creditUsdPeg);
    return credits < 1 ? 1 : credits;
  }

  const maxPossibleCost = computeCredits(DEFAULT_ASSUMED_INPUT_TOKENS, maxOutputTokens);

  if (maxPossibleCost > 0) {
    const { data: credits, error: creditsError } = await userClient
      .from('account_credits')
      .select('balance')
      .eq('account_id', accountId)
      .single();

    if (creditsError || !credits) {
      return { ok: false, status: 404, error: 'credits_not_found' };
    }
    if (credits.balance < maxPossibleCost) {
      return {
        ok: false,
        status: 402,
        error: 'insufficient_credits',
        detail: { required: maxPossibleCost, balance: credits.balance },
      };
    }
  }

  const { data: fullModel } = await serviceClient
    .from('ai_models')
    .select('openrouter_slug')
    .eq('id', aiModelId)
    .single();

  if (!fullModel?.openrouter_slug) {
    return { ok: false, status: 500, error: 'model_not_routable' };
  }

  const adapter = new OpenRouterAdapter();
  let result;
  try {
    result = await adapter.generate(fullModel.openrouter_slug, prompt, { maxOutputTokens });
  } catch (err) {
    return { ok: false, status: 500, error: 'upstream_error', detail: String(err) };
  }

  const actualCost = computeCredits(result.promptTokens, result.completionTokens);

  const { data: currentCredits } = await serviceClient
    .from('account_credits')
    .select('balance')
    .eq('account_id', accountId)
    .single();

  let creditsRemaining = currentCredits?.balance ?? 0;
  if (actualCost > 0) {
    creditsRemaining = (currentCredits?.balance ?? 0) - actualCost;
    await serviceClient
      .from('account_credits')
      .update({ balance: creditsRemaining, updated_at: new Date().toISOString() })
      .eq('account_id', accountId);

    await serviceClient.from('credit_transactions').insert({
      account_id: accountId,
      amount: -actualCost,
      reason: 'generation',
    });
  }

  await serviceClient.from('ai_generation_logs').insert({
    account_id: accountId,
    user_id: userId,
    [workspaceColumn]: workspaceId,
    ai_model_id: aiModelId,
    tokens_used: result.promptTokens + result.completionTokens,
    credits_used: actualCost,
  });

  return {
    ok: true,
    text: result.text,
    promptTokens: result.promptTokens,
    completionTokens: result.completionTokens,
    creditsUsed: actualCost,
    creditsRemaining,
  };
}
