import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/facade_document.dart';
import 'package:stilp_v1/src/core/models/facade_section.dart';
import 'package:stilp_v1/src/core/models/facade_storey.dart';
import 'package:stilp_v1/src/core/models/plan_side.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/data/projects/file_local_project_store.dart';
import 'package:stilp_v1/src/features/facade_editor/state/facade_grid_adjustment_controller.dart';
import 'package:stilp_v1/src/features/facade_editor/state/facade_grid_generation_controller.dart';
import 'package:stilp_v1/src/features/facade_editor/state/facade_standing_height_controller.dart';

void main() {
  test('reloading project restores independent facade states per side', () async {
    final tempRoot = await Directory.systemTemp.createTemp('stilp_facade_state_reload_');
    addTearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    final store = FileLocalProjectStore(
      projectsDirectory: Directory('${tempRoot.path}/projects'),
    );

    const projectId = 'facade-state-reload';
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
            edgeLengthMm: 5140,
            sideType: PlanSideType.langside,
            eavesHeightMm: null,
            ridgeHeightMm: null,
            standingHeightM: null,
            topZoneM: 0,
            sections: [],
            storeys: [],
            markers: [],
          ),
          FacadeDocument(
            sideId: 'e2',
            label: 'Side 2',
            planEdgeId: 'e2',
            sideOrder: 1,
            edgeLengthMm: 3000,
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

    final gridGenerationController = FacadeGridGenerationController(
      store: store,
      now: () => DateTime.utc(2026, 4, 22, 12, 0),
    );
    final gridAdjustmentController = FacadeGridAdjustmentController(
      store: store,
      now: () => DateTime.utc(2026, 4, 22, 12, 1),
    );
    final standingHeightController = FacadeStandingHeightController(
      store: store,
      now: () => DateTime.utc(2026, 4, 22, 12, 2),
    );

    await gridGenerationController.generateGrid(
      projectId: projectId,
      facadeSideId: 'e1',
      basisInput: const FacadeGridBasisInput(
        numberOfSections: 3,
        defaultSectionWidthM: 2.0,
        numberOfStoreys: 2,
        defaultStoreyHeightM: 2.0,
      ),
    );
    await gridAdjustmentController.saveAdjustedGrid(
      projectId: projectId,
      facadeSideId: 'e1',
      sections: const [
        FacadeSection(id: 'sec-1', widthM: 2.4),
        FacadeSection(id: 'sec-2', widthM: 1.4),
        FacadeSection(id: 'sec-3', widthM: 2.2),
      ],
      storeys: const [
        FacadeStorey(id: 'st-1', heightM: 2.4, kind: FacadeStoreyKind.main),
        FacadeStorey(id: 'st-2', heightM: 1.6, kind: FacadeStoreyKind.main),
      ],
    );
    await standingHeightController.saveStandingHeight(
      projectId: projectId,
      facadeSideId: 'e1',
      standingHeightM: 3.2,
    );

    await standingHeightController.saveStandingHeight(
      projectId: projectId,
      facadeSideId: 'e2',
      standingHeightM: null,
    );

    final reloadedStore = FileLocalProjectStore(
      projectsDirectory: Directory('${tempRoot.path}/projects'),
    );
    final reloaded = await reloadedStore.getProject(projectId);

    final side1 = reloaded!.facades.firstWhere((facade) => facade.sideId == 'e1');
    final side2 = reloaded.facades.firstWhere((facade) => facade.sideId == 'e2');

    expect(side1.sideOrder, 0);
    expect(side2.sideOrder, 1);

    expect(side1.sections.map((section) => section.widthM), [2.4, 1.4, 2.2]);
    expect(side1.storeys.map((storey) => storey.heightM), [2.4, 1.6]);
    expect(side1.standingHeightM, closeTo(3.2, 0.0001));
    expect(side1.topZoneM, facadeTopZoneHeightM);

    expect(side2.sections, isEmpty);
    expect(side2.storeys, isEmpty);
    expect(side2.standingHeightM, isNull);
    expect(side2.topZoneM, 0);
  });
}
