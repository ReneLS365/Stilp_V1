import '../../core/models/project_summary.dart';

class ProjectDocument {
  const ProjectDocument({
    required this.projectId,
    required this.taskType,
    required this.notes,
    required this.updatedAt,
  });

  final String projectId;
  final String taskType;
  final String notes;
  final DateTime updatedAt;
}

abstract class LocalProjectStore {
  Future<List<ProjectSummary>> listProjects();
  Future<ProjectDocument?> getProject(String projectId);
  Future<void> saveProject(ProjectDocument project);
  Future<void> deleteProject(String projectId);
}

class InMemoryProjectStore implements LocalProjectStore {
  InMemoryProjectStore();

  final Map<String, ProjectDocument> _projects = {
    'demo-project': ProjectDocument(
      projectId: 'demo-project',
      taskType: 'Stillas',
      notes: 'Demoprosjekt',
      updatedAt: DateTime(2026, 1, 1),
    ),
  };

  @override
  Future<void> deleteProject(String projectId) async {
    _projects.remove(projectId);
  }

  @override
  Future<ProjectDocument?> getProject(String projectId) async {
    return _projects[projectId];
  }

  @override
  Future<List<ProjectSummary>> listProjects() async {
    return _projects.values
        .map(
          (project) => ProjectSummary(
            projectId: project.projectId,
            taskType: project.taskType,
            notes: project.notes,
            updatedAt: project.updatedAt,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveProject(ProjectDocument project) async {
    _projects[project.projectId] = project;
  }
}
