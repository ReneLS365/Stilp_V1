import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/facade_document.dart';
import 'package:stilp_v1/src/core/models/plan_side.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/data/projects/file_local_project_store.dart';
import 'package:stilp_v1/src/data/projects/in_memory_project_store.dart';
import 'package:stilp_v1/src/features/facade_editor/state/facade_grid_generation_controller.dart';

void main() {
  group('FacadeGridGenerationController', () {
    test('generating grid creates expected number of sections and storeys', () async {
      final store = InMemoryProjectStore();
      const projectId = 'grid-count-project';
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
              topZoneM: 1,
              sections: [],
              storeys: [],
              markers: [],
            ),
          ],
        ),
      );

      final controller = FacadeGridGenerationController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 12, 0),
      );

      final result = await controller.generateGrid(
        projectId: projectId,
        facadeSideId: 'e1',
        basisInput: const FacadeGridBasisInput(
          numberOfSections: 3,
          defaultSectionWidthM: 2.57,
          numberOfStoreys: 2,
          defaultStoreyHeightM: 2.0,
        ),
      );

      final updated = await store.getProject(projectId);
      final facade = updated!.facades.single;

      expect(result.isSuccess, isTrue);
      expect(facade.sections, hasLength(3));
      expect(facade.storeys, hasLength(2));
    });

    test('generated grid persists after project reload', () async {
      final tempRoot = await Directory.systemTemp.createTemp('stilp_facade_grid_');
      addTearDown(() async {
        if (await tempRoot.exists()) {
          await tempRoot.delete(recursive: true);
        }
      });

      final store = FileLocalProjectStore(
        projectsDirectory: Directory('${tempRoot.path}/projects'),
      );
      const projectId = 'grid-persist-project';

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
              topZoneM: 1,
              sections: [],
              storeys: [],
              markers: [],
            ),
          ],
        ),
      );

      final controller = FacadeGridGenerationController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 12, 0),
      );
      await controller.generateGrid(
        projectId: projectId,
        facadeSideId: 'e1',
        basisInput: const FacadeGridBasisInput(
          numberOfSections: 4,
          defaultSectionWidthM: 2.0,
          numberOfStoreys: 3,
          defaultStoreyHeightM: 1.8,
        ),
      );

      final reloadedStore = FileLocalProjectStore(
        projectsDirectory: Directory('${tempRoot.path}/projects'),
      );
      final reloaded = await reloadedStore.getProject(projectId);

      expect(reloaded!.facades.single.sections, hasLength(4));
      expect(reloaded.facades.single.storeys, hasLength(3));
    });

    test('generating one facade does not overwrite another facade', () async {
      final store = InMemoryProjectStore();
      const projectId = 'grid-isolation-project';
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
              edgeLengthMm: 3000,
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

      final controller = FacadeGridGenerationController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 12, 0),
      );
      await controller.generateGrid(
        projectId: projectId,
        facadeSideId: 'e1',
        basisInput: const FacadeGridBasisInput(
          numberOfSections: 3,
          defaultSectionWidthM: 2.57,
          numberOfStoreys: 2,
          defaultStoreyHeightM: 2.0,
        ),
      );

      final updated = await store.getProject(projectId);
      final facade1 = updated!.facades.firstWhere((facade) => facade.sideId == 'e1');
      final facade2 = updated.facades.firstWhere((facade) => facade.sideId == 'e2');

      expect(facade1.sections, hasLength(3));
      expect(facade1.storeys, hasLength(2));
      expect(facade2.sections, isEmpty);
      expect(facade2.storeys, isEmpty);
    });
  });
}
