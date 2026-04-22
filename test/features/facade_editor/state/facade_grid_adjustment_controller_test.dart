import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/facade_document.dart';
import 'package:stilp_v1/src/core/models/facade_section.dart';
import 'package:stilp_v1/src/core/models/facade_storey.dart';
import 'package:stilp_v1/src/core/models/plan_side.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/data/projects/file_local_project_store.dart';
import 'package:stilp_v1/src/data/projects/in_memory_project_store.dart';
import 'package:stilp_v1/src/features/facade_editor/state/facade_grid_adjustment_controller.dart';

void main() {
  group('FacadeGridAdjustmentController', () {
    test('resizing a vertical divider updates adjacent section widths', () {
      final sections = const [
        FacadeSection(id: 's1', widthM: 1.0),
        FacadeSection(id: 's2', widthM: 1.0),
        FacadeSection(id: 's3', widthM: 1.0),
      ];

      final updated = FacadeGridAdjustmentController.resizeSectionsAtDivider(
        sections: sections,
        dividerIndex: 1,
        deltaM: 0.2,
      );

      expect(updated[0].widthM, 1.0);
      expect(updated[1].widthM, closeTo(1.2, 0.0001));
      expect(updated[2].widthM, closeTo(0.8, 0.0001));
    });

    test('resizing a horizontal divider updates adjacent storey heights', () {
      final storeys = const [
        FacadeStorey(id: 'st1', heightM: 2.0, kind: FacadeStoreyKind.main),
        FacadeStorey(id: 'st2', heightM: 2.0, kind: FacadeStoreyKind.main),
      ];

      final updated = FacadeGridAdjustmentController.resizeStoreysAtDivider(
        storeys: storeys,
        dividerIndex: 0,
        deltaM: -0.3,
      );

      expect(updated[0].heightM, closeTo(1.7, 0.0001));
      expect(updated[1].heightM, closeTo(2.3, 0.0001));
    });

    test('total width is preserved after vertical adjustment', () {
      final sections = const [
        FacadeSection(id: 's1', widthM: 1.2),
        FacadeSection(id: 's2', widthM: 0.8),
      ];

      final totalBefore = sections.fold<double>(0, (sum, section) => sum + section.widthM);
      final updated = FacadeGridAdjustmentController.resizeSectionsAtDivider(
        sections: sections,
        dividerIndex: 0,
        deltaM: 0.15,
      );
      final totalAfter = updated.fold<double>(0, (sum, section) => sum + section.widthM);

      expect(totalAfter, closeTo(totalBefore, 0.0001));
    });

    test('total height is preserved after horizontal adjustment', () {
      final storeys = const [
        FacadeStorey(id: 'st1', heightM: 1.0, kind: FacadeStoreyKind.main),
        FacadeStorey(id: 'st2', heightM: 2.0, kind: FacadeStoreyKind.main),
        FacadeStorey(id: 'st3', heightM: 3.0, kind: FacadeStoreyKind.main),
      ];

      final totalBefore = storeys.fold<double>(0, (sum, storey) => sum + storey.heightM);
      final updated = FacadeGridAdjustmentController.resizeStoreysAtDivider(
        storeys: storeys,
        dividerIndex: 1,
        deltaM: 0.4,
      );
      final totalAfter = updated.fold<double>(0, (sum, storey) => sum + storey.heightM);

      expect(totalAfter, closeTo(totalBefore, 0.0001));
    });

    test('minimum size clamp works for sections and storeys', () {
      final sections = const [
        FacadeSection(id: 's1', widthM: 0.4),
        FacadeSection(id: 's2', widthM: 0.6),
      ];
      final storeys = const [
        FacadeStorey(id: 'st1', heightM: 0.35, kind: FacadeStoreyKind.main),
        FacadeStorey(id: 'st2', heightM: 0.65, kind: FacadeStoreyKind.main),
      ];

      final clampedSections = FacadeGridAdjustmentController.resizeSectionsAtDivider(
        sections: sections,
        dividerIndex: 0,
        deltaM: -0.4,
      );
      final clampedStoreys = FacadeGridAdjustmentController.resizeStoreysAtDivider(
        storeys: storeys,
        dividerIndex: 0,
        deltaM: -0.2,
      );

      expect(clampedSections[0].widthM, closeTo(0.3, 0.0001));
      expect(clampedSections[1].widthM, closeTo(0.7, 0.0001));
      expect(clampedStoreys[0].heightM, closeTo(0.3, 0.0001));
      expect(clampedStoreys[1].heightM, closeTo(0.7, 0.0001));
    });

    test('persisted facade reload restores adjusted dimensions', () async {
      final tempRoot = await Directory.systemTemp.createTemp('stilp_adjust_grid_');
      addTearDown(() async {
        if (await tempRoot.exists()) {
          await tempRoot.delete(recursive: true);
        }
      });

      final store = FileLocalProjectStore(
        projectsDirectory: Directory('${tempRoot.path}/projects'),
      );
      const projectId = 'adjust-persist-project';
      await store.saveProject(_project(projectId));

      final controller = FacadeGridAdjustmentController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 12, 0),
      );

      await controller.saveAdjustedGrid(
        projectId: projectId,
        facadeSideId: 'e1',
        sections: const [
          FacadeSection(id: 's1', widthM: 1.4),
          FacadeSection(id: 's2', widthM: 0.6),
        ],
        storeys: const [
          FacadeStorey(id: 'st1', heightM: 2.2, kind: FacadeStoreyKind.main),
          FacadeStorey(id: 'st2', heightM: 1.8, kind: FacadeStoreyKind.main),
        ],
      );

      final reloadedStore = FileLocalProjectStore(
        projectsDirectory: Directory('${tempRoot.path}/projects'),
      );
      final reloaded = await reloadedStore.getProject(projectId);
      final facade = reloaded!.facades.firstWhere((value) => value.sideId == 'e1');

      expect(facade.sections.map((section) => section.widthM), [1.4, 0.6]);
      expect(facade.storeys.map((storey) => storey.heightM), [2.2, 1.8]);
    });

    test('adjusting one facade does not overwrite another facade', () async {
      final store = InMemoryProjectStore();
      const projectId = 'adjust-isolation-project';
      await store.saveProject(_project(projectId));

      final controller = FacadeGridAdjustmentController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 12, 0),
      );

      await controller.saveAdjustedGrid(
        projectId: projectId,
        facadeSideId: 'e1',
        sections: const [
          FacadeSection(id: 's1', widthM: 1.1),
          FacadeSection(id: 's2', widthM: 0.9),
        ],
        storeys: const [
          FacadeStorey(id: 'st1', heightM: 2.1, kind: FacadeStoreyKind.main),
          FacadeStorey(id: 'st2', heightM: 1.9, kind: FacadeStoreyKind.main),
        ],
      );

      final updated = await store.getProject(projectId);
      final facade1 = updated!.facades.firstWhere((facade) => facade.sideId == 'e1');
      final facade2 = updated.facades.firstWhere((facade) => facade.sideId == 'e2');

      expect(facade1.sections.map((section) => section.widthM), [1.1, 0.9]);
      expect(facade2.sections.map((section) => section.widthM), [1.0, 1.0]);
      expect(facade2.storeys.map((storey) => storey.heightM), [2.0, 2.0]);
    });
  });
}

ProjectDocument _project(String projectId) {
  return ProjectDocument.empty(
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
        eavesHeightMm: null,
        ridgeHeightMm: null,
        standingHeightM: null,
        topZoneM: 1,
        sections: [
          FacadeSection(id: 's1', widthM: 1.0),
          FacadeSection(id: 's2', widthM: 1.0),
        ],
        storeys: [
          FacadeStorey(id: 'st1', heightM: 2.0, kind: FacadeStoreyKind.main),
          FacadeStorey(id: 'st2', heightM: 2.0, kind: FacadeStoreyKind.main),
        ],
        markers: [],
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
        sections: [
          FacadeSection(id: 's1', widthM: 1.0),
          FacadeSection(id: 's2', widthM: 1.0),
        ],
        storeys: [
          FacadeStorey(id: 'st1', heightM: 2.0, kind: FacadeStoreyKind.main),
          FacadeStorey(id: 'st2', heightM: 2.0, kind: FacadeStoreyKind.main),
        ],
        markers: [],
      ),
    ],
  );
}
