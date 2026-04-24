import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/manual_packing_list_item.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/data/projects/in_memory_project_store.dart';
import 'package:stilp_v1/src/features/manual_packing_list/state/manual_packing_list_controller.dart';

void main() {
  late InMemoryProjectStore store;
  late DateTime now;
  late ManualPackingListController controller;

  setUp(() {
    store = InMemoryProjectStore();
    now = DateTime.utc(2026, 4, 24, 12, 0, 0);
    controller = ManualPackingListController(
      store: store,
      now: () => now,
    );
  });

  test('add item stores a row on the active project', () async {
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-1',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 11, 0),
      ),
    );

    final result = await controller.addItem(
      projectId: 'project-1',
      text: 'Stilladsrammer',
      quantity: '40',
      unit: 'stk',
    );

    final project = await store.getProject('project-1');
    expect(result.isSuccess, isTrue);
    expect(project!.manualPackingList, hasLength(1));
    expect(project.manualPackingList.single.text, 'Stilladsrammer');
    expect(project.manualPackingList.single.quantity, 40);
    expect(project.manualPackingList.single.unit, 'stk');
    expect(project.updatedAt, now);
  });

  test('edit item updates existing row by id', () async {
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-2',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 11, 0),
      ).copyWith(
        manualPackingList: const [
          ManualPackingListItem(id: 'a', text: 'Dæk', quantity: 80, unit: 'stk'),
          ManualPackingListItem(id: 'b', text: 'Gelænder', quantity: 20, unit: 'stk'),
        ],
      ),
    );

    final result = await controller.updateItem(
      projectId: 'project-2',
      itemId: 'a',
      text: 'Dæk opdateret',
      quantity: '82',
      unit: 'stk',
    );

    final project = await store.getProject('project-2');
    expect(result.isSuccess, isTrue);
    expect(project!.manualPackingList, hasLength(2));
    expect(project.manualPackingList.first.id, 'a');
    expect(project.manualPackingList.first.text, 'Dæk opdateret');
    expect(project.manualPackingList.first.quantity, 82);
    expect(project.manualPackingList.last.id, 'b');
    expect(project.manualPackingList.last.text, 'Gelænder');
  });

  test('delete item removes row by id', () async {
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-3',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 11, 0),
      ).copyWith(
        manualPackingList: const [
          ManualPackingListItem(id: 'a', text: 'Dæk', quantity: 80, unit: 'stk'),
          ManualPackingListItem(id: 'b', text: 'Gelænder', quantity: 20, unit: 'stk'),
        ],
      ),
    );

    final result = await controller.deleteItem(projectId: 'project-3', itemId: 'a');

    final project = await store.getProject('project-3');
    expect(result.isSuccess, isTrue);
    expect(project!.manualPackingList, hasLength(1));
    expect(project.manualPackingList.single.id, 'b');
  });

  test('invalid quantity is rejected and does not overwrite saved data', () async {
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-4',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 11, 0),
      ).copyWith(
        manualPackingList: const [
          ManualPackingListItem(id: 'a', text: 'Dæk', quantity: 80, unit: 'stk'),
        ],
      ),
    );

    final result = await controller.updateItem(
      projectId: 'project-4',
      itemId: 'a',
      text: 'Ny tekst',
      quantity: 'abc',
      unit: 'stk',
    );

    final project = await store.getProject('project-4');
    expect(result.isSuccess, isFalse);
    expect(project!.manualPackingList.single.text, 'Dæk');
    expect(project.manualPackingList.single.quantity, 80);
  });

  test('empty quantity and unit are stored as null', () async {
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-5',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 11, 0),
      ),
    );

    final result = await controller.addItem(
      projectId: 'project-5',
      text: 'Husk konsoller ved udhæng',
      quantity: ' ',
      unit: ' ',
    );

    final project = await store.getProject('project-5');
    expect(result.isSuccess, isTrue);
    expect(project!.manualPackingList.single.quantity, isNull);
    expect(project.manualPackingList.single.unit, isNull);
  });
}
