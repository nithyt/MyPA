/**
 * MyPA — Meta (Instagram/Facebook) adapter.
 * Ref: Architecture Document v1.4, Section 8.2 — "Graph API; requires Meta
 * App Review for publishing permissions; supports scheduled publishing
 * natively."
 *
 * NOT YET FUNCTIONAL: requires a registered Meta App (META_APP_ID /
 * META_APP_SECRET, see Environment Setup Guide) and completed App Review
 * for the instagram_content_publish / pages_manage_posts permissions before
 * publishPost() can work for real. The method bodies below are structured
 * to match the real Graph API shape so filling them in later is a contained
 * change, not a redesign.
 */
import type {
  Connection,
  PlatformContent,
  PublishResult,
  Insights,
  SocialPlatformAdapter,
  WorkspaceRef,
} from './types.ts';

const META_APP_ID = Deno.env.get('META_APP_ID') ?? '';
const META_APP_SECRET = Deno.env.get('META_APP_SECRET') ?? '';
const GRAPH_API_BASE = 'https://graph.facebook.com/v21.0';

export class MetaAdapter implements SocialPlatformAdapter {
  connectAccount(_oauthCode: string, _workspace: WorkspaceRef): Promise<Connection> {
    if (!META_APP_ID || !META_APP_SECRET) {
      throw new Error('META_APP_ID / META_APP_SECRET not configured — see Environment Setup Guide.');
    }
    // Real flow: exchange oauthCode for a short-lived token, then a
    // long-lived token via GRAPH_API_BASE/oauth/access_token.
    throw new Error('MetaAdapter.connectAccount: pending Meta App Review approval.');
  }

  publishPost(_content: PlatformContent, _connection: Connection): Promise<PublishResult> {
    // Real flow (Instagram): POST {ig-user-id}/media to create a container,
    // then POST {ig-user-id}/media_publish with the returned creation_id.
    throw new Error('MetaAdapter.publishPost: pending Meta App Review approval.');
  }

  fetchInsights(_platformPostId: string, _connection: Connection): Promise<Insights> {
    // Real flow: GET {media-id}/insights?metric=reach,saved,...
    throw new Error('MetaAdapter.fetchInsights: pending Meta App Review approval.');
  }

  disconnectAccount(_connection: Connection): Promise<void> {
    // Real flow: DELETE {user-id}/permissions to revoke the granted scopes.
    throw new Error('MetaAdapter.disconnectAccount: pending Meta App Review approval.');
  }
}

// Keep GRAPH_API_BASE referenced so it's not flagged unused before the
// real implementation lands.
void GRAPH_API_BASE;
