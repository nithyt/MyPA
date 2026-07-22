/**
 * MyPA — POST /functions/v1/approve-content
 * Ref: Technical Design Document v1.3, Section 6.6
 * Ref: Functional Design Document, Section 5.2 (Approval Workflow Settings)
 *
 * Approval is a Business/Team-workspace feature (BR-AD-03) — the caller
 * must hold an admin/manager role in the team_workspace that owns this
 * content item. Consultant-client workspaces have no approval concept in
 * Phase 1 (FDD Section 5, Admin/IT Console is a Business-only module).
 */
import { corsHeaders, handleCorsPreflight, jsonResponse } from '../_shared/cors.ts';
import { createServiceRoleClient, createUserClient, getCallerUserId } from '../_shared/supabase.ts';

interface ApproveContentRequest {
  approval_request_id: string;
  decision: 'approved' | 'rejected';
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

  let body: ApproveContentRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'invalid_json_body' }, 400);
  }

  if (!body.approval_request_id || !body.decision) {
    return jsonResponse(
      { error: 'missing_required_field', required: ['approval_request_id', 'decision'] },
      400,
    );
  }
  if (!['approved', 'rejected'].includes(body.decision)) {
    return jsonResponse({ error: 'invalid_decision', allowed: ['approved', 'rejected'] }, 400);
  }

  const userClient = createUserClient(req);
  const serviceClient = createServiceRoleClient();

  // RLS-enforced read (approval_requests_access -> content_items visibility).
  const { data: approval, error: approvalError } = await userClient
    .from('approval_requests')
    .select('id, content_item_id, content_items(team_workspace_id)')
    .eq('id', body.approval_request_id)
    .single();

  if (approvalError || !approval) {
    return jsonResponse({ error: 'approval_request_not_found' }, 404);
  }

  const teamWorkspaceId = (approval as unknown as { content_items: { team_workspace_id: string | null } })
    .content_items.team_workspace_id;

  if (!teamWorkspaceId) {
    return jsonResponse({ error: 'approval_not_applicable_to_client_workspaces' }, 400);
  }

  // ---- Explicit role check: admin/manager only ----
  const { data: membership, error: membershipError } = await userClient
    .from('team_members')
    .select('role')
    .eq('team_workspace_id', teamWorkspaceId)
    .eq('user_id', userId)
    .single();

  if (membershipError || !membership || !['admin', 'manager'].includes(membership.role)) {
    return jsonResponse({ error: 'insufficient_role', required: ['admin', 'manager'] }, 403);
  }

  const newContentStatus = body.decision === 'approved' ? 'scheduled' : 'draft';

  await serviceClient
    .from('approval_requests')
    .update({ status: body.decision, approver_id: userId, decided_at: new Date().toISOString() })
    .eq('id', approval.id);

  await userClient
    .from('content_items')
    .update({ status: newContentStatus })
    .eq('id', approval.content_item_id);

  return jsonResponse(
    { content_item_id: approval.content_item_id, status: newContentStatus },
    200,
    corsHeaders,
  );
});
