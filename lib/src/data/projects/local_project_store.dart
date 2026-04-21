import '../../core/models/project_document.dart';
import '../../core/models/project_summary.dart';

abstract class LocalProjectStore {
  Future<List<ProjectSummary>> listProjects();
  Future<ProjectDocument?> getProject(String projectId);
  Future<void> saveProject(ProjectDocument project);
  Future<void> deleteProject(String projectId);
}
