/// Mirrors the `ads` table (Technical Design Document v1.3, Section 3.8).
/// Only ever read by the client via the ads_public_read RLS policy — writes
/// are platform-admin-only (Architecture v1.4, Section 9).
enum AdPlacement { top, bottom }

class Ad {
  const Ad({
    required this.id,
    required this.placement,
    required this.title,
    this.bodyText,
    this.imageUrl,
    this.targetUrl,
  });

  final String id;
  final AdPlacement placement;
  final String title;
  final String? bodyText;
  final String? imageUrl;
  final String? targetUrl;

  factory Ad.fromMap(Map<String, dynamic> row) {
    return Ad(
      id: row['id'] as String,
      placement: AdPlacement.values.byName(row['placement'] as String),
      title: row['title'] as String,
      bodyText: row['body_text'] as String?,
      imageUrl: row['image_url'] as String?,
      targetUrl: row['target_url'] as String?,
    );
  }
}
