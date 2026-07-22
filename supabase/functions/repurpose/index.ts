/**
 * MyPA — POST /functions/v1/repurpose
 * Ref: Technical Design Document v1.3, Section 6.2
 * Ref: Architecture Document v1.4, Section 8 (platform adaptation)
 * Ref: Prompt Library document, Section 5 (per-platform adaptation prompts —
 *      the PLATFORM_PROMPTS below mirror those exactly).
 *
 * Runs one generateWithBilling() call per requested platform, so credits
 * are spent per platform (an honest reflection of N separate LLM calls,
 * not a bulk discount). A partial failure (e.g. insufficient credits
 * partway through) still returns whichever platforms succeeded.
 */
import { corsHeaders, handleCorsPreflight, jsonResponse } from '../_shared/cors.ts';
import { createServiceRoleClient, createUserClient, getCallerUserId } from '../_shared/supabase.ts';
import { generateWithBilling } from '../_shared/billing.ts';

interface RepurposeRequest {
  content_item_id: string;
  ai_model_id: string;
  platforms: string[];
}

const PLATFORM_PROMPTS: Record<string, string> = {
  instagram:
    'Rewrite this content as an Instagram caption: conversational tone, relevant emojis, and 3-5 relevant hashtags at the end.',
  facebook:
    'Rewrite this content as a Facebook post: conversational, slightly longer-form than Instagram, minimal hashtags.',
  linkedin:
    'Rewrite this content as a LinkedIn post: slightly longer-form, professional tone, a clear takeaway in the first two lines (since LinkedIn truncates), no more than 1-2 hashtags.',
  x: 'Rewrite this content as a single X post under 280 characters: punchy, one clear idea, at most one hashtag.',
  tiktok:
    'Turn this content into a short-form video concept for TikTok: a 3-second hook, a suggested on-screen text overlay, and a one-line caption.',
  youtube:
    'Turn this content into a YouTube video title (under 60 characters) and a 2-3 sentence description optimized for search.',
};

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

  let body: RepurposeRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'invalid_json_body' }, 400);
  }

  if (!body.content_item_id || !body.ai_model_id || !body.platforms?.length) {
    return jsonResponse(
      { error: 'missing_required_field', required: ['content_item_id', 'ai_model_id', 'platforms'] },
      400,
    );
  }

  const unknownPlatforms = body.platforms.filter((p) => !(p in PLATFORM_PROMPTS));
  if (unknownPlatforms.length > 0) {
    return jsonResponse({ error: 'unknown_platform', platforms: unknownPlatforms }, 400);
  }

  const userClient = createUserClient(req);
  const serviceClient = createServiceRoleClient();

  // RLS-enforced read — 404s naturally if the caller doesn't belong to the
  // owning workspace (TDD Section 4.3).
  const { data: contentItem, error: contentError } = await userClient
    .from('content_items')
    .select('id, source_text, client_workspace_id, team_workspace_id')
    .eq('id', body.content_item_id)
    .single();

  if (contentError || !contentItem) {
    return jsonResponse({ error: 'content_item_not_found' }, 404);
  }

  const workspaceColumn: 'client_workspace_id' | 'team_workspace_id' = contentItem.client_workspace_id
    ? 'client_workspace_id'
    : 'team_workspace_id';
  const workspaceId = contentItem.client_workspace_id ?? contentItem.team_workspace_id;

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

  const versions: Array<{ platform: string; body_text?: string; status: string; error?: string }> = [];

  for (const platform of body.platforms) {
    const prompt = `${PLATFORM_PROMPTS[platform]}\n\nOriginal content: ${contentItem.source_text}`;

    const result = await generateWithBilling({
      userClient,
      serviceClient,
      accountId: account.id,
      tier,
      aiModelId: body.ai_model_id,
      prompt,
      workspaceColumn,
      workspaceId: workspaceId as string,
      userId,
    });

    if (!result.ok) {
      versions.push({ platform, status: 'failed', error: result.error });
      continue;
    }

    const { error: insertError } = await userClient.from('content_platform_versions').insert({
      content_item_id: contentItem.id,
      platform,
      body_text: result.text,
      status: 'draft',
    });

    versions.push({
      platform,
      body_text: result.text,
      status: insertError ? 'failed' : 'draft',
      error: insertError?.message,
    });
  }

  return jsonResponse({ versions }, 200, corsHeaders);
});
