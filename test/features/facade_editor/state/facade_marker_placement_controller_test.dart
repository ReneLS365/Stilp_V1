import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/facade_document.dart';
import 'package:stilp_v1/src/core/models/facade_marker.dart';
import 'package:stilp_v1/src/core/models/plan_side.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/data/projects/file_local_project_store.dart';
import 'package:stilp_v1/src/features/facade_editor/state/facade_marker_placement_controller.dart';

void main() {
  test('placing a marker stores it on the correct facade only', () async {
    final tempRoot = await Directory.systemTemp.createTemp('stilp_marker_state_');
    addTearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    final store = FileLocalProjectStore(
      projectsDirectory: Directory('${tempRoot.path}/projects'),
    );

    const projectId = 'marker-placement';
    await store.saveProject(
      ProjectDocument.empty(
        projectId: projectId,
        taskType: 'Facade test',
        now: DateTime.utc(2026, 4, 23, 9, 0),
      ).copyWith(
        facades: const [
          FacadeDocument(
            sideId: 'e1',
            label: 'Side 1',
            planEdgeId: 'e1',
            sideOrder: 0,
            edgeLengthMm: 5000,
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

    final controller = FacadeMarkerPlacementController(
      store: store,
      now: () => DateTime.utc(2026, 4, 23, 10, 0),
    );

    final result = await controller.placeMarker(
      projectId: projectId,
      facadeSideId: 'e1',
      markerType: FacadeMarkerType.console,
      localDx: 0.3,
      localDy: 0.6,
    );

    expect(result.isSuccess, isTrue);

    final reloaded = await store.getProject(projectId);
    final side1 = reloaded!.facades.firstWhere((facade) => facade.sideId == 'e1');
    final side2 = reloaded.facades.firstWhere((facade) => facade.sideId == 'e2');

    expect(side1.markers, hasLength(1));
    expect(side1.markers.single.type, FacadeMarkerType.console);
    expect(side1.markers.single.localDx, closeTo(0.3, 0.0001));
    expect(side1.markers.single.localDy, closeTo(0.6, 0.0001));
    expect(side2.markers, isEmpty);
  });

  test('markers restore after project reload and text notes get default text', () async {
    final tempRoot = await Directory.systemTemp.createTemp('stilp_marker_reload_');
    addTearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    final store = FileLocalProjectStore(
      projectsDirectory: Directory('${tempRoot.path}/projects'),
    );

    const projectId = 'marker-reload';
    await store.saveProject(
      ProjectDocument.empty(
        projectId: projectId,
        taskType: 'Facade test',
        now: DateTime.utc(2026, 4, 23, 9, 0),
      ).copyWith(
        facades: const [
          FacadeDocument(
            sideId: 'e1',
            label: 'Side 1',
            planEdgeId: 'e1',
            sideOrder: 0,
            edgeLengthMm: 5000,
            sideType: PlanSideType.langside,
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

    final controller = FacadeMarkerPlacementController(
      store: store,
      now: () => DateTime.utc(2026, 4, 23, 10, 0, 0, 1),
    );

    await controller.placeMarker(
      projectId: projectId,
      facadeSideId: 'e1',
      markerType: FacadeMarkerType.textNote,
      localDx: 0.95,
      localDy: -0.2,
    );

    final reloadedStore = FileLocalProjectStore(
      projectsDirectory: Directory('${tempRoot.path}/projects'),
    );
    final reloaded = await reloadedStore.getProject(projectId);

    final marker = reloaded!.facades.single.markers.single;
    expect(marker.type, FacadeMarkerType.textNote);
    expect(marker.text, 'Note');
    expect(marker.localDx, closeTo(0.95, 0.0001));
    expect(marker.localDy, closeTo(0.0, 0.0001));
  });
}
