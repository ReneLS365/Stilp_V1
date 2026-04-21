import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/placeholder_screen.dart';
import '../../app/state/app_shell_controller.dart';
import '../project_session/state/project_session_controller.dart';

class ProjectsListScreen extends ConsumerWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) {
          return const PlaceholderScreen(
            title: 'Projektliste',
            subtitle: 'Ingen lokale prosjekter enda.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final project = projects[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: const Icon(Icons.folder_open),
              title: Text(project.taskType),
              subtitle: Text(project.notes),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref
                    .read(projectSessionControllerProvider.notifier)
                    .openProject(project.projectId);
                ref.read(appShellControllerProvider.notifier).showWorkspace();
              },
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: projects.length,
        );
      },
      error: (_, __) {
        return const PlaceholderScreen(
          title: 'Projektliste',
          subtitle: 'Kunne ikke læse lokale projekter.',
        );
      },
      loading: () {
        return const PlaceholderScreen(
          title: 'Projektliste',
          subtitle: 'Indlæser lokale projekter...',
        );
      },
    );
  }
}
