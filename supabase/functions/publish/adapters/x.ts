/**
 * MyPA — X adapter.
 * Ref: Architecture Document v1.4, Section 8.2 — "X API v2; tiered access
 * levels affect rate limits — plan for the paid tier needed for reliable
 * scheduled posting."
 *
 * NOT YET FUNCTIONAL: requires X_API_KEY / X_API_SECRET on a paid API tier
 * (see Environment Setup Guide).
 */
import type {
  Connection,
  PlatformContent,
  PublishResult,
  Insights,
  SocialPlatformAdapter,
  WorkspaceRef,
} from './types.ts';

const X_API_KEY = Deno.env.get('X_API_KEY') ?? '';
const X_API_SECRET = Deno.env.get('X_API_SECRET') ?? '';

export class XAdapter implements SocialPlatformAdapter {
  connectAccount(_oauthCode: string, _workspace: WorkspaceRef): Promise<Connection> {
    if (!X_API_KEY || !X_API_SECRET) {
      throw new Error('X_API_KEY / X_API_SECRET not configured.');
    }
    // Real flow: OAuth 2.0 PKCE token exchange against api.x.com/2/oauth2/token
    throw new Error('XAdapter.connectAccount: requires a paid API tier — see BRD risk register.');
  }

  publishPost(_content: PlatformContent, _connection: Connection): Promise<PublishResult> {
    // Real flow: POST https://api.x.com/2/tweets
    throw new Error('XAdapter.publishPost: requires a paid API tier.');
  }

  fetchInsights(_platformPostId: string, _connection: Connection): Promise<Insights> {
    // Real flow: GET https://api.x.com/2/tweets/{id}?tweet.fields=public_metrics
    throw new Error('XAdapter.fetchInsights: requires a paid API tier.');
  }

  disconnectAccount(_connection: Connection): Promise<void> {
    throw new Error('XAdapter.disconnectAccount: requires a paid API tier.');
  }
}
