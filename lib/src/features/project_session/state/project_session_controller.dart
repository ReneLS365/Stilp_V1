import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'project_session_state.dart';

final projectSessionControllerProvider =
    StateNotifierProvider<ProjectSessionController, ProjectSessionState?>(
  (ref) => ProjectSessionController(),
);

class ProjectSessionController extends StateNotifier<ProjectSessionState?> {
  ProjectSessionController() : super(null);

  void openProject(String projectId) {
    state = ProjectSessionState(
      activeProjectId: projectId,
      activeTab: ProjectWorkspaceTab.plan,
      selectedFacadeSideId: null,
    );
  }

  void closeProject() {
    state = null;
  }

  void setTab(ProjectWorkspaceTab tab) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(activeTab: tab);
  }

  void setSelectedFacadeSide(String? sideId) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(selectedFacadeSideId: sideId);
  }

  void resetSelectedFacadeSide() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(clearSelectedFacadeSideId: true);
  }
}
