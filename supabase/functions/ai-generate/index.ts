/**
 * MyPA — POST /functions/v1/ai-generate
 * Ref: Technical Design Document v1.3, Section 5 (entitlement/billing logic)
 *      and Section 6.1 (contract).
 * Ref: Architecture Document v1.4, Section 6.3 (actual-usage credit billing).
 *
 * Free tier: always rejected (402) — no AI access at all, per BRD v1.1.
 * Pro/Business: pre-check cap based on max_output_tokens, then actual
 * per-call token usage is what's really charged (never the cap itself).
 *
 * The tier-check / pre-check-cap / actual-billing sequence lives in
 * _shared/billing.ts (generateWithBilling) so repurpose can reuse it for
 * its N-platforms-in-one-request case without duplicating this logic.
 */
import { corsHeaders, handleCorsPreflight, jsonResponse } from '../_shared/cors.ts';
import { createServiceRoleClient, createUserClient, getCallerUserId } from '../_shared/supabase.ts';
import { generateWithBilling } from '../_shared/billing.ts';

interface AiGenerateRequest {
  workspace_type: 'client' | 'team';
  workspace_id: string;
  prompt_id: string | null;
  input_text: string;
  goal: string;
  tone: string;
  ai_model_id: string;
  max_tokens?: number;
}

Deno.serve(async (req) => {
  const preflight = handleCorsPreflight(req);
  if (preflight) return preflight;

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405);
  }

  const userId = await getCallerUserId(req);
  if (!userId) {
    return jsonResponse({ error: 'unauthenticated' }, 401);
  }

  let body: AiGenerateRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'invalid_json_body' }, 400);
  }

  if (!body.workspace_id || !body.input_text || !body.ai_model_id) {
    return jsonResponse(
      { error: 'missing_required_field', required: ['workspace_id', 'input_text', 'ai_model_id'] },
      400,
    );
  }

  const userClient = createUserClient(req);
  const serviceClient = createServiceRoleClient();

  const { data: account, error: accountError } = await userClient
    .from('accounts')
    .select('id, subscriptions(tier)')
    .eq('owner_user_id', userId)
    .single();

  if (accountError || !account) {
    return jsonResponse({ error: 'account_not_found' }, 404);
  }

  const tier = (account as unknown as { subscriptions: { tier: string }[] }).subscriptions?.[0]
    ?.tier;

  const workspaceColumn: 'client_workspace_id' | 'team_workspace_id' =
    body.workspace_type === 'client' ? 'client_workspace_id' : 'team_workspace_id';

  // Create the content_items row as the calling user (RLS-enforced — fails
  // naturally if the caller doesn't belong to the target workspace,
  // TDD Section 4.3) before spending any credits, so a failed generation
  // never leaves an orphaned paid transaction with no content to show for it.
  const { data: contentItem, error: contentError } = await userClient
    .from('content_items')
    .insert({
      [workspaceColumn]: body.workspace_id,
      created_by: userId,
      goal: body.goal,
      tone: body.tone,
      source_text: body.input_text,
      ai_generated: true,
      status: 'draft',
    })
    .select('id')
    .single();

  if (contentError || !contentItem) {
    return jsonResponse({ error: 'content_item_creation_failed', detail: contentError?.message }, 500);
  }

  const promptText = [
    body.goal ? `Goal: ${body.goal}.` : '',
    body.tone ? `Tone: ${body.tone}.` : '',
    body.input_text,
  ]
    .filter(Boolean)
    .join(' ');

  const result = await generateWithBilling({
    userClient,
    serviceClient,
    accountId: account.id,
    tier,
    aiModelId: body.ai_model_id,
    prompt: promptText,
    maxOutputTokens: body.max_tokens,
    workspaceColumn,
    workspaceId: body.workspace_id,
    userId,
  });

  if (!result.ok) {
    return jsonResponse({ error: result.error, detail: result.detail }, result.status);
  }

  await userClient.from('content_items').update({ source_text: result.text }).eq('id', contentItem.id);

  return jsonResponse(
    {
      content_item_id: contentItem.id,
      draft_text: result.text,
      tokens_used: { prompt: result.promptTokens, completion: result.completionTokens },
      credits_used: result.creditsUsed,
      credits_remaining: result.creditsRemaining,
    },
    200,
    corsHeaders,
  );
});
