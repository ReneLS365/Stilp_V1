import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/facade_document.dart';
import 'package:stilp_v1/src/core/models/facade_section.dart';
import 'package:stilp_v1/src/core/models/facade_storey.dart';
import 'package:stilp_v1/src/core/models/plan_side.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/core/models/project_summary.dart';
import 'package:stilp_v1/src/data/projects/file_local_project_store.dart';
import 'package:stilp_v1/src/data/projects/in_memory_project_store.dart';
import 'package:stilp_v1/src/data/projects/local_project_store.dart';
import 'package:stilp_v1/src/data/projects/project_mutation_queue.dart';
import 'package:stilp_v1/src/features/facade_editor/facade_standing_height_input_parser.dart';
import 'package:stilp_v1/src/features/facade_editor/state/facade_grid_adjustment_controller.dart';
import 'package:stilp_v1/src/features/facade_editor/state/facade_standing_height_controller.dart';

void main() {
  group('FacadeStandingHeightController', () {
    test('setting standing height persists to selected facade', () async {
      final store = InMemoryProjectStore();
      const projectId = 'standing-height-set';
      await store.saveProject(_project(projectId));

      final controller = FacadeStandingHeightController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 12, 0),
      );

      await controller.saveStandingHeight(
        projectId: projectId,
        facadeSideId: 'e1',
        standingHeightM: 3.2,
      );

      final updated = await store.getProject(projectId);
      final facade = updated!.facades.firstWhere((value) => value.sideId == 'e1');

      expect(facade.standingHeightM, closeTo(3.2, 0.0001));
      expect(facade.topZoneM, facadeTopZoneHeightM);
    });

    test('clearing standing height clears standingHeightM and disables top zone', () async {
      final store = InMemoryProjectStore();
      const projectId = 'standing-height-clear';
      await store.saveProject(_project(projectId).copyWith(
        facades: [
          _project(projectId).facades.first.copyWith(
            standingHeightM: 3.0,
            topZoneM: facadeTopZoneHeightM,
          ),
          _project(projectId).facades[1],
        ],
      ));

      final controller = FacadeStandingHeightController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 12, 0),
      );

      await controller.saveStandingHeight(
        projectId: projectId,
        facadeSideId: 'e1',
        standingHeightM: null,
      );

      final updated = await store.getProject(projectId);
      final facade = updated!.facades.firstWhere((value) => value.sideId == 'e1');

      expect(facade.standingHeightM, isNull);
      expect(facade.topZoneM, 0);
    });

    test('invalid non-empty input does not overwrite stored standing height', () async {
      final store = InMemoryProjectStore();
      const projectId = 'standing-height-invalid';
      await store.saveProject(_project(projectId).copyWith(
        facades: [
          _project(projectId).facades.first.copyWith(
            standingHeightM: 2.8,
            topZoneM: facadeTopZoneHeightM,
          ),
          _project(projectId).facades[1],
        ],
      ));

      final parseResult = parseFacadeStandingHeightInputM('abc');
      expect(parseResult.isValid, isFalse);

      final updated = await store.getProject(projectId);
      final facade = updated!.facades.firstWhere((value) => value.sideId == 'e1');

      expect(facade.standingHeightM, closeTo(2.8, 0.0001));
      expect(facade.topZoneM, facadeTopZoneHeightM);
    });

    test('updating one facade does not overwrite another facade', () async {
      final store = InMemoryProjectStore();
      const projectId = 'standing-height-isolation';
      await store.saveProject(_project(projectId));

      final controller = FacadeStandingHeightController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 12, 0),
      );

      await controller.saveStandingHeight(
        projectId: projectId,
        facadeSideId: 'e1',
        standingHeightM: 3.0,
      );

      final updated = await store.getProject(projectId);
      final facade1 = updated!.facades.firstWhere((value) => value.sideId == 'e1');
      final facade2 = updated.facades.firstWhere((value) => value.sideId == 'e2');

      expect(facade1.standingHeightM, closeTo(3.0, 0.0001));
      expect(facade1.topZoneM, facadeTopZoneHeightM);
      expect(facade2.standingHeightM, isNull);
      expect(facade2.topZoneM, 1);
    });

    test('reloading project restores persisted standing height and top zone values', () async {
      final tempRoot = await Directory.systemTemp.createTemp('stilp_standing_height_');
      addTearDown(() async {
        if (await tempRoot.exists()) {
          await tempRoot.delete(recursive: true);
        }
      });

      final store = FileLocalProjectStore(
        projectsDirectory: Directory('${tempRoot.path}/projects'),
      );
      const projectId = 'standing-height-reload';
      await store.saveProject(_project(projectId));

      final controller = FacadeStandingHeightController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 12, 0),
      );

      await controller.saveStandingHeight(
        projectId: projectId,
        facadeSideId: 'e1',
        standingHeightM: 3.4,
      );

      final reloadedStore = FileLocalProjectStore(
        projectsDirectory: Directory('${tempRoot.path}/projects'),
      );
      final reloaded = await reloadedStore.getProject(projectId);
      final facade = reloaded!.facades.firstWhere((value) => value.sideId == 'e1');

      expect(facade.standingHeightM, closeTo(3.4, 0.0001));
      expect(facade.topZoneM, facadeTopZoneHeightM);
    });

    test('overlapping standing-height saves are serialized and keep latest value', () async {
      const projectId = 'standing-height-serialized';
      final store = _ControlledSaveProjectStore(_project(projectId));
      final controller = FacadeStandingHeightController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 12, 0),
      );

      final firstSave = controller.saveStandingHeight(
        projectId: projectId,
        facadeSideId: 'e1',
        standingHeightM: 2.6,
      );
      final secondSave = controller.saveStandingHeight(
        projectId: projectId,
        facadeSideId: 'e1',
        standingHeightM: 3.1,
      );

      await Future<void>.delayed(Duration.zero);
      store.releaseSave(1);
      store.releaseSave(0);

      await Future.wait([firstSave, secondSave]);

      final reloaded = await store.getProject(projectId);
      final facade = reloaded!.facades.firstWhere((value) => value.sideId == 'e1');

      expect(facade.standingHeightM, closeTo(3.1, 0.0001));
      expect(facade.topZoneM, facadeTopZoneHeightM);
    });

    test('standing-height save is serialized with grid save for same project', () async {
      const projectId = 'standing-height-grid-serialized';
      final store = _ControlledSaveProjectStore(_project(projectId));
      final queue = ProjectMutationQueue();
      final gridController = FacadeGridAdjustmentController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 12, 0),
        mutationQueue: queue,
      );
      final standingController = FacadeStandingHeightController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 12, 0),
        mutationQueue: queue,
      );

      final gridSave = gridController.saveAdjustedGrid(
        projectId: projectId,
        facadeSideId: 'e1',
        sections: const [
          FacadeSection(id: 's1', widthM: 1.25),
          FacadeSection(id: 's2', widthM: 0.75),
        ],
        storeys: const [
          FacadeStorey(id: 'st1', heightM: 2.2, kind: FacadeStoreyKind.main),
          FacadeStorey(id: 'st2', heightM: 1.8, kind: FacadeStoreyKind.main),
        ],
      );
      final standingSave = standingController.saveStandingHeight(
        projectId: projectId,
        facadeSideId: 'e1',
        standingHeightM: 3.15,
      );

      await Future<void>.delayed(Duration.zero);
      store.releaseSave(0);
      store.releaseSave(1);
      await Future.wait([gridSave, standingSave]);

      final reloaded = await store.getProject(projectId);
      final facade = reloaded!.facades.firstWhere((value) => value.sideId == 'e1');

      expect(facade.sections.map((section) => section.widthM), [1.25, 0.75]);
      expect(facade.storeys.map((storey) => storey.heightM), [2.2, 1.8]);
      expect(facade.standingHeightM, closeTo(3.15, 0.0001));
      expect(facade.topZoneM, facadeTopZoneHeightM);
    });
  });
}

class _ControlledSaveProjectStore implements LocalProjectStore {
  _ControlledSaveProjectStore(this._project);

  ProjectDocument _project;
  final List<Completer<void>> _saveGate = [Completer<void>(), Completer<void>()];
  int _saveIndex = 0;

  void releaseSave(int index) {
    if (index < 0 || index >= _saveGate.length) return;
    if (!_saveGate[index].isCompleted) {
      _saveGate[index].complete();
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {}

  @override
  Future<ProjectDocument?> getProject(String projectId) async {
    if (_project.projectId != projectId) return null;
    return _project;
  }

  @override
  Future<List<ProjectSummary>> listProjects() async => const [];

  @override
  Future<void> saveProject(ProjectDocument project) async {
    final currentIndex = _saveIndex;
    _saveIndex += 1;
    if (currentIndex < _saveGate.length) {
      await _saveGate[currentIndex].future;
    }
    _project = project;
  }
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
