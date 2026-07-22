/**
 * MyPA — YouTube adapter.
 * Ref: Architecture Document v1.4, Section 8.2 — "YouTube Data API;
 * primarily for video upload/metadata — most relevant to consultants
 * managing video content."
 *
 * NOT YET FUNCTIONAL: requires a Google Cloud project with the YouTube
 * Data API enabled and OAuth credentials (see Environment Setup Guide).
 */
import type {
  Connection,
  PlatformContent,
  PublishResult,
  Insights,
  SocialPlatformAdapter,
  WorkspaceRef,
} from './types.ts';

const YOUTUBE_CLIENT_ID = Deno.env.get('YOUTUBE_CLIENT_ID') ?? '';
const YOUTUBE_CLIENT_SECRET = Deno.env.get('YOUTUBE_CLIENT_SECRET') ?? '';

export class YouTubeAdapter implements SocialPlatformAdapter {
  connectAccount(_oauthCode: string, _workspace: WorkspaceRef): Promise<Connection> {
    if (!YOUTUBE_CLIENT_ID || !YOUTUBE_CLIENT_SECRET) {
      throw new Error('YOUTUBE_CLIENT_ID / YOUTUBE_CLIENT_SECRET not configured.');
    }
    // Real flow: Google OAuth 2.0 token exchange against oauth2.googleapis.com/token
    throw new Error('YouTubeAdapter.connectAccount: not yet implemented.');
  }

  publishPost(_content: PlatformContent, _connection: Connection): Promise<PublishResult> {
    // Real flow: POST https://www.googleapis.com/upload/youtube/v3/videos
    throw new Error('YouTubeAdapter.publishPost: not yet implemented.');
  }

  fetchInsights(_platformPostId: string, _connection: Connection): Promise<Insights> {
    // Real flow: GET https://www.googleapis.com/youtube/v3/videos?part=statistics
    throw new Error('YouTubeAdapter.fetchInsights: not yet implemented.');
  }

  disconnectAccount(_connection: Connection): Promise<void> {
    throw new Error('YouTubeAdapter.disconnectAccount: not yet implemented.');
  }
}
