enum AppFlow {
  projects,
  newProject,
  workspace,
}

enum WorkspaceScreen {
  planView,
  facadeEditor,
  manualPackingList,
  exportPreview,
}

class AppShellState {
  const AppShellState({
    required this.flow,
    required this.workspaceScreen,
    required this.activeProjectId,
  });

  const AppShellState.initial()
      : flow = AppFlow.projects,
        workspaceScreen = WorkspaceScreen.planView,
        activeProjectId = null;

  final AppFlow flow;
  final WorkspaceScreen workspaceScreen;
  final String? activeProjectId;

  AppShellState copyWith({
    AppFlow? flow,
    WorkspaceScreen? workspaceScreen,
    String? activeProjectId,
    bool clearActiveProject = false,
  }) {
    return AppShellState(
      flow: flow ?? this.flow,
      workspaceScreen: workspaceScreen ?? this.workspaceScreen,
      activeProjectId:
          clearActiveProject ? null : (activeProjectId ?? this.activeProjectId),
    );
  }
}
