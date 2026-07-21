import '../../core/supabase_client.dart';
import '../../domain/entities/ai_model.dart';

/// Reads the AI model marketplace catalog. This is a direct table read
/// against the `ai_models_public_read` RLS policy (TDD v1.3, Section 4.4) —
/// no Edge Function needed, since listing models requires no secret.
///
/// Rates shown here are whatever the nightly sync-model-pricing Edge
/// Function last wrote (Architecture v1.4, Section 6.2); the client never
/// computes or caches pricing independently.
class AiModelsRepository {
  const AiModelsRepository();

  Future<List<AiModel>> fetchActiveModels() async {
    final rows = await supabase
        .from('ai_models')
        .select()
        .eq('is_active', true)
        .order('input_rate_per_million');

    return (rows as List)
        .map((row) => AiModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
