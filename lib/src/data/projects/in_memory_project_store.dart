import '../../core/models/project_document.dart';
import '../../core/models/project_summary.dart';
import 'local_project_store.dart';

class InMemoryProjectStore implements LocalProjectStore {
  InMemoryProjectStore();

  final Map<String, ProjectDocument> _projects = {
    'demo-project': ProjectDocument.empty(
      projectId: 'demo-project',
      taskType: 'Stillads',
      notes: 'Demo-projekt',
      now: DateTime(2026, 1, 1),
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
    final summaries = _projects.values
        .map(
          (project) => ProjectSummary(
            projectId: project.projectId,
            taskType: project.taskType,
            notes: project.notes,
            updatedAt: project.updatedAt,
          ),
        )
        .toList(growable: false);

    summaries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return summaries;
  }

  @override
  Future<void> saveProject(ProjectDocument project) async {
    _projects[project.projectId] = project;
  }
}
