import 'package:flutter/foundation.dart';

enum ProjectWorkspaceTab {
  plan,
  facade,
  packing,
  exportPreview,
}

@immutable
class ProjectSessionState {
  const ProjectSessionState({
    required this.activeProjectId,
    required this.activeTab,
    required this.selectedFacadeSideId,
  });

  final String activeProjectId;
  final ProjectWorkspaceTab activeTab;
  final String? selectedFacadeSideId;

  ProjectSessionState copyWith({
    String? activeProjectId,
    ProjectWorkspaceTab? activeTab,
    String? selectedFacadeSideId,
    bool clearSelectedFacadeSideId = false,
  }) {
    return ProjectSessionState(
      activeProjectId: activeProjectId ?? this.activeProjectId,
      activeTab: activeTab ?? this.activeTab,
      selectedFacadeSideId: clearSelectedFacadeSideId
          ? null
          : (selectedFacadeSideId ?? this.selectedFacadeSideId),
    );
  }
}
