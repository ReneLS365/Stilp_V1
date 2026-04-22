import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/app/state/app_shell_controller.dart';
import 'package:stilp_v1/src/core/models/facade_document.dart';
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
        child: const MaterialApp(home: FacadeEditorScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Ingen facader endnu'), findsOneWidget);
  });

  testWidgets('shows generated facades list and details', (tester) async {
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
            (ref) => ProjectSessionController()..openProject('project-with-facades'),
          ),
        ],
        child: const MaterialApp(home: FacadeEditorScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Facader (2)'), findsOneWidget);
    expect(find.text('Side 1'), findsWidgets);
    expect(find.text('Plan edge: e1'), findsOneWidget);
    expect(find.text('Length: 2.00 m'), findsOneWidget);
  });
}
