/**
 * MyPA — POST /functions/v1/connect-social-account
 * Ref: Technical Design Document v1.3, Section 6.4
 *
 * Exchanges an OAuth authorization code for that platform's access/refresh
 * tokens via the matching adapter, then stores them encrypted. The actual
 * token exchange is delegated to each platform's connectAccount() — which,
 * per the adapter stubs in publish/adapters/, is not yet functional pending
 * each platform's own developer approval (see BRD v1.1 risk register).
 *
 * NOTE: access_token_encrypted / refresh_token_encrypted are stored as
 * received here; real encryption-at-rest (e.g. via Supabase Vault or
 * pgsodium) is an infrastructure detail not yet wired up — see Open
 * Architectural Decisions in the Architecture Document.
 */
import { corsHeaders, handleCorsPreflight, jsonResponse } from '../_shared/cors.ts';
import { createUserClient, getCallerUserId } from '../_shared/supabase.ts';
import { getAdapterForPlatform } from '../publish/adapters/index.ts';

interface ConnectRequest {
  workspace_type: 'client' | 'team';
  workspace_id: string;
  platform: string;
  oauth_code: string;
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

  let body: ConnectRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'invalid_json_body' }, 400);
  }

  if (!body.workspace_id || !body.platform || !body.oauth_code) {
    return jsonResponse(
      { error: 'missing_required_field', required: ['workspace_id', 'platform', 'oauth_code'] },
      400,
    );
  }

  const userClient = createUserClient(req);
  const workspaceColumn: 'client_workspace_id' | 'team_workspace_id' =
    body.workspace_type === 'client' ? 'client_workspace_id' : 'team_workspace_id';

  let adapter;
  try {
    adapter = getAdapterForPlatform(body.platform);
  } catch {
    return jsonResponse({ error: 'unknown_platform', platform: body.platform }, 400);
  }

  try {
    const connection = await adapter.connectAccount(body.oauth_code, {
      workspaceType: body.workspace_type,
      workspaceId: body.workspace_id,
    });

    // Insert as the calling user — RLS naturally enforces they belong to
    // the target workspace (TDD Section 4, social_connections_access policy).
    const { data: inserted, error: insertError } = await userClient
      .from('social_connections')
      .insert({
        [workspaceColumn]: body.workspace_id,
        platform: body.platform,
        access_token_encrypted: connection.accessToken,
        refresh_token_encrypted: connection.refreshToken ?? null,
        connected_by: userId,
      })
      .select('id, expires_at')
      .single();

    if (insertError || !inserted) {
      return jsonResponse({ error: 'connection_save_failed', detail: insertError?.message }, 500);
    }

    return jsonResponse(
      { connection_id: inserted.id, platform: body.platform, expires_at: inserted.expires_at },
      200,
      corsHeaders,
    );
  } catch (err) {
    return jsonResponse({ error: 'platform_connect_failed', detail: String(err) }, 502);
  }
});
