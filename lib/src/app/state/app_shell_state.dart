enum AppFlow {
  projects,
  newProject,
  workspace,
}

class AppShellState {
  const AppShellState({
    required this.flow,
  });

  const AppShellState.initial() : flow = AppFlow.projects;

  final AppFlow flow;

  AppShellState copyWith({
    AppFlow? flow,
  }) {
    return AppShellState(
      flow: flow ?? this.flow,
    );
  }
}
