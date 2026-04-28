import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/app/state/app_shell_controller.dart';
import 'package:stilp_v1/src/core/models/facade_document.dart';
import 'package:stilp_v1/src/core/models/facade_marker.dart';
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
      planView: PlanViewData(
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

  testWidgets('supports previous/next facade switching with index indicator and synchronized chips', (
    tester,
  ) async {
    final store = InMemoryProjectStore();
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-side-switching',
        taskType: 'Facade test',
        now: DateTime.utc(2026, 4, 22, 10, 0),
      ).copyWith(
        facades: const [
          FacadeDocument(
            sideId: 'e1',
            label: 'Side 1',
            planEdgeId: 'edge-a',
            sideOrder: 0,
            edgeLengthMm: 2000,
            sideType: PlanSideType.langside,
            eavesHeightMm: 3200,
            ridgeHeightMm: 4600,
            standingHeightM: 2.8,
            topZoneM: 1,
            sections: [FacadeSection(id: 'sec-1', widthM: 1.5)],
            storeys: [FacadeStorey(id: 'st-1', heightM: 2.0, kind: FacadeStoreyKind.main)],
            markers: [],
          ),
          FacadeDocument(
            sideId: 'e2',
            label: 'Side 2',
            planEdgeId: 'edge-b',
            sideOrder: 1,
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
            sideId: 'e3',
            label: 'Side 3',
            planEdgeId: 'edge-c',
            sideOrder: 2,
            edgeLengthMm: 2000,
            sideType: PlanSideType.gavl,
            eavesHeightMm: null,
            ridgeHeightMm: null,
            standingHeightM: 3.1,
            topZoneM: 1,
            sections: [
              FacadeSection(id: 'sec-1', widthM: 1.5),
              FacadeSection(id: 'sec-2', widthM: 1.5),
            ],
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
            (ref) => ProjectSessionController()..openProject('project-side-switching'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: FacadeEditorScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(_readKeyedText(const ValueKey('facade-side-position-indicator'), tester), '1 / 3');
    expect(
      tester.widget<IconButton>(find.byKey(const ValueKey('facade-previous-side-button'))).onPressed,
      isNull,
    );
    expect(
      tester.widget<IconButton>(find.byKey(const ValueKey('facade-next-side-button'))).onPressed,
      isNotNull,
    );
    expect(_readKeyedText(const ValueKey('facade-plan-edge-label'), tester), 'Plan edge: edge-a');
    expect(_readKeyedText(const ValueKey('standing-height-label'), tester), 'Standing height: 2.80 m');
    expect(_readKeyedText(const ValueKey('top-zone-label'), tester), 'Top zone: 1.00 m');

    await tester.tap(find.byKey(const ValueKey('facade-next-side-button')));
    await tester.pumpAndSettle();

    expect(_readKeyedText(const ValueKey('facade-side-position-indicator'), tester), '2 / 3');
    expect(
      _readKeyedText(const ValueKey('facade-plan-edge-label'), tester),
      'Plan edge: edge-b',
    );
    await _scrollToSection(tester, const ValueKey('facade-grid-card'));
    expect(
      _readKeyedText(const ValueKey('facade-grid-empty-state'), tester),
      'No grid generated yet for this facade side.',
    );
    await _scrollToSection(tester, const ValueKey('facade-metadata-card'), delta: const Offset(0, 200));
    expect(_readKeyedText(const ValueKey('standing-height-label'), tester), 'Standing height: - m');
    expect(_readKeyedText(const ValueKey('top-zone-label'), tester), 'Top zone: - m');

    await tester.tap(find.byKey(const ValueKey('facade-next-side-button')));
    await tester.pumpAndSettle();

    expect(_readKeyedText(const ValueKey('facade-side-position-indicator'), tester), '3 / 3');
    expect(
      tester.widget<IconButton>(find.byKey(const ValueKey('facade-next-side-button'))).onPressed,
      isNull,
    );
    await _scrollToSection(tester, const ValueKey('facade-grid-card'));
    expect(_readKeyedText(const ValueKey('facade-grid-generated-summary'), tester), '2 sections · 1 storeys');
    await _scrollToSection(tester, const ValueKey('facade-metadata-card'), delta: const Offset(0, 200));
    expect(_readKeyedText(const ValueKey('facade-plan-edge-label'), tester), 'Plan edge: edge-c');
    expect(_readKeyedText(const ValueKey('standing-height-label'), tester), 'Standing height: 3.10 m');
    expect(_readKeyedText(const ValueKey('top-zone-label'), tester), 'Top zone: 1.00 m');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Side 1'));
    await tester.pumpAndSettle();
    expect(_readKeyedText(const ValueKey('facade-side-position-indicator'), tester), '1 / 3');
    expect(
      tester.widget<IconButton>(find.byKey(const ValueKey('facade-previous-side-button'))).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('facade-next-side-button')));
    await tester.pumpAndSettle();
    expect(_readKeyedText(const ValueKey('facade-side-position-indicator'), tester), '2 / 3');
    expect(_readKeyedText(const ValueKey('facade-plan-edge-label'), tester), 'Plan edge: edge-b');

    await tester.tap(find.byKey(const ValueKey('facade-previous-side-button')));
    await tester.pumpAndSettle();
    expect(_readKeyedText(const ValueKey('facade-side-position-indicator'), tester), '1 / 3');
    expect(_readKeyedText(const ValueKey('facade-plan-edge-label'), tester), 'Plan edge: edge-a');
    expect(_readKeyedText(const ValueKey('standing-height-label'), tester), 'Standing height: 2.80 m');
    expect(_readKeyedText(const ValueKey('top-zone-label'), tester), 'Top zone: 1.00 m');
  });

  testWidgets('generation and standing-height inputs sync to the active facade without stale bleed', (
    tester,
  ) async {
    final store = InMemoryProjectStore();
    await store.saveProject(
      ProjectDocument.empty(
        projectId: 'project-controller-sync',
        taskType: 'Facade test',
        now: DateTime.utc(2026, 4, 22, 10, 0),
      ).copyWith(
        facades: const [
          FacadeDocument(
            sideId: 'e1',
            label: 'Side 1',
            planEdgeId: 'edge-a',
            sideOrder: 0,
            edgeLengthMm: 7700,
            sideType: PlanSideType.langside,
            eavesHeightMm: 3200,
            ridgeHeightMm: 4600,
            standingHeightM: 3.2,
            topZoneM: 1,
            sections: [
              FacadeSection(id: 'sec-1', widthM: 1.4),
              FacadeSection(id: 'sec-2', widthM: 1.6),
            ],
            storeys: [
              FacadeStorey(id: 'st-1', heightM: 2.4, kind: FacadeStoreyKind.main),
              FacadeStorey(id: 'st-2', heightM: 1.6, kind: FacadeStoreyKind.main),
            ],
            markers: [],
          ),
          FacadeDocument(
            sideId: 'e2',
            label: 'Side 2',
            planEdgeId: 'edge-b',
            sideOrder: 1,
            edgeLengthMm: 5140,
            sideType: PlanSideType.gavl,
            eavesHeightMm: null,
            ridgeHeightMm: null,
            standingHeightM: null,
            topZoneM: 0,
            sections: [],
            storeys: [],
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
            (ref) => ProjectSessionController()..openProject('project-controller-sync'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: FacadeEditorScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(_readTextFieldValue(const ValueKey('generation-sections-input'), tester), '2');
    expect(_readTextFieldValue(const ValueKey('generation-section-width-input'), tester), '1.40');
    expect(_readTextFieldValue(const ValueKey('generation-storeys-input'), tester), '2');
    expect(_readTextFieldValue(const ValueKey('generation-storey-height-input'), tester), '2.40');
    expect(_readTextFieldValue(const ValueKey('standing-height-input'), tester), '3.20');

    await _enterTextInSection(
      tester,
      sectionKey: const ValueKey('facade-generation-card'),
      inputKey: const ValueKey('generation-sections-input'),
      value: '99',
    );
    expect(_readTextFieldValue(const ValueKey('generation-sections-input'), tester), '99');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Side 2'));
    await tester.pumpAndSettle();

    expect(_readTextFieldValue(const ValueKey('generation-sections-input'), tester), '2');
    expect(_readTextFieldValue(const ValueKey('generation-section-width-input'), tester), '2.57');
    expect(_readTextFieldValue(const ValueKey('generation-storeys-input'), tester), '2');
    expect(_readTextFieldValue(const ValueKey('generation-storey-height-input'), tester), '2.00');
    expect(_readTextFieldValue(const ValueKey('standing-height-input'), tester), '');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Side 1'));
    await tester.pumpAndSettle();

    expect(_readTextFieldValue(const ValueKey('generation-sections-input'), tester), '2');
    expect(_readTextFieldValue(const ValueKey('generation-section-width-input'), tester), '1.40');
    expect(_readTextFieldValue(const ValueKey('generation-storeys-input'), tester), '2');
    expect(_readTextFieldValue(const ValueKey('generation-storey-height-input'), tester), '2.40');
    expect(_readTextFieldValue(const ValueKey('standing-height-input'), tester), '3.20');
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

  testWidgets('marker placement is facade-specific and text note gets default payload', (
    tester,
  ) async {
    final store = InMemoryProjectStore();
    const projectId = 'project-markers';
    await store.saveProject(
      ProjectDocument.empty(
        projectId: projectId,
        taskType: 'Facade test',
        now: DateTime.utc(2026, 4, 23, 10, 0),
      ).copyWith(
        facades: const [
          FacadeDocument(
            sideId: 'e1',
            label: 'Side 1',
            planEdgeId: 'e1',
            sideOrder: 0,
            edgeLengthMm: 2000,
            sideType: PlanSideType.langside,
            eavesHeightMm: null,
            ridgeHeightMm: null,
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

    await _scrollToSection(tester, const ValueKey('facade-grid-card'));
    await tester.tap(_keyedFinder(const ValueKey('marker-tool-console')));
    await tester.pumpAndSettle();
    await tester.tap(_keyedFinder(const ValueKey('facade-grid-canvas')));
    await tester.pumpAndSettle();

    var project = await store.getProject(projectId);
    var side1 = project!.facades.firstWhere((facade) => facade.sideId == 'e1');
    var side2 = project.facades.firstWhere((facade) => facade.sideId == 'e2');
    expect(side1.markers, hasLength(1));
    expect(side1.markers.single.type, FacadeMarkerType.console);
    expect(side2.markers, isEmpty);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Side 2'));
    await tester.pumpAndSettle();
    await _scrollToSection(tester, const ValueKey('facade-grid-card'));
    await tester.tap(_keyedFinder(const ValueKey('marker-tool-text_note')));
    await tester.pumpAndSettle();
    await tester.tap(_keyedFinder(const ValueKey('facade-grid-canvas')));
    await tester.pumpAndSettle();

    project = await store.getProject(projectId);
    side1 = project!.facades.firstWhere((facade) => facade.sideId == 'e1');
    side2 = project.facades.firstWhere((facade) => facade.sideId == 'e2');
    expect(side1.markers, hasLength(1));
    expect(side2.markers, hasLength(1));
    expect(side2.markers.single.type, FacadeMarkerType.textNote);
    expect(side2.markers.single.text, 'Note');
  });


  testWidgets('placement tool can place marker even when tapping existing marker hit area', (tester) async {
    final store = InMemoryProjectStore();
    const projectId = 'project-marker-place-on-hit-target';
    await store.saveProject(
      ProjectDocument.empty(
        projectId: projectId,
        taskType: 'Facade test',
        now: DateTime.utc(2026, 4, 24, 9, 0),
      ).copyWith(
        facades: const [
          FacadeDocument(
            sideId: 'e1',
            label: 'Side 1',
            planEdgeId: 'e1',
            sideOrder: 0,
            edgeLengthMm: 2000,
            sideType: PlanSideType.langside,
            eavesHeightMm: null,
            ridgeHeightMm: null,
            standingHeightM: null,
            topZoneM: 1,
            sections: [FacadeSection(id: 'sec-1', widthM: 1.0)],
            storeys: [FacadeStorey(id: 'st-1', heightM: 2.0, kind: FacadeStoreyKind.main)],
            markers: [
              FacadeMarker(
                id: 'm-existing',
                type: FacadeMarkerType.console,
                sectionIndex: 0,
                storeyIndex: 0,
                localDx: 0.5,
                localDy: 0.5,
              ),
            ],
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

    await _scrollToSection(tester, const ValueKey('facade-grid-card'));
    await tester.tap(_keyedFinder(const ValueKey('marker-tool-opening')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('facade-marker-hit-m-existing')));
    await tester.pumpAndSettle();

    final project = await store.getProject(projectId);
    final markers = project!.facades.single.markers;
    expect(markers, hasLength(2));
    expect(markers.where((marker) => marker.id == 'm-existing'), hasLength(1));
    expect(markers.where((marker) => marker.type == FacadeMarkerType.opening), hasLength(1));
  });

  testWidgets('tapping marker selects it and allows edit and delete actions', (tester) async {
    final store = InMemoryProjectStore();
    const projectId = 'project-marker-select-actions';
    await store.saveProject(
      ProjectDocument.empty(
        projectId: projectId,
        taskType: 'Facade test',
        now: DateTime.utc(2026, 4, 24, 9, 0),
      ).copyWith(
        facades: const [
          FacadeDocument(
            sideId: 'e1',
            label: 'Side 1',
            planEdgeId: 'e1',
            sideOrder: 0,
            edgeLengthMm: 2000,
            sideType: PlanSideType.langside,
            eavesHeightMm: null,
            ridgeHeightMm: null,
            standingHeightM: null,
            topZoneM: 1,
            sections: [FacadeSection(id: 'sec-1', widthM: 1.0)],
            storeys: [FacadeStorey(id: 'st-1', heightM: 2.0, kind: FacadeStoreyKind.main)],
            markers: [
              FacadeMarker(
                id: 'm-note',
                type: FacadeMarkerType.textNote,
                sectionIndex: 0,
                storeyIndex: 0,
                localDx: 0.5,
                localDy: 0.5,
                text: 'Old',
              ),
            ],
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

    await _scrollToSection(tester, const ValueKey('facade-grid-card'));
    await tester.tap(find.byKey(const ValueKey('facade-marker-hit-m-note')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('facade-marker-action-bar')), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byKey(const ValueKey('facade-marker-edit-button'))).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<FilledButton>(find.byKey(const ValueKey('facade-marker-delete-button'))).onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('facade-marker-edit-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('facade-marker-text-input')), 'Updated note');
    await tester.tap(find.byKey(const ValueKey('facade-marker-save-edit-button')));
    await tester.pumpAndSettle();

    var project = await store.getProject(projectId);
    expect(project!.facades.single.markers.single.text, 'Updated note');
    expect(find.byKey(const ValueKey('facade-marker-action-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('facade-marker-delete-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('facade-marker-delete-button')));
    await tester.pumpAndSettle();

    project = await store.getProject(projectId);
    expect(project!.facades.single.markers, isEmpty);
    expect(find.byKey(const ValueKey('facade-marker-action-bar')), findsNothing);
  });

  testWidgets('dragging selected marker persists new position on active facade only', (tester) async {
    final store = InMemoryProjectStore();
    const projectId = 'project-marker-drag';
    await store.saveProject(
      ProjectDocument.empty(
        projectId: projectId,
        taskType: 'Facade test',
        now: DateTime.utc(2026, 4, 24, 9, 0),
      ).copyWith(
        facades: const [
          FacadeDocument(
            sideId: 'e1',
            label: 'Side 1',
            planEdgeId: 'e1',
            sideOrder: 0,
            edgeLengthMm: 2000,
            sideType: PlanSideType.langside,
            eavesHeightMm: null,
            ridgeHeightMm: null,
            standingHeightM: null,
            topZoneM: 1,
            sections: [FacadeSection(id: 'sec-1', widthM: 1.0)],
            storeys: [FacadeStorey(id: 'st-1', heightM: 2.0, kind: FacadeStoreyKind.main)],
            markers: [
              FacadeMarker(
                id: 'm-move',
                type: FacadeMarkerType.console,
                sectionIndex: 0,
                storeyIndex: 0,
                localDx: 0.2,
                localDy: 0.2,
              ),
            ],
          ),
          FacadeDocument(
            sideId: 'e2',
            label: 'Side 2',
            planEdgeId: 'e2',
            sideOrder: 1,
            edgeLengthMm: 2000,
            sideType: PlanSideType.gavl,
            eavesHeightMm: null,
            ridgeHeightMm: null,
            standingHeightM: null,
            topZoneM: 1,
            sections: [FacadeSection(id: 'sec-1', widthM: 1.0)],
            storeys: [FacadeStorey(id: 'st-1', heightM: 2.0, kind: FacadeStoreyKind.main)],
            markers: [
              FacadeMarker(
                id: 'm-other',
                type: FacadeMarkerType.opening,
                sectionIndex: 0,
                storeyIndex: 0,
                localDx: 0.7,
                localDy: 0.7,
              ),
            ],
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

    await _scrollToSection(tester, const ValueKey('facade-grid-card'));
    final hitFinder = find.byKey(const ValueKey('facade-marker-hit-m-move'));
    await tester.tap(hitFinder);
    await tester.pumpAndSettle();
    await tester.drag(hitFinder, const Offset(120, 40));
    await tester.pumpAndSettle();

    var project = await store.getProject(projectId);
    final moved = project!.facades.firstWhere((facade) => facade.sideId == 'e1').markers.single;
    final other = project.facades.firstWhere((facade) => facade.sideId == 'e2').markers.single;
    expect(moved.localDx, greaterThan(0.2));
    expect(moved.localDy, greaterThan(0.2));
    expect(other.localDx, closeTo(0.7, 0.0001));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Side 2'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('facade-marker-action-bar')), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Side 1'));
    await tester.pumpAndSettle();
    project = await store.getProject(projectId);
    final movedAfterSwitch = project!.facades.firstWhere((facade) => facade.sideId == 'e1').markers.single;
    expect(movedAfterSwitch.localDx, greaterThan(0.2));
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

String _readTextFieldValue(ValueKey<String> inputKey, WidgetTester tester) {
  final finder = _keyedFinder(inputKey);
  expect(finder, findsOneWidget);
  final field = tester.widget<TextField>(finder);
  return field.controller?.text ?? '';
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
