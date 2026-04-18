import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/placeholder_screen.dart';
import '../../app/state/app_shell_controller.dart';

class ProjectsListScreen extends ConsumerWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    final subtitle = projectsAsync.when(
      data: (projects) =>
          'Lokale projekter (${projects.length}), opret, åbn, slet eller duplikér.',
      error: (_, __) => 'Kunne ikke læse lokale projekter.',
      loading: () => 'Indlæser lokale projekter...',
    );

    return PlaceholderScreen(
      title: 'Projektliste',
      subtitle: subtitle,
    );
  }
}
