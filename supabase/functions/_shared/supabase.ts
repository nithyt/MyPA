/**
 * MyPA — Shared Supabase client factories for Edge Functions.
 * Ref: Architecture Document v1.4, Section 10 (Security) — secrets never
 * reach the client; every privileged write (credit deduction, log writes)
 * happens here, server-side, using the service_role key.
 */
import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2.45.4';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

/**
 * A client that acts AS the calling user — forwards their JWT so every
 * query is still subject to Row Level Security (TDD v1.3, Section 4).
 * Use this for anything the user should only be able to do to their own
 * data; never use this for credit deduction or writing logs.
 */
export function createUserClient(req: Request): SupabaseClient {
  const authHeader = req.headers.get('Authorization') ?? '';
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
}

/**
 * A client that bypasses RLS entirely using the service_role key. Only
 * ever used inside Edge Functions for operations the schema deliberately
 * has no client-facing write policy for (account_credits, credit_transactions,
 * ai_generation_logs, publish_logs) — see TDD v1.3, Section 4.
 *
 * SUPABASE_SERVICE_ROLE_KEY must be set as an Edge Function secret and must
 * NEVER be exposed to the Flutter client (Architecture v1.4, Section 10).
 */
export function createServiceRoleClient(): SupabaseClient {
  if (!SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error(
      'SUPABASE_SERVICE_ROLE_KEY is not set. Set it via `supabase secrets set` — ' +
        'see docs/06-environment/MyPA_Environment_Setup_v1.0.docx.',
    );
  }
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
}

/** Extracts the calling user's id from their JWT, or null if unauthenticated. */
export async function getCallerUserId(req: Request): Promise<string | null> {
  const client = createUserClient(req);
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) return null;
  return data.user.id;
}
