import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/app/state/app_shell_controller.dart';
import 'package:stilp_v1/src/core/models/manual_packing_list_item.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/data/projects/in_memory_project_store.dart';
import 'package:stilp_v1/src/features/manual_packing_list/manual_packing_list_screen.dart';
import 'package:stilp_v1/src/features/project_session/state/project_session_controller.dart';

void main() {
  testWidgets('empty state is shown when list is empty', (tester) async {
    final store = InMemoryProjectStore();
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-empty',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 9, 0),
      ),
    );

    await _pumpScreen(tester, store: store, projectId: 'project-empty');

    expect(find.byKey(const ValueKey('manual-packing-list-empty-state')), findsOneWidget);
    expect(find.text('Ingen pakkelinjer endnu'), findsOneWidget);
  });

  testWidgets('add flow creates and displays a row', (tester) async {
    final store = InMemoryProjectStore();
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-add',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 9, 0),
      ),
    );

    await _pumpScreen(tester, store: store, projectId: 'project-add');

    await tester.tap(find.byKey(const ValueKey('manual-packing-list-add-button')).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-text-input')), 'Stilladsrammer');
    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-quantity-input')), '40');
    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-unit-input')), 'stk');

    await tester.tap(find.byKey(const ValueKey('manual-packing-list-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Stilladsrammer'), findsOneWidget);
    expect(find.text('Antal: 40 · Enhed: stk'), findsOneWidget);
  });

  testWidgets('edit flow updates visible row values', (tester) async {
    final store = InMemoryProjectStore();
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-edit',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 9, 0),
      ).copyWith(
        manualPackingList: const [
          ManualPackingListItem(id: 'item-1', text: 'Stilladsrammer', quantity: 40, unit: 'stk'),
        ],
      ),
    );

    await _pumpScreen(tester, store: store, projectId: 'project-edit');

    await tester.tap(find.byKey(const ValueKey('manual-packing-list-edit-item-1')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-quantity-input')), '42');
    await tester.tap(find.byKey(const ValueKey('manual-packing-list-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Antal: 42 · Enhed: stk'), findsOneWidget);
  });

  testWidgets('delete flow removes a row', (tester) async {
    final store = InMemoryProjectStore();
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-delete',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 9, 0),
      ).copyWith(
        manualPackingList: const [
          ManualPackingListItem(id: 'item-1', text: 'Stilladsrammer', quantity: 40, unit: 'stk'),
          ManualPackingListItem(id: 'item-2', text: 'Ekstra rækværk'),
        ],
      ),
    );

    await _pumpScreen(tester, store: store, projectId: 'project-delete');

    await tester.tap(find.byKey(const ValueKey('manual-packing-list-delete-item-1')));
    await tester.pumpAndSettle();

    expect(find.text('Stilladsrammer'), findsNothing);
    expect(find.text('Ekstra rækværk'), findsOneWidget);
  });

  testWidgets('list restores after rebuild/project reload', (tester) async {
    final store = InMemoryProjectStore();
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-restore',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 9, 0),
      ),
    );

    await _pumpScreen(tester, store: store, projectId: 'project-restore');

    await tester.tap(find.byKey(const ValueKey('manual-packing-list-add-button')).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-text-input')), 'Dæk');
    await tester.tap(find.byKey(const ValueKey('manual-packing-list-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Dæk'), findsOneWidget);

    await _pumpScreen(tester, store: store, projectId: 'project-restore');
    await tester.pumpAndSettle();

    expect(find.text('Dæk'), findsOneWidget);
    final loaded = await store.getProject('project-restore');
    expect(loaded!.manualPackingList.single.text, 'Dæk');
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required InMemoryProjectStore store,
  required String projectId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localProjectStoreProvider.overrideWithValue(store),
        projectSessionControllerProvider.overrideWith(
          (ref) => ProjectSessionController()..openProject(projectId),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: ManualPackingListScreen())),
    ),
  );
  await tester.pumpAndSettle();
}
