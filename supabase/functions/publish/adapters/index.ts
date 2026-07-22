/**
 * MyPA — Adapter factory.
 * Ref: Technical Design Document v1.3, Section 7.1
 */
import type { SocialPlatformAdapter } from './types.ts';
import { MetaAdapter } from './meta.ts';
import { LinkedInAdapter } from './linkedin.ts';
import { XAdapter } from './x.ts';
import { TikTokAdapter } from './tiktok.ts';
import { YouTubeAdapter } from './youtube.ts';

export function getAdapterForPlatform(platform: string): SocialPlatformAdapter {
  switch (platform) {
    case 'instagram':
    case 'facebook':
      return new MetaAdapter();
    case 'linkedin':
      return new LinkedInAdapter();
    case 'x':
      return new XAdapter();
    case 'tiktok':
      return new TikTokAdapter();
    case 'youtube':
      return new YouTubeAdapter();
    default:
      throw new Error(`No adapter registered for platform: ${platform}`);
  }
}
