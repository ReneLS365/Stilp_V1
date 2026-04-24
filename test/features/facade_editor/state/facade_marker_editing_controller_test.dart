import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/facade_document.dart';
import 'package:stilp_v1/src/core/models/facade_marker.dart';
import 'package:stilp_v1/src/core/models/plan_side.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/data/projects/file_local_project_store.dart';
import 'package:stilp_v1/src/features/facade_editor/state/facade_marker_editing_controller.dart';

void main() {
  test('moving marker updates only selected marker coordinates', () async {
    final seeded = await _seedStore(projectId: 'marker-move');
    final store = seeded.store;
    final controller = FacadeMarkerEditingController(
      store: store,
      now: () => DateTime.utc(2026, 4, 24, 11, 0),
    );

    final result = await controller.moveMarker(
      projectId: 'marker-move',
      facadeSideId: 'e1',
      markerId: 'm-1',
      localDx: 0.82,
      localDy: 0.73,
    );

    expect(result.isSuccess, isTrue);

    final project = await store.getProject('marker-move');
    final side1 = project!.facades.firstWhere((facade) => facade.sideId == 'e1');
    final moved = side1.markers.firstWhere((marker) => marker.id == 'm-1');
    final untouched = side1.markers.firstWhere((marker) => marker.id == 'm-2');
    final side2 = project.facades.firstWhere((facade) => facade.sideId == 'e2');

    expect(moved.localDx, closeTo(0.82, 0.0001));
    expect(moved.localDy, closeTo(0.73, 0.0001));
    expect(untouched.localDx, closeTo(0.20, 0.0001));
    expect(untouched.localDy, closeTo(0.30, 0.0001));
    expect(side2.markers.single.localDx, closeTo(0.50, 0.0001));
  });

  test('editing text note updates only selected marker text', () async {
    final seeded = await _seedStore(projectId: 'marker-edit-text');
    final store = seeded.store;
    final controller = FacadeMarkerEditingController(
      store: store,
      now: () => DateTime.utc(2026, 4, 24, 11, 1),
    );

    final result = await controller.updateTextNote(
      projectId: 'marker-edit-text',
      facadeSideId: 'e1',
      markerId: 'm-2',
      text: 'Updated note',
    );

    expect(result.isSuccess, isTrue);

    final project = await store.getProject('marker-edit-text');
    final side1 = project!.facades.firstWhere((facade) => facade.sideId == 'e1');
    final edited = side1.markers.firstWhere((marker) => marker.id == 'm-2');
    final untouched = side1.markers.firstWhere((marker) => marker.id == 'm-1');

    expect(edited.text, 'Updated note');
    expect(untouched.text, isNull);
  });

  test('deleting marker removes only selected marker', () async {
    final seeded = await _seedStore(projectId: 'marker-delete');
    final store = seeded.store;
    final controller = FacadeMarkerEditingController(
      store: store,
      now: () => DateTime.utc(2026, 4, 24, 11, 2),
    );

    final result = await controller.deleteMarker(
      projectId: 'marker-delete',
      facadeSideId: 'e1',
      markerId: 'm-1',
    );

    expect(result.isSuccess, isTrue);

    final project = await store.getProject('marker-delete');
    final side1 = project!.facades.firstWhere((facade) => facade.sideId == 'e1');
    final side2 = project.facades.firstWhere((facade) => facade.sideId == 'e2');

    expect(side1.markers.map((marker) => marker.id), ['m-2']);
    expect(side2.markers.map((marker) => marker.id), ['m-3']);
  });

  test('marker edits persist after project reload', () async {
    final seeded = await _seedStore(projectId: 'marker-reload');
    final store = seeded.store;
    final controller = FacadeMarkerEditingController(
      store: store,
      now: () => DateTime.utc(2026, 4, 24, 11, 3),
    );

    await controller.moveMarker(
      projectId: 'marker-reload',
      facadeSideId: 'e1',
      markerId: 'm-1',
      localDx: 0.91,
      localDy: 0.09,
    );
    await controller.updateTextNote(
      projectId: 'marker-reload',
      facadeSideId: 'e1',
      markerId: 'm-2',
      text: 'Persisted',
    );
    await controller.deleteMarker(
      projectId: 'marker-reload',
      facadeSideId: 'e1',
      markerId: 'm-1',
    );

    final reloadedStore = FileLocalProjectStore(
      projectsDirectory: Directory('${seeded.projectsDirectory.path}'),
    );
    final project = await reloadedStore.getProject('marker-reload');

    final side1 = project!.facades.firstWhere((facade) => facade.sideId == 'e1');
    expect(side1.markers, hasLength(1));
    expect(side1.markers.single.id, 'm-2');
    expect(side1.markers.single.text, 'Persisted');
  });

  test('marker edits do not affect markers on other facades', () async {
    final seeded = await _seedStore(projectId: 'marker-cross-facade');
    final store = seeded.store;
    final controller = FacadeMarkerEditingController(
      store: store,
      now: () => DateTime.utc(2026, 4, 24, 11, 4),
    );

    await controller.moveMarker(
      projectId: 'marker-cross-facade',
      facadeSideId: 'e1',
      markerId: 'm-1',
      localDx: 0.44,
      localDy: 0.66,
    );

    final project = await store.getProject('marker-cross-facade');
    final side2 = project!.facades.firstWhere((facade) => facade.sideId == 'e2');

    expect(side2.markers.single.id, 'm-3');
    expect(side2.markers.single.localDx, closeTo(0.50, 0.0001));
    expect(side2.markers.single.localDy, closeTo(0.50, 0.0001));
  });
}

Future<_SeededStore> _seedStore({required String projectId}) async {
  final tempRoot = await Directory.systemTemp.createTemp('stilp_marker_editing_');
  addTearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  final store = FileLocalProjectStore(
    projectsDirectory: Directory('${tempRoot.path}/projects'),
  );

  await store.saveProject(
    ProjectDocument.empty(
      projectId: projectId,
      taskType: 'Facade marker edit',
      now: DateTime.utc(2026, 4, 24, 10, 0),
    ).copyWith(
      facades: const [
        FacadeDocument(
          sideId: 'e1',
          label: 'Side 1',
          planEdgeId: 'e1',
          sideOrder: 0,
          edgeLengthMm: 3000,
          sideType: PlanSideType.langside,
          eavesHeightMm: null,
          ridgeHeightMm: null,
          standingHeightM: null,
          topZoneM: 1,
          sections: [],
          storeys: [],
          markers: [
            FacadeMarker(
              id: 'm-1',
              type: FacadeMarkerType.console,
              sectionIndex: 0,
              storeyIndex: 0,
              localDx: 0.10,
              localDy: 0.10,
            ),
            FacadeMarker(
              id: 'm-2',
              type: FacadeMarkerType.textNote,
              sectionIndex: 0,
              storeyIndex: 0,
              localDx: 0.20,
              localDy: 0.30,
              text: 'Original',
            ),
          ],
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
          markers: [
            FacadeMarker(
              id: 'm-3',
              type: FacadeMarkerType.opening,
              sectionIndex: 0,
              storeyIndex: 0,
              localDx: 0.50,
              localDy: 0.50,
            ),
          ],
        ),
      ],
    ),
  );

  return _SeededStore(
    store: store,
    projectsDirectory: Directory('${tempRoot.path}/projects'),
  );
}

class _SeededStore {
  const _SeededStore({
    required this.store,
    required this.projectsDirectory,
  });

  final FileLocalProjectStore store;
  final Directory projectsDirectory;
}
