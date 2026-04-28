import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/facade_document.dart';
import 'package:stilp_v1/src/core/models/facade_marker.dart';
import 'package:stilp_v1/src/core/models/facade_section.dart';
import 'package:stilp_v1/src/core/models/facade_storey.dart';
import 'package:stilp_v1/src/core/models/plan_side.dart';
import 'package:stilp_v1/src/core/models/plan_view_data.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/data/projects/file_local_project_store.dart';
import 'package:stilp_v1/src/data/projects/in_memory_project_store.dart';
import 'package:stilp_v1/src/features/facade_editor/state/facade_mapping_controller.dart';

void main() {
  group('FacadeMappingController', () {
    test('mapping a plan creates one facade per edge with plan order and stable labels', () async {
      final store = InMemoryProjectStore();
      const projectId = 'mapping-project';
      await store.saveProject(
        ProjectDocument.empty(
          projectId: projectId,
          taskType: 'Facade test',
          now: DateTime.utc(2026, 4, 22, 10, 0),
        ).copyWith(
          planView: PlanViewData(
            enabled: true,
            nodes: [
              PlanViewNode(id: 'n1', x: 0, y: 0),
              PlanViewNode(id: 'n2', x: 100, y: 0),
              PlanViewNode(id: 'n3', x: 100, y: 50),
            ],
            edges: [
              PlanViewEdge(
                id: 'e1',
                fromNodeId: 'n1',
                toNodeId: 'n2',
                lengthMm: 1000,
                sideType: PlanSideType.langside,
              ),
              PlanViewEdge(
                id: 'e2',
                fromNodeId: 'n2',
                toNodeId: 'n3',
                lengthMm: 500,
                sideType: PlanSideType.gavl,
              ),
            ],
          ),
        ),
      );

      final controller = FacadeMappingController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 11, 0),
      );

      final result = await controller.mapFromPlan(projectId);
      final updated = await store.getProject(projectId);

      expect(result.isSuccess, isTrue);
      expect(updated!.facades, hasLength(2));
      expect(updated.facades.map((facade) => facade.sideId), <String>['e1', 'e2']);
      expect(updated.facades.map((facade) => facade.label), <String>['Side 1', 'Side 2']);
      expect(updated.facades.map((facade) => facade.sideOrder), <int>[0, 1]);
    });

    test('remapping preserves existing facade state for matching side ids', () async {
      final store = InMemoryProjectStore();
      const projectId = 'preserve-project';
      await store.saveProject(
        ProjectDocument.empty(
          projectId: projectId,
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
                lengthMm: 1400,
                sideType: PlanSideType.andet,
              ),
            ],
          ),
          facades: const [
            FacadeDocument(
              sideId: 'e1',
              label: 'Custom',
              planEdgeId: 'e1',
              sideOrder: 4,
              edgeLengthMm: 1000,
              sideType: PlanSideType.gavl,
              eavesHeightMm: null,
              ridgeHeightMm: null,
              standingHeightM: 5.5,
              topZoneM: 1,
              sections: [FacadeSection(id: 'sec-1', widthM: 2.57)],
              storeys: [FacadeStorey(id: 'st-1', heightM: 2, kind: FacadeStoreyKind.main)],
              markers: [
                FacadeMarker(
                  id: 'm-1',
                  type: FacadeMarkerType.textNote,
                  sectionIndex: 0,
                  storeyIndex: 0,
                  text: 'keep me',
                ),
              ],
            ),
          ],
        ),
      );

      final controller = FacadeMappingController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 11, 0),
      );

      await controller.mapFromPlan(projectId);
      final updated = await store.getProject(projectId);
      final facade = updated!.facades.single;

      expect(facade.sideId, 'e1');
      expect(facade.label, 'Side 1');
      expect(facade.edgeLengthMm, 1400);
      expect(facade.sections, hasLength(1));
      expect(facade.storeys, hasLength(1));
      expect(facade.markers, hasLength(1));
      expect(facade.standingHeightM, 5.5);
      expect(facade.markers.single.text, 'keep me');
    });

    test('remapping removes facades where side no longer exists in plan', () async {
      final store = InMemoryProjectStore();
      const projectId = 'remove-orphan-project';
      await store.saveProject(
        ProjectDocument.empty(
          projectId: projectId,
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
                id: 'e2',
                fromNodeId: 'n1',
                toNodeId: 'n2',
                lengthMm: 1000,
                sideType: PlanSideType.andet,
              ),
            ],
          ),
          facades: [
            FacadeDocument.emptyForSide(sideId: 'e1', label: 'Old side'),
            FacadeDocument.emptyForSide(sideId: 'e2', label: 'Current side'),
          ],
        ),
      );

      final controller = FacadeMappingController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 11, 0),
      );

      await controller.mapFromPlan(projectId);
      final updated = await store.getProject(projectId);

      expect(updated!.facades, hasLength(1));
      expect(updated.facades.single.sideId, 'e2');
    });

    test('persisted project reload restores mapped facades', () async {
      final tempRoot = await Directory.systemTemp.createTemp('stilp_facade_map_');
      addTearDown(() async {
        if (await tempRoot.exists()) {
          await tempRoot.delete(recursive: true);
        }
      });

      final projectsDirectory = Directory('${tempRoot.path}/projects');
      final store = FileLocalProjectStore(projectsDirectory: projectsDirectory);
      const projectId = 'persist-facades-project';

      await store.saveProject(
        ProjectDocument.empty(
          projectId: projectId,
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
                lengthMm: 2000,
                sideType: PlanSideType.langside,
                eavesHeightMm: 3300,
                ridgeHeightMm: 5000,
              ),
            ],
          ),
        ),
      );

      final controller = FacadeMappingController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 12, 0),
      );
      await controller.mapFromPlan(projectId);

      final freshStore = FileLocalProjectStore(projectsDirectory: projectsDirectory);
      final reloaded = await freshStore.getProject(projectId);

      expect(reloaded!.facades, hasLength(1));
      final facade = reloaded.facades.single;
      expect(facade.sideId, 'e1');
      expect(facade.label, 'Side 1');
      expect(facade.edgeLengthMm, 2000);
      expect(facade.eavesHeightMm, 3300);
      expect(facade.ridgeHeightMm, isNull);
    });
  });
}
