/**
 * MyPA — POST /functions/v1/team-invite (Admin/Manager only)
 * Ref: Technical Design Document v1.3, Section 6.5
 *
 * Uses Supabase Auth's admin inviteUserByEmail (service role only) to
 * create/invite the user, then adds them to team_members with the
 * requested role. The authorization check (caller must be admin/manager
 * of this specific team_workspace) is done explicitly here rather than
 * relying solely on RLS, since the team_members insert for the *invited*
 * user is performed with the service-role client.
 */
import { corsHeaders, handleCorsPreflight, jsonResponse } from '../_shared/cors.ts';
import { createServiceRoleClient, createUserClient, getCallerUserId } from '../_shared/supabase.ts';

interface TeamInviteRequest {
  team_workspace_id: string;
  email: string;
  role: 'admin' | 'manager' | 'contributor' | 'viewer';
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

  let body: TeamInviteRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'invalid_json_body' }, 400);
  }

  if (!body.team_workspace_id || !body.email || !body.role) {
    return jsonResponse(
      { error: 'missing_required_field', required: ['team_workspace_id', 'email', 'role'] },
      400,
    );
  }

  const userClient = createUserClient(req);
  const serviceClient = createServiceRoleClient();

  // ---- Explicit authorization check: caller must be admin/manager here ----
  const { data: callerMembership, error: membershipError } = await userClient
    .from('team_members')
    .select('role')
    .eq('team_workspace_id', body.team_workspace_id)
    .eq('user_id', userId)
    .single();

  if (membershipError || !callerMembership) {
    return jsonResponse({ error: 'not_a_team_member' }, 403);
  }
  if (!['admin', 'manager'].includes(callerMembership.role)) {
    return jsonResponse({ error: 'insufficient_role', required: ['admin', 'manager'] }, 403);
  }

  // ---- Invite (or look up) the user via Supabase Auth admin API ----
  const { data: inviteData, error: inviteError } = await serviceClient.auth.admin.inviteUserByEmail(
    body.email,
  );

  if (inviteError || !inviteData?.user) {
    return jsonResponse({ error: 'invite_failed', detail: inviteError?.message }, 502);
  }

  const { error: memberInsertError } = await serviceClient.from('team_members').insert({
    team_workspace_id: body.team_workspace_id,
    user_id: inviteData.user.id,
    role: body.role,
  });

  if (memberInsertError) {
    return jsonResponse({ error: 'team_member_insert_failed', detail: memberInsertError.message }, 500);
  }

  return jsonResponse({ invite_id: inviteData.user.id, status: 'sent' }, 200, corsHeaders);
});
