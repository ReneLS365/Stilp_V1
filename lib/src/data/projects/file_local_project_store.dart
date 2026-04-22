import 'dart:convert';
import 'dart:io';

import '../../core/models/project_document.dart';
import '../../core/models/project_summary.dart';
import 'local_project_store.dart';

class FileLocalProjectStore implements LocalProjectStore {
  FileLocalProjectStore({required Directory projectsDirectory})
      : _resolveProjectsDirectory = (() async => projectsDirectory);

  FileLocalProjectStore.fromDirectoryResolver({
    required Future<Directory> Function() resolveProjectsDirectory,
  }) : _resolveProjectsDirectory = resolveProjectsDirectory;

  final Future<Directory> Function() _resolveProjectsDirectory;

  Future<Directory> _projectsDirectory() async {
    return _resolveProjectsDirectory();
  }

  Future<File> _projectFile(String projectId) async {
    final projectsDirectory = await _projectsDirectory();
    return File('${projectsDirectory.path}/$projectId.json');
  }

  Future<Directory> _ensureDirectory() async {
    final projectsDirectory = await _projectsDirectory();
    if (!await projectsDirectory.exists()) {
      await projectsDirectory.create(recursive: true);
    }
    return projectsDirectory;
  }

  @override
  Future<void> saveProject(ProjectDocument project) async {
    await _ensureDirectory();
    final file = await _projectFile(project.projectId);
    final encoded = jsonEncode(project.toJson());
    await file.writeAsString(encoded, flush: true);
  }

  @override
  Future<ProjectDocument?> getProject(String projectId) async {
    final file = await _projectFile(projectId);
    if (!await file.exists()) {
      return null;
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return ProjectDocument.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ProjectSummary>> listProjects() async {
    final projectsDirectory = await _projectsDirectory();
    if (!await projectsDirectory.exists()) {
      return const [];
    }

    final summaries = <ProjectSummary>[];
    await for (final entity in projectsDirectory.list(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }

      try {
        final raw = await entity.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }

        final project = ProjectDocument.fromJson(decoded);
        summaries.add(
          ProjectSummary(
            projectId: project.projectId,
            taskType: project.taskType,
            notes: project.notes,
            updatedAt: project.updatedAt,
          ),
        );
      } catch (_) {
        // Ignore corrupt files and continue listing remaining projects.
      }
    }

    summaries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return summaries;
  }

  @override
  Future<void> deleteProject(String projectId) async {
    final file = await _projectFile(projectId);
    if (!await file.exists()) {
      return;
    }

    await file.delete();
  }
}
