import '../models/project_summary.dart';

abstract class LocalProjectStore {
  Future<List<ProjectSummary>> listProjects();
}

class InMemoryProjectStore implements LocalProjectStore {
  InMemoryProjectStore();

  final List<ProjectSummary> _projects = const [];

  @override
  Future<List<ProjectSummary>> listProjects() async => _projects;
}
