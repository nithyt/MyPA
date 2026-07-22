/**
 * MyPA — LinkedIn adapter.
 * Ref: Architecture Document v1.4, Section 8.2 — "LinkedIn Marketing/Share
 * API; company page publishing requires partner-level access approval."
 *
 * NOT YET FUNCTIONAL: requires LINKEDIN_CLIENT_ID / LINKEDIN_CLIENT_SECRET
 * (see Environment Setup Guide) and, for company-page publishing, LinkedIn
 * Marketing Developer Platform partner access.
 */
import type {
  Connection,
  PlatformContent,
  PublishResult,
  Insights,
  SocialPlatformAdapter,
  WorkspaceRef,
} from './types.ts';

const LINKEDIN_CLIENT_ID = Deno.env.get('LINKEDIN_CLIENT_ID') ?? '';
const LINKEDIN_CLIENT_SECRET = Deno.env.get('LINKEDIN_CLIENT_SECRET') ?? '';

export class LinkedInAdapter implements SocialPlatformAdapter {
  connectAccount(_oauthCode: string, _workspace: WorkspaceRef): Promise<Connection> {
    if (!LINKEDIN_CLIENT_ID || !LINKEDIN_CLIENT_SECRET) {
      throw new Error('LINKEDIN_CLIENT_ID / LINKEDIN_CLIENT_SECRET not configured.');
    }
    // Real flow: POST https://www.linkedin.com/oauth/v2/accessToken
    throw new Error('LinkedInAdapter.connectAccount: pending partner access approval.');
  }

  publishPost(_content: PlatformContent, _connection: Connection): Promise<PublishResult> {
    // Real flow: POST https://api.linkedin.com/v2/ugcPosts
    throw new Error('LinkedInAdapter.publishPost: pending partner access approval.');
  }

  fetchInsights(_platformPostId: string, _connection: Connection): Promise<Insights> {
    // Real flow: GET https://api.linkedin.com/v2/organizationalEntityShareStatistics
    throw new Error('LinkedInAdapter.fetchInsights: pending partner access approval.');
  }

  disconnectAccount(_connection: Connection): Promise<void> {
    throw new Error('LinkedInAdapter.disconnectAccount: pending partner access approval.');
  }
}
