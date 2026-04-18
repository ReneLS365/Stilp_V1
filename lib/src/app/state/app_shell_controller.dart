import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/project_summary.dart';
import '../../core/storage/local_project_store.dart';
import 'app_shell_state.dart';

final localProjectStoreProvider = Provider<LocalProjectStore>((ref) {
  return InMemoryProjectStore();
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

  void openWorkspaceForProject(String projectId) {
    state = state.copyWith(
      flow: AppFlow.workspace,
      activeProjectId: projectId,
    );
  }

  void setWorkspaceScreen(WorkspaceScreen screen) {
    state = state.copyWith(
      flow: AppFlow.workspace,
      workspaceScreen: screen,
    );
  }
}
