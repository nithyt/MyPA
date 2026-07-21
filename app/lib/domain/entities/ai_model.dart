/// Mirrors the `ai_models` table (Technical Design Document v1.3, Section 3.7).
/// Rates are kept current by the sync-model-pricing Edge Function
/// (Architecture v1.4, Section 6.2) — this entity always reflects whatever
/// GET /functions/v1/ai-models last returned, never a hardcoded value.
class AiModel {
  const AiModel({
    required this.id,
    required this.provider,
    required this.displayName,
    required this.isFree,
    required this.inputRatePerMillion,
    required this.outputRatePerMillion,
  });

  final String id;
  final String provider;
  final String displayName;
  final bool isFree;
  final double inputRatePerMillion;
  final double outputRatePerMillion;

  /// Rough client-side estimate only, for display purposes (e.g. "~2 credits").
  /// The authoritative charge is always computed server-side in ai-generate
  /// from actual token usage (Architecture v1.4, Section 6.3) — this estimate
  /// must never be trusted for billing decisions on the client.
  int estimatedCreditsForDisplay({
    int assumedInputTokens = 800,
    int assumedOutputTokens = 600,
    double creditUsdPeg = 0.001,
  }) {
    if (isFree) return 0;
    final cost = (assumedInputTokens / 1000000 * inputRatePerMillion) +
        (assumedOutputTokens / 1000000 * outputRatePerMillion);
    final credits = (cost / creditUsdPeg).ceil();
    return credits < 1 ? 1 : credits;
  }

  factory AiModel.fromMap(Map<String, dynamic> row) {
    return AiModel(
      id: row['id'] as String,
      provider: row['provider'] as String,
      displayName: row['display_name'] as String,
      isFree: row['is_free'] as bool,
      inputRatePerMillion: (row['input_rate_per_million'] as num).toDouble(),
      outputRatePerMillion: (row['output_rate_per_million'] as num).toDouble(),
    );
  }
}
