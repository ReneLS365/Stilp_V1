import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/app/state/app_shell_controller.dart';
import 'package:stilp_v1/src/core/models/facade_document.dart';
import 'package:stilp_v1/src/core/models/facade_section.dart';
import 'package:stilp_v1/src/core/models/facade_storey.dart';
import 'package:stilp_v1/src/core/models/plan_side.dart';
import 'package:stilp_v1/src/core/models/plan_view_data.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/data/projects/in_memory_project_store.dart';
import 'package:stilp_v1/src/features/facade_editor/facade_editor_screen.dart';
import 'package:stilp_v1/src/features/project_session/state/project_session_controller.dart';

void main() {
  testWidgets('shows empty state when no facades exist', (tester) async {
    final store = InMemoryProjectStore();
    final project = ProjectDocument.empty(
      projectId: 'project-empty-facades',
      taskType: 'Facade test',
      now: DateTime.utc(2026, 4, 22, 10, 0),
    ).copyWith(
      planView: const PlanViewData(
        enabled: true,
        nodes: [
          PlanViewNode(id: 'n1', x: 0, y: 0),
          PlanViewNode(id: 'n2', x: 100, y: 0),
        ],
        edges: [
          PlanViewEdge(
            id: 'e1',
            fromNodeId: 'n1',
            toNodeId: 'n2',
            lengthMm: 1500,
            sideType: PlanSideType.gavl,
          ),
        ],
      ),
    );
    await store.saveProject(project);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localProjectStoreProvider.overrideWithValue(store),
          projectSessionControllerProvider.overrideWith(
            (ref) => ProjectSessionController()..openProject('project-empty-facades'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: FacadeEditorScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Ingen facader endnu'), findsOneWidget);
  });

  testWidgets('shows empty and generated grid states', (tester) async {
    final store = InMemoryProjectStore();
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-with-facades',
        taskType: 'Facade test',
        now: DateTime.utc(2026, 4, 22, 10, 0),
      ).copyWith(
        facades: const [
          FacadeDocument(
            sideId: 'e1',
            label: 'Side 1',
            planEdgeId: 'e1',
            sideOrder: 0,
            edgeLengthMm: 2000,
            sideType: PlanSideType.langside,
            eavesHeightMm: 3200,
            ridgeHeightMm: 4600,
            standingHeightM: null,
            topZoneM: 1,
            sections: [],
            storeys: [],
            markers: [],
          ),
          FacadeDocument(
            sideId: 'e2',
            label: 'Side 2',
            planEdgeId: 'e2',
            sideOrder: 1,
            edgeLengthMm: 1800,
            sideType: PlanSideType.gavl,
            eavesHeightMm: null,
            ridgeHeightMm: null,
            standingHeightM: null,
            topZoneM: 1,
            sections: [FacadeSection(id: 'sec-1', widthM: 1.5)],
            storeys: [FacadeStorey(id: 'st-1', heightM: 2.0, kind: FacadeStoreyKind.main)],
            markers: [],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localProjectStoreProvider.overrideWithValue(store),
          projectSessionControllerProvider.overrideWith(
            (ref) => ProjectSessionController()..openProject('project-with-facades'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: FacadeEditorScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Facader (2)'), findsOneWidget);
    await _scrollToSection(tester, const ValueKey('facade-metadata-card'));
    expect(_readKeyedText(const ValueKey('facade-plan-edge-label'), tester), 'Plan edge: e1');

    await _scrollToSection(tester, const ValueKey('facade-grid-card'));
    expect(
      _readKeyedText(const ValueKey('facade-grid-empty-state'), tester),
      'No grid generated yet for this facade side.',
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Side 2'));
    await tester.pumpAndSettle();

    await _scrollToSection(tester, const ValueKey('facade-metadata-card'), delta: const Offset(0, 200));
    expect(_readKeyedText(const ValueKey('facade-plan-edge-label'), tester), 'Plan edge: e2');
    await _scrollToSection(tester, const ValueKey('facade-grid-card'));
    expect(_readKeyedText(const ValueKey('facade-grid-generated-summary'), tester), '1 sections · 1 storeys');
  });

  testWidgets('applies standing height for selected facade and keeps other facade untouched', (
    tester,
  ) async {
    final store = InMemoryProjectStore();
    const projectId = 'project-standing-height';
    await store.saveProject(
      ProjectDocument.empty(
        projectId: projectId,
        taskType: 'Facade test',
        now: DateTime.utc(2026, 4, 22, 10, 0),
      ).copyWith(
        facades: const [
          FacadeDocument(
            sideId: 'e1',
            label: 'Side 1',
            planEdgeId: 'e1',
            sideOrder: 0,
            edgeLengthMm: 2000,
            sideType: PlanSideType.langside,
            eavesHeightMm: 3200,
            ridgeHeightMm: 4600,
            standingHeightM: null,
            topZoneM: 1,
            sections: [FacadeSection(id: 'sec-1', widthM: 1.5)],
            storeys: [FacadeStorey(id: 'st-1', heightM: 2.0, kind: FacadeStoreyKind.main)],
            markers: [],
          ),
          FacadeDocument(
            sideId: 'e2',
            label: 'Side 2',
            planEdgeId: 'e2',
            sideOrder: 1,
            edgeLengthMm: 1800,
            sideType: PlanSideType.gavl,
            eavesHeightMm: null,
            ridgeHeightMm: null,
            standingHeightM: null,
            topZoneM: 1,
            sections: [FacadeSection(id: 'sec-1', widthM: 1.5)],
            storeys: [FacadeStorey(id: 'st-1', heightM: 2.0, kind: FacadeStoreyKind.main)],
            markers: [],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localProjectStoreProvider.overrideWithValue(store),
          projectSessionControllerProvider.overrideWith(
            (ref) => ProjectSessionController()..openProject(projectId),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: FacadeEditorScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await _scrollToSection(tester, const ValueKey('facade-metadata-card'), delta: const Offset(0, 200));
    expect(_readKeyedText(const ValueKey('standing-height-label'), tester), 'Standing height: - m');
    expect(_readKeyedText(const ValueKey('top-zone-label'), tester), 'Top zone: - m');

    await _enterTextInSection(
      tester,
      sectionKey: const ValueKey('facade-standing-height-card'),
      inputKey: const ValueKey('standing-height-input'),
      value: '3.20',
    );
    await _tapInSection(
      tester,
      sectionKey: const ValueKey('facade-standing-height-card'),
      targetKey: const ValueKey('standing-height-apply'),
    );
    await tester.pumpAndSettle();

    await _scrollToSection(tester, const ValueKey('facade-metadata-card'), delta: const Offset(0, 200));
    expect(_readKeyedText(const ValueKey('standing-height-label'), tester), 'Standing height: 3.20 m');
    expect(_readKeyedText(const ValueKey('top-zone-label'), tester), 'Top zone: 1.00 m');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Side 2'));
    await tester.pumpAndSettle();
    await _scrollToSection(tester, const ValueKey('facade-metadata-card'), delta: const Offset(0, 200));
    expect(_readKeyedText(const ValueKey('standing-height-label'), tester), 'Standing height: - m');
    expect(_readKeyedText(const ValueKey('top-zone-label'), tester), 'Top zone: - m');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Side 1'));
    await tester.pumpAndSettle();
    await _scrollToSection(tester, const ValueKey('facade-metadata-card'), delta: const Offset(0, 200));
    expect(_readKeyedText(const ValueKey('standing-height-label'), tester), 'Standing height: 3.20 m');
    expect(_readKeyedText(const ValueKey('top-zone-label'), tester), 'Top zone: 1.00 m');
  });
}

Finder _verticalListViewFinder() => find.byKey(const ValueKey('facade-editor-vertical-scroll'));

Finder _keyedFinder(ValueKey<String> key) => find.byKey(key, skipOffstage: false);

Future<void> _scrollToSection(
  WidgetTester tester,
  ValueKey<String> sectionKey, {
  Offset delta = const Offset(0, -200),
}) async {
  final listFinder = _verticalListViewFinder();
  expect(listFinder, findsOneWidget);
  final sectionFinder = _keyedFinder(sectionKey);
  await tester.dragUntilVisible(sectionFinder, listFinder, delta);
  await tester.pumpAndSettle();
}

String? _readKeyedText(ValueKey<String> textKey, WidgetTester tester) {
  final finder = _keyedFinder(textKey);
  expect(finder, findsOneWidget);
  return tester.widget<Text>(finder).data;
}

Future<void> _enterTextInSection(
  WidgetTester tester, {
  required ValueKey<String> sectionKey,
  required ValueKey<String> inputKey,
  required String value,
}) async {
  await _scrollToSection(tester, sectionKey);
  final inputFinder = _keyedFinder(inputKey);
  await tester.ensureVisible(inputFinder);
  await tester.pumpAndSettle();
  await tester.enterText(inputFinder, value);
}

Future<void> _tapInSection(
  WidgetTester tester, {
  required ValueKey<String> sectionKey,
  required ValueKey<String> targetKey,
}) async {
  await _scrollToSection(tester, sectionKey);
  final targetFinder = _keyedFinder(targetKey);
  await tester.ensureVisible(targetFinder);
  await tester.pumpAndSettle();
  await tester.tap(targetFinder);
}
