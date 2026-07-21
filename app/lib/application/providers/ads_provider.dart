import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/ads_repository.dart';
import '../../domain/entities/ad.dart';

final adsRepositoryProvider = Provider<AdsRepository>((ref) {
  return const AdsRepository();
});

/// Family provider so the Home screen can independently fetch the top and
/// bottom ad slots (FDD Section 3.2 "Home / Dashboard" wireframe).
final activeAdsProvider = FutureProvider.family<List<Ad>, AdPlacement>((ref, placement) async {
  return ref.watch(adsRepositoryProvider).fetchActiveAds(placement);
});
