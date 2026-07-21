import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/ai_models_repository.dart';
import '../../domain/entities/ai_model.dart';

final aiModelsRepositoryProvider = Provider<AiModelsRepository>((ref) {
  return const AiModelsRepository();
});

/// The list of selectable AI models for the Create screen's model picker
/// (FDD Section 3.2, "AI model for this post"). Always live data — see
/// AiModelsRepository for why this is never hardcoded.
final activeAiModelsProvider = FutureProvider<List<AiModel>>((ref) async {
  return ref.watch(aiModelsRepositoryProvider).fetchActiveModels();
});
