import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/data/projects/file_local_project_store.dart';

void main() {
  late Directory tempRoot;
  late Directory projectsDir;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('stilp_store_test_');
    projectsDir = Directory('${tempRoot.path}/stilp/projects');
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('saveProject and getProject persist through fresh store instances', () async {
    final createdAt = DateTime.utc(2026, 4, 21, 12, 0);
    final project = ProjectDocument.empty(
      projectId: 'project-1',
      taskType: 'Facadestillads',
      notes: 'Persist me',
      now: createdAt,
    );

    final firstStore = FileLocalProjectStore(projectsDirectory: projectsDir);
    await firstStore.saveProject(project);

    final secondStore = FileLocalProjectStore(projectsDirectory: projectsDir);
    final loaded = await secondStore.getProject('project-1');

    expect(loaded, isNotNull);
    expect(loaded!.projectId, 'project-1');
    expect(loaded.taskType, 'Facadestillads');
    expect(loaded.notes, 'Persist me');
    expect(loaded.createdAt, createdAt);
  });

  test('listProjects returns summaries derived from stored documents', () async {
    final store = FileLocalProjectStore(projectsDirectory: projectsDir);
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-2',
        taskType: 'Tagarbejde',
        notes: 'Summary source',
        now: DateTime.utc(2026, 4, 21, 13, 0),
      ),
    );

    final summaries = await store.listProjects();

    expect(summaries, hasLength(1));
    expect(summaries.single.projectId, 'project-2');
    expect(summaries.single.taskType, 'Tagarbejde');
    expect(summaries.single.notes, 'Summary source');
  });

  test('saveProject overwrites existing project data', () async {
    final store = FileLocalProjectStore(projectsDirectory: projectsDir);
    final original = ProjectDocument.empty(
      projectId: 'project-3',
      taskType: 'Stillads',
      notes: 'v1',
      now: DateTime.utc(2026, 4, 21, 14, 0),
    );

    await store.saveProject(original);

    final updated = original.copyWith(
      notes: 'v2',
      updatedAt: DateTime.utc(2026, 4, 22, 9, 30),
    );
    await store.saveProject(updated);

    final loaded = await store.getProject('project-3');

    expect(loaded, isNotNull);
    expect(loaded!.notes, 'v2');
    expect(loaded.updatedAt, DateTime.utc(2026, 4, 22, 9, 30));
  });

  test('deleteProject removes a persisted project and missing delete does not crash', () async {
    final store = FileLocalProjectStore(projectsDirectory: projectsDir);
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-4',
        taskType: 'Facade',
        notes: 'to-delete',
        now: DateTime.utc(2026, 4, 21, 15, 0),
      ),
    );

    await store.deleteProject('project-4');
    await store.deleteProject('missing-project');

    final loaded = await store.getProject('project-4');
    final summaries = await store.listProjects();

    expect(loaded, isNull);
    expect(summaries, isEmpty);
  });

  test('listProjects sorts by updatedAt descending', () async {
    final store = FileLocalProjectStore(projectsDirectory: projectsDir);

    final older = ProjectDocument.empty(
      projectId: 'older',
      taskType: 'Old',
      now: DateTime.utc(2026, 4, 21, 10, 0),
    );
    final newer = ProjectDocument.empty(
      projectId: 'newer',
      taskType: 'New',
      now: DateTime.utc(2026, 4, 21, 10, 0),
    ).copyWith(updatedAt: DateTime.utc(2026, 4, 22, 10, 0));

    await store.saveProject(older);
    await store.saveProject(newer);

    final summaries = await store.listProjects();

    expect(summaries.map((item) => item.projectId), <String>['newer', 'older']);
  });

  test('listProjects skips corrupt json files and non-json files', () async {
    final store = FileLocalProjectStore(projectsDirectory: projectsDir);
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'valid-project',
        taskType: 'Valid',
        now: DateTime.utc(2026, 4, 21, 16, 0),
      ),
    );

    await projectsDir.create(recursive: true);
    await File('${projectsDir.path}/broken.json').writeAsString('{not valid json');
    await File('${projectsDir.path}/notes.txt').writeAsString('ignore this');

    final summaries = await store.listProjects();

    expect(summaries, hasLength(1));
    expect(summaries.single.projectId, 'valid-project');
  });
}
