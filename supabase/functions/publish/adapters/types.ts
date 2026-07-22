/**
 * MyPA — Social Platform Adapter interface.
 * Ref: Technical Design Document v1.3, Section 7.1
 * Ref: Architecture Document v1.4, Section 8.1
 *
 * Every launch platform (Meta, LinkedIn, X, TikTok, YouTube) implements this
 * so the publish function never branches on platform-specific logic.
 * Concrete adapters (meta.ts, linkedin.ts, etc.) are stubs pending each
 * platform's developer API approval — see BRD v1.1 risk register and
 * Architecture v1.4 Section 8.2 for per-platform notes.
 */

export interface WorkspaceRef {
  workspaceType: 'client' | 'team';
  workspaceId: string;
}

export interface Connection {
  id: string;
  accessToken: string;
  refreshToken?: string;
}

export interface PlatformContent {
  bodyText: string;
  mediaUrl?: string;
}

export interface PublishResult {
  platformPostId: string;
  status: 'success' | 'failed';
}

export interface Insights {
  reach?: number;
  engagementRate?: number;
  saves?: number;
}

export interface SocialPlatformAdapter {
  connectAccount(oauthCode: string, workspace: WorkspaceRef): Promise<Connection>;
  publishPost(content: PlatformContent, connection: Connection): Promise<PublishResult>;
  fetchInsights(platformPostId: string, connection: Connection): Promise<Insights>;
  disconnectAccount(connection: Connection): Promise<void>;
}
