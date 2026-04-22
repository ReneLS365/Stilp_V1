import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/models/project_summary.dart';
import '../../data/projects/file_local_project_store.dart';
import '../../data/projects/local_project_store.dart';
import 'app_shell_state.dart';

final localProjectStoreProvider = Provider<LocalProjectStore>((ref) {
  return FileLocalProjectStore.fromDirectoryResolver(
    resolveProjectsDirectory: () async {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      return Directory('${documentsDirectory.path}/stilp/projects');
    },
  );
});

final projectsProvider = FutureProvider<List<ProjectSummary>>((ref) async {
  final store = ref.watch(localProjectStoreProvider);
  return store.listProjects();
});

final appShellControllerProvider =
    NotifierProvider<AppShellController, AppShellState>(AppShellController.new);

class AppShellController extends Notifier<AppShellState> {
  @override
  AppShellState build() {
    return const AppShellState.initial();
  }

  void showProjects() {
    state = state.copyWith(flow: AppFlow.projects);
  }

  void showNewProject() {
    state = state.copyWith(flow: AppFlow.newProject);
  }

  void showWorkspace() {
    state = state.copyWith(flow: AppFlow.workspace);
  }
}
