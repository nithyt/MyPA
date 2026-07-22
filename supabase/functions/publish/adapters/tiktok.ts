/**
 * MyPA — TikTok adapter.
 * Ref: Architecture Document v1.4, Section 8.2 — "TikTok API for
 * Business/Content Posting API; approval process is typically the
 * slowest — build manual-export fallback for launch if approval lags."
 *
 * NOT YET FUNCTIONAL: requires TIKTOK_CLIENT_KEY / TIKTOK_CLIENT_SECRET and
 * Content Posting API approval (see Environment Setup Guide and BRD v1.1
 * risk register — this is typically the slowest of the 5 platforms to
 * approve). The manual-export fallback described there lives in the
 * Flutter app's UI, not here.
 */
import type {
  Connection,
  PlatformContent,
  PublishResult,
  Insights,
  SocialPlatformAdapter,
  WorkspaceRef,
} from './types.ts';

const TIKTOK_CLIENT_KEY = Deno.env.get('TIKTOK_CLIENT_KEY') ?? '';
const TIKTOK_CLIENT_SECRET = Deno.env.get('TIKTOK_CLIENT_SECRET') ?? '';

export class TikTokAdapter implements SocialPlatformAdapter {
  connectAccount(_oauthCode: string, _workspace: WorkspaceRef): Promise<Connection> {
    if (!TIKTOK_CLIENT_KEY || !TIKTOK_CLIENT_SECRET) {
      throw new Error('TIKTOK_CLIENT_KEY / TIKTOK_CLIENT_SECRET not configured.');
    }
    throw new Error('TikTokAdapter.connectAccount: pending Content Posting API approval.');
  }

  publishPost(_content: PlatformContent, _connection: Connection): Promise<PublishResult> {
    // Real flow: POST https://open.tiktokapis.com/v2/post/publish/video/init/
    throw new Error('TikTokAdapter.publishPost: pending Content Posting API approval.');
  }

  fetchInsights(_platformPostId: string, _connection: Connection): Promise<Insights> {
    throw new Error('TikTokAdapter.fetchInsights: pending Content Posting API approval.');
  }

  disconnectAccount(_connection: Connection): Promise<void> {
    throw new Error('TikTokAdapter.disconnectAccount: pending Content Posting API approval.');
  }
}
