import '../../core/supabase_client.dart';
import '../../domain/entities/ad.dart';

/// Reads active ads for a given placement. Filtering by date/active-flag
/// happens server-side via the `ads_public_read` RLS policy
/// (TDD v1.3, Section 4.4) — the client never has to reason about which
/// ads are expired, and never receives rows it shouldn't.
class AdsRepository {
  const AdsRepository();

  Future<List<Ad>> fetchActiveAds(AdPlacement placement) async {
    final rows = await supabase
        .from('ads')
        .select()
        .eq('placement', placement.name)
        .order('created_at', ascending: false);

    return (rows as List).map((row) => Ad.fromMap(row as Map<String, dynamic>)).toList();
  }
}
