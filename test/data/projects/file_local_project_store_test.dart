import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/manual_packing_list_item.dart';
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


  test('manual packing list persists after save and reload', () async {
    final store = FileLocalProjectStore(projectsDirectory: projectsDir);
    final project = ProjectDocument.empty(
      projectId: 'project-pack-1',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 21, 17, 0),
    ).copyWith(
      manualPackingList: const [
        ManualPackingListItem(
          id: 'pack-1',
          text: 'Stilladsrammer',
          quantity: 40,
          unit: 'stk',
        ),
        ManualPackingListItem(id: 'pack-2', text: 'Ekstra rækværk til gavl'),
      ],
    );

    await store.saveProject(project);
    final loaded = await FileLocalProjectStore(projectsDirectory: projectsDir).getProject('project-pack-1');

    expect(loaded, isNotNull);
    expect(loaded!.manualPackingList, hasLength(2));
    expect(loaded.manualPackingList.first.text, 'Stilladsrammer');
    expect(loaded.manualPackingList.last.quantity, isNull);
    expect(loaded.manualPackingList.last.unit, isNull);
  });

  test('updating one packing list item does not affect other items', () async {
    final store = FileLocalProjectStore(projectsDirectory: projectsDir);
    final initial = ProjectDocument.empty(
      projectId: 'project-pack-2',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 21, 17, 30),
    ).copyWith(
      manualPackingList: const [
        ManualPackingListItem(id: 'pack-1', text: 'Dæk', quantity: 80, unit: 'stk'),
        ManualPackingListItem(id: 'pack-2', text: 'Gelænder', quantity: 20, unit: 'stk'),
      ],
    );

    await store.saveProject(initial);

    final loaded = await store.getProject('project-pack-2');
    final updatedItems = [...loaded!.manualPackingList];
    updatedItems[0] = updatedItems[0].copyWith(quantity: 82);

    await store.saveProject(loaded.copyWith(manualPackingList: updatedItems));

    final reloaded = await store.getProject('project-pack-2');
    expect(reloaded, isNotNull);
    expect(reloaded!.manualPackingList[0].quantity, 82);
    expect(reloaded.manualPackingList[1].id, 'pack-2');
    expect(reloaded.manualPackingList[1].text, 'Gelænder');
    expect(reloaded.manualPackingList[1].quantity, 20);
  });

  test('deleting one packing list item removes only that item', () async {
    final store = FileLocalProjectStore(projectsDirectory: projectsDir);
    final initial = ProjectDocument.empty(
      projectId: 'project-pack-3',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 21, 18, 0),
    ).copyWith(
      manualPackingList: const [
        ManualPackingListItem(id: 'pack-1', text: 'Dæk', quantity: 80, unit: 'stk'),
        ManualPackingListItem(id: 'pack-2', text: 'Konsoller', quantity: 5, unit: 'stk'),
      ],
    );

    await store.saveProject(initial);
    final loaded = await store.getProject('project-pack-3');
    final keptItems = loaded!.manualPackingList.where((item) => item.id != 'pack-1').toList();

    await store.saveProject(loaded.copyWith(manualPackingList: keptItems));

    final reloaded = await store.getProject('project-pack-3');
    expect(reloaded, isNotNull);
    expect(reloaded!.manualPackingList, hasLength(1));
    expect(reloaded.manualPackingList.single.id, 'pack-2');
    expect(reloaded.manualPackingList.single.text, 'Konsoller');
  });

}
