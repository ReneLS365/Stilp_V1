import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/app/state/app_shell_controller.dart';
import 'package:stilp_v1/src/core/models/manual_packing_list_item.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/core/models/project_summary.dart';
import 'package:stilp_v1/src/data/projects/in_memory_project_store.dart';
import 'package:stilp_v1/src/data/projects/local_project_store.dart';
import 'package:stilp_v1/src/features/manual_packing_list/manual_packing_list_screen.dart';
import 'package:stilp_v1/src/features/manual_packing_list/state/manual_packing_list_controller.dart';
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

  testWidgets('successful mutations invalidate project summaries provider', (tester) async {
    final store = _CountingProjectStore();
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-invalidate',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 9, 0),
      ).copyWith(
        manualPackingList: const [
          ManualPackingListItem(id: 'item-1', text: 'Stilladsrammer', quantity: 40, unit: 'stk'),
        ],
      ),
    );

    await _pumpScreen(
      tester,
      store: store,
      projectId: 'project-invalidate',
      watchProjectSummaries: true,
    );
    final initialListCalls = store.listProjectsCallCount;

    await tester.tap(find.byKey(const ValueKey('manual-packing-list-add-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-text-input')), 'Dæk');
    await tester.tap(find.byKey(const ValueKey('manual-packing-list-save-button')));
    await tester.pumpAndSettle();
    expect(store.listProjectsCallCount, greaterThan(initialListCalls));

    final afterAddCalls = store.listProjectsCallCount;
    await tester.tap(find.byKey(const ValueKey('manual-packing-list-edit-item-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-quantity-input')), '42');
    await tester.tap(find.byKey(const ValueKey('manual-packing-list-save-button')));
    await tester.pumpAndSettle();
    expect(store.listProjectsCallCount, greaterThan(afterAddCalls));

    final afterUpdateCalls = store.listProjectsCallCount;
    await tester.tap(find.byKey(const ValueKey('manual-packing-list-delete-item-1')));
    await tester.pumpAndSettle();
    expect(store.listProjectsCallCount, greaterThan(afterUpdateCalls));
  });

  testWidgets('failed validation does not invalidate project summaries provider', (tester) async {
    final store = _CountingProjectStore();
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-no-invalidate',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 9, 0),
      ),
    );

    await _pumpScreen(
      tester,
      store: store,
      projectId: 'project-no-invalidate',
      watchProjectSummaries: true,
    );
    final initialListCalls = store.listProjectsCallCount;

    await tester.tap(find.byKey(const ValueKey('manual-packing-list-add-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-text-input')), 'Dæk');
    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-quantity-input')), 'ikke-tal');
    await tester.tap(find.byKey(const ValueKey('manual-packing-list-save-button')));
    await tester.pumpAndSettle();

    expect(store.listProjectsCallCount, initialListCalls);
  });

  testWidgets('rapid double tap on save submits only once', (tester) async {
    final store = InMemoryProjectStore();
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-double-save',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 9, 0),
      ),
    );
    final addGate = Completer<void>();
    final fakeController = _ControlledSaveManualPackingListController(
      store: store,
      addGate: addGate,
      now: DateTime.utc(2026, 4, 24, 10, 0),
    );

    await _pumpScreen(
      tester,
      store: store,
      projectId: 'project-double-save',
      controllerOverride: fakeController,
    );

    await tester.tap(find.byKey(const ValueKey('manual-packing-list-add-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-text-input')), 'Stilladsrammer');
    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-quantity-input')), '40');
    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-unit-input')), 'stk');

    await tester.tap(find.byKey(const ValueKey('manual-packing-list-save-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('manual-packing-list-save-button')));
    await tester.pump();

    expect(fakeController.addCallCount, 1);
    expect(find.text('Gemmer...'), findsOneWidget);

    addGate.complete();
    await tester.pumpAndSettle();

    final project = await store.getProject('project-double-save');
    expect(project!.manualPackingList, hasLength(1));
    expect(project.manualPackingList.single.text, 'Stilladsrammer');
  });

  testWidgets('save button is enabled again after validation failure', (tester) async {
    final store = InMemoryProjectStore();
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-invalid-save',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 24, 9, 0),
      ),
    );

    await _pumpScreen(tester, store: store, projectId: 'project-invalid-save');

    await tester.tap(find.byKey(const ValueKey('manual-packing-list-add-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-text-input')), 'Stilladsrammer');
    await tester.enterText(find.byKey(const ValueKey('manual-packing-list-quantity-input')), 'xyz');
    await tester.tap(find.byKey(const ValueKey('manual-packing-list-save-button')));
    await tester.pumpAndSettle();

    final saveButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('manual-packing-list-save-button')),
    );
    expect(saveButton.onPressed, isNotNull);
    final project = await store.getProject('project-invalid-save');
    expect(project!.manualPackingList, isEmpty);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required LocalProjectStore store,
  required String projectId,
  bool watchProjectSummaries = false,
  ManualPackingListController? controllerOverride,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localProjectStoreProvider.overrideWithValue(store),
        if (controllerOverride != null)
          manualPackingListControllerProvider.overrideWithValue(controllerOverride),
        projectSessionControllerProvider.overrideWith(
          (ref) => ProjectSessionController()..openProject(projectId),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: watchProjectSummaries
              ? const _ManualPackingWithProjectsProbe()
              : const ManualPackingListScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _ManualPackingWithProjectsProbe extends ConsumerWidget {
  const _ManualPackingWithProjectsProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    return Column(
      children: [
        Expanded(child: const ManualPackingListScreen()),
        Text('projects:${projectsAsync.valueOrNull?.length ?? 0}'),
      ],
    );
  }
}

class _CountingProjectStore extends InMemoryProjectStore {
  int listProjectsCallCount = 0;

  @override
  Future<List<ProjectSummary>> listProjects() async {
    listProjectsCallCount++;
    return super.listProjects();
  }
}

class _ControlledSaveManualPackingListController extends ManualPackingListController {
  _ControlledSaveManualPackingListController({
    required InMemoryProjectStore store,
    required this.addGate,
    required this.now,
  })  : _store = store,
        super(store: store, now: () => now);

  final InMemoryProjectStore _store;
  final Completer<void> addGate;
  final DateTime now;
  int addCallCount = 0;

  @override
  Future<ManualPackingListOperationResult> addItem({
    required String projectId,
    required String text,
    required String quantity,
    required String unit,
  }) async {
    addCallCount++;
    await addGate.future;
    final project = await _store.getProject(projectId);
    if (project == null) {
      return const ManualPackingListOperationResult(
        isSuccess: false,
        message: 'Kunne ikke finde projekt.',
      );
    }

    await _store.saveProject(
      project.copyWith(
        updatedAt: now,
        manualPackingList: [
          ...project.manualPackingList,
          const ManualPackingListItem(
            id: 'controlled-item',
            text: 'Stilladsrammer',
            quantity: 40,
            unit: 'stk',
          ),
        ],
      ),
    );

    return const ManualPackingListOperationResult(
      isSuccess: true,
      message: 'Pakkelinje tilføjet.',
    );
  }
}
