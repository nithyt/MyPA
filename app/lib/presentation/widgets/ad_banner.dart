import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/providers/ads_provider.dart';
import '../../domain/entities/ad.dart';

/// Scrolling ad banner for the Home screen's top or bottom slot, sourced
/// live from the `ads` table (TDD v1.3 Section 3.8) — never hardcoded
/// content, per the requirement that ads come entirely from the database.
class AdBanner extends ConsumerWidget {
  const AdBanner({super.key, required this.placement});

  final AdPlacement placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(activeAdsProvider(placement));

    return adsAsync.when(
      data: (ads) {
        if (ads.isEmpty) return const SizedBox.shrink();
        return _ScrollingAdStrip(ads: ads);
      },
      // Ads are non-critical — never block or visibly error the Home screen.
      loading: () => const SizedBox(height: 28),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ScrollingAdStrip extends StatelessWidget {
  const _ScrollingAdStrip({required this.ads});

  final List<Ad> ads;

  Future<void> _openAd(Ad ad) async {
    final url = ad.targetUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 28,
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: ads.length,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final ad = ads[index];
          return GestureDetector(
            onTap: () => _openAd(ad),
            child: Center(
              child: Text(
                '📣 Ad · ${ad.title}${ad.bodyText != null ? ' — ${ad.bodyText}' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
          );
        },
      ),
    );
  }
}
