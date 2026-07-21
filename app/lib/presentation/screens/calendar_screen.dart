import 'package:flutter/material.dart';

/// Matches FDD Section 3.2 "Content Calendar" wireframe.
///
/// TODO (Phase 1 build): read from `content_platform_versions.scheduled_at`
/// (TDD Section 3.4), grouped by day, with status coloring
/// (Draft/Scheduled/Published per FDD Section 8 status-label convention —
/// never color alone, per Accessibility Section 9).
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Content calendar — coming next.\n\n'
            'See FDD Section 3.2 for the wireframe and TDD Section 10 for '
            'the scheduled_at index this screen will query.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
