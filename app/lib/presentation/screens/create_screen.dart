import 'package:flutter/material.dart';

/// Matches FDD Section 3.2 "Create (guided, 3-step)" wireframe.
///
/// TODO (Phase 1 build): implement the 3-step flow —
///   1. Describe idea (text or voice, reuse VoiceSearchBar's mic pattern)
///   2. Pick a tone
///   3. Review AI draft — calls POST /functions/v1/ai-generate
///      (TDD Section 6.1), which enforces the paid-tier-only gate and
///      actual-usage credit billing (Architecture v1.4 Section 6.3).
/// This stub exists so the bottom nav and routing are already correct;
/// the guided flow itself is the next real feature to build.
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Guided content creation — coming next.\n\n'
            'See FDD Section 3.2 for the 3-step wireframe and '
            'TDD Section 6.1 for the ai-generate contract this will call.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
