/**
 * MyPA — POST /functions/v1/publish
 * Ref: Technical Design Document v1.3, Section 6.3
 * Ref: Architecture Document v1.4, Section 8 (adapter pattern)
 *
 * If schedule_at is in the future, this just records the schedule — actual
 * publishing at that time requires a separate scheduler trigger (not yet
 * built; TODO, see Section 10 of the TDD on the scheduled_at index this
 * will query). If schedule_at is omitted or in the past, this publishes
 * immediately via the matching platform adapter.
 */
import { corsHeaders, handleCorsPreflight, jsonResponse } from '../_shared/cors.ts';
import { createServiceRoleClient, createUserClient, getCallerUserId } from '../_shared/supabase.ts';
import { getAdapterForPlatform } from './adapters/index.ts';

interface PublishRequest {
  content_platform_version_id: string;
  schedule_at?: string | null;
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

  let body: PublishRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'invalid_json_body' }, 400);
  }

  if (!body.content_platform_version_id) {
    return jsonResponse({ error: 'missing_required_field', required: ['content_platform_version_id'] }, 400);
  }

  const userClient = createUserClient(req);
  const serviceClient = createServiceRoleClient();

  // RLS-enforced read: this naturally 404s if the caller doesn't belong to
  // the owning workspace (TDD Section 4.3's content_items policy cascades
  // to this join).
  const { data: version, error: versionError } = await userClient
    .from('content_platform_versions')
    .select('id, platform, body_text, media_url, content_item_id, content_items(client_workspace_id, team_workspace_id, status)')
    .eq('id', body.content_platform_version_id)
    .single();

  if (versionError || !version) {
    return jsonResponse({ error: 'content_version_not_found' }, 404);
  }

  const contentItem = (version as unknown as {
    content_items: { client_workspace_id: string | null; team_workspace_id: string | null; status: string };
  }).content_items;

  // ---- Approval gate ----
  if (contentItem.status === 'pending_approval') {
    return jsonResponse({ error: 'approval_required' }, 403);
  }

  const workspaceId = contentItem.client_workspace_id ?? contentItem.team_workspace_id;
  const workspaceColumn = contentItem.client_workspace_id ? 'client_workspace_id' : 'team_workspace_id';

  // ---- Scheduling path: just record it, no adapter call yet ----
  const scheduleAt = body.schedule_at ? new Date(body.schedule_at) : null;
  if (scheduleAt && scheduleAt.getTime() > Date.now()) {
    await userClient
      .from('content_platform_versions')
      .update({ scheduled_at: scheduleAt.toISOString(), status: 'scheduled' })
      .eq('id', version.id);

    return jsonResponse({ status: 'scheduled', platform_post_id: null }, 200, corsHeaders);
  }

  // ---- Immediate publish path ----
  const { data: connection, error: connectionError } = await userClient
    .from('social_connections')
    .select('id, access_token_encrypted, refresh_token_encrypted, expires_at')
    .eq(workspaceColumn, workspaceId)
    .eq('platform', version.platform)
    .single();

  if (connectionError || !connection) {
    return jsonResponse({ error: 'platform_not_connected' }, 409);
  }

  if (connection.expires_at && new Date(connection.expires_at).getTime() < Date.now()) {
    return jsonResponse({ error: 'platform_token_expired', platform: version.platform }, 409);
  }

  const adapter = getAdapterForPlatform(version.platform);

  try {
    const result = await adapter.publishPost(
      { bodyText: version.body_text ?? '', mediaUrl: version.media_url ?? undefined },
      {
        id: connection.id,
        // NOTE: access_token_encrypted is stored encrypted at rest (TDD
        // Section 3.5); decrypting it is an infrastructure detail (e.g. via
        // Supabase Vault or pgsodium) not yet wired up here — see Open
        // Architectural Decisions.
        accessToken: connection.access_token_encrypted,
        refreshToken: connection.refresh_token_encrypted ?? undefined,
      },
    );

    await userClient
      .from('content_platform_versions')
      .update({
        status: result.status,
        platform_post_id: result.platformPostId,
        published_at: new Date().toISOString(),
      })
      .eq('id', version.id);

    await serviceClient.from('publish_logs').insert({
      content_platform_version_id: version.id,
      status: result.status === 'success' ? 'success' : 'failed',
      response_payload: result,
    });

    return jsonResponse(
      { status: 'published', platform_post_id: result.platformPostId },
      200,
      corsHeaders,
    );
  } catch (err) {
    await serviceClient.from('publish_logs').insert({
      content_platform_version_id: version.id,
      status: 'failed',
      response_payload: { error: String(err) },
    });

    return jsonResponse(
      { error: 'platform_api_error', platform: version.platform, detail: String(err) },
      502,
    );
  }
});
