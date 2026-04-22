import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/plan_side.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/data/projects/file_local_project_store.dart';
import 'package:stilp_v1/src/data/projects/in_memory_project_store.dart';
import 'package:stilp_v1/src/features/plan_view/height_input_parser.dart';
import 'package:stilp_v1/src/features/plan_view/state/plan_view_controller.dart';

void main() {
  group('PlanViewController', () {
    test('startRectangle adds initial closed shape for an empty project', () async {
      final store = InMemoryProjectStore();
      final projectId = 'empty-project';
      await store.saveProject(
        ProjectDocument.empty(
          projectId: projectId,
          taskType: 'Plan test',
          now: DateTime.utc(2026, 4, 22, 10, 0),
        ),
      );

      final controller = PlanViewController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 10, 5),
      );

      await controller.startRectangle(projectId);
      final updated = await store.getProject(projectId);

      expect(updated, isNotNull);
      expect(updated!.planView.enabled, isTrue);
      expect(updated.planView.nodes, hasLength(4));
      expect(updated.planView.edges, hasLength(4));
      expect(updated.planView.edges.first.fromNodeId, updated.planView.nodes.first.id);
      expect(updated.planView.edges.last.toNodeId, updated.planView.nodes.first.id);
    });

    test('moveNode updates node coordinates and connected edge lengths in project state', () async {
      final store = InMemoryProjectStore();
      final projectId = 'moving-project';
      await store.saveProject(
        ProjectDocument.empty(
          projectId: projectId,
          taskType: 'Plan test',
          now: DateTime.utc(2026, 4, 22, 10, 0),
        ),
      );

      final controller = PlanViewController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 10, 6),
      );

      await controller.startRectangle(projectId);
      final beforeMove = await store.getProject(projectId);
      final beforeE1 = beforeMove!.planView.edges.firstWhere((edge) => edge.id == 'e1');
      final beforeE2 = beforeMove.planView.edges.firstWhere((edge) => edge.id == 'e2');

      await controller.moveNode(
        projectId: projectId,
        nodeId: 'n2',
        nextPosition: const Offset(300, 120),
        canvasSize: const Size(400, 300),
      );

      final updated = await store.getProject(projectId);
      final movedNode = updated!.planView.nodes.firstWhere((node) => node.id == 'n2');
      final afterE1 = updated.planView.edges.firstWhere((edge) => edge.id == 'e1');
      final afterE2 = updated.planView.edges.firstWhere((edge) => edge.id == 'e2');

      expect(movedNode.x, 300);
      expect(movedNode.y, 120);
      expect(afterE1.lengthMm, isNot(beforeE1.lengthMm));
      expect(afterE2.lengthMm, isNot(beforeE2.lengthMm));
    });

    test('updateSideType persists chosen side type for an edge', () async {
      final store = InMemoryProjectStore();
      const projectId = 'side-type-project';
      await store.saveProject(
        ProjectDocument.empty(
          projectId: projectId,
          taskType: 'Plan test',
          now: DateTime.utc(2026, 4, 22, 10, 0),
        ),
      );

      final controller = PlanViewController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 10, 7),
      );

      await controller.startRectangle(projectId);
      await controller.updateSideType(
        projectId: projectId,
        edgeId: 'e1',
        sideType: PlanSideType.gavl,
      );

      final updated = await store.getProject(projectId);
      final edge = updated!.planView.edges.firstWhere((item) => item.id == 'e1');
      expect(edge.sideType, PlanSideType.gavl);
    });

    test('updateSideHeights persists and allows clearing heights', () async {
      final store = InMemoryProjectStore();
      const projectId = 'heights-project';
      await store.saveProject(
        ProjectDocument.empty(
          projectId: projectId,
          taskType: 'Plan test',
          now: DateTime.utc(2026, 4, 22, 10, 0),
        ),
      );

      final controller = PlanViewController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 10, 9),
      );

      await controller.startRectangle(projectId);
      await controller.updateSideHeights(
        projectId: projectId,
        edgeId: 'e2',
        eavesHeightMm: 3100,
        ridgeHeightMm: 4600,
      );
      await controller.updateSideHeights(
        projectId: projectId,
        edgeId: 'e2',
        eavesHeightMm: null,
        ridgeHeightMm: null,
      );

      final updated = await store.getProject(projectId);
      final edge = updated!.planView.edges.firstWhere((item) => item.id == 'e2');
      expect(edge.eavesHeightMm, isNull);
      expect(edge.ridgeHeightMm, isNull);
    });

    test('concurrent side metadata saves preserve both updates', () async {
      final store = InMemoryProjectStore();
      const projectId = 'concurrent-side-save-project';
      await store.saveProject(
        ProjectDocument.empty(
          projectId: projectId,
          taskType: 'Plan test',
          now: DateTime.utc(2026, 4, 22, 10, 0),
        ),
      );

      final controller = PlanViewController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 10, 11),
      );

      await controller.startRectangle(projectId);
      final futures = <Future<void>>[
        controller.updateSideType(
          projectId: projectId,
          edgeId: 'e1',
          sideType: PlanSideType.gavl,
        ),
        controller.updateSideHeights(
          projectId: projectId,
          edgeId: 'e2',
          eavesHeightMm: 3200,
          ridgeHeightMm: 4700,
        ),
      ];
      await Future.wait(futures);

      final updated = await store.getProject(projectId);
      final e1 = updated!.planView.edges.firstWhere((item) => item.id == 'e1');
      final e2 = updated.planView.edges.firstWhere((item) => item.id == 'e2');
      expect(e1.sideType, PlanSideType.gavl);
      expect(e2.eavesHeightMm, 3200);
      expect(e2.ridgeHeightMm, 4700);
    });

    test('invalid non-empty height input does not clear existing saved value', () async {
      final store = InMemoryProjectStore();
      const projectId = 'invalid-height-input-project';
      await store.saveProject(
        ProjectDocument.empty(
          projectId: projectId,
          taskType: 'Plan test',
          now: DateTime.utc(2026, 4, 22, 10, 0),
        ),
      );

      final controller = PlanViewController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 10, 12),
      );

      await controller.startRectangle(projectId);
      await controller.updateSideHeights(
        projectId: projectId,
        edgeId: 'e1',
        eavesHeightMm: 3200,
        ridgeHeightMm: 4500,
      );

      final invalidEaves = parseHeightInputMm('3,200');
      final invalidRidge = parseHeightInputMm('3200mm');
      if (invalidEaves.isValid && invalidRidge.isValid) {
        await controller.updateSideHeights(
          projectId: projectId,
          edgeId: 'e1',
          eavesHeightMm: invalidEaves.valueMm,
          ridgeHeightMm: invalidRidge.valueMm,
        );
      }

      final updated = await store.getProject(projectId);
      final edge = updated!.planView.edges.firstWhere((item) => item.id == 'e1');
      expect(invalidEaves.isValid, isFalse);
      expect(invalidRidge.isValid, isFalse);
      expect(edge.eavesHeightMm, 3200);
      expect(edge.ridgeHeightMm, 4500);
    });

    test('clearPlan removes nodes and edges again', () async {
      final store = InMemoryProjectStore();
      final projectId = 'clear-project';
      await store.saveProject(
        ProjectDocument.empty(
          projectId: projectId,
          taskType: 'Plan test',
          now: DateTime.utc(2026, 4, 22, 10, 0),
        ),
      );

      final controller = PlanViewController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 10, 8),
      );

      await controller.startRectangle(projectId);
      await controller.clearPlan(projectId);

      final updated = await store.getProject(projectId);

      expect(updated, isNotNull);
      expect(updated!.planView.nodes, isEmpty);
      expect(updated.planView.edges, isEmpty);
      expect(updated.planView.enabled, isTrue);
    });

    test('plan side metadata persists through FileLocalProjectStore reload', () async {
      final tempRoot = await Directory.systemTemp.createTemp('stilp_plan_view_');
      addTearDown(() async {
        if (await tempRoot.exists()) {
          await tempRoot.delete(recursive: true);
        }
      });

      final projectsDirectory = Directory('${tempRoot.path}/projects');
      final store = FileLocalProjectStore(projectsDirectory: projectsDirectory);
      const projectId = 'persist-project';

      await store.saveProject(
        ProjectDocument.empty(
          projectId: projectId,
          taskType: 'Persist test',
          now: DateTime.utc(2026, 4, 22, 10, 0),
        ),
      );

      final controller = PlanViewController(
        store: store,
        now: () => DateTime.utc(2026, 4, 22, 10, 10),
      );

      await controller.startRectangle(projectId);
      await controller.moveNode(
        projectId: projectId,
        nodeId: 'n3',
        nextPosition: const Offset(320, 260),
        canvasSize: const Size(400, 400),
      );
      await controller.updateSideType(
        projectId: projectId,
        edgeId: 'e3',
        sideType: PlanSideType.langside,
      );
      await controller.updateSideHeights(
        projectId: projectId,
        edgeId: 'e3',
        eavesHeightMm: 3300,
        ridgeHeightMm: 5000,
      );

      final freshStore = FileLocalProjectStore(projectsDirectory: projectsDirectory);
      final reloaded = await freshStore.getProject(projectId);
      final movedNode = reloaded!.planView.nodes.firstWhere((node) => node.id == 'n3');
      final edge = reloaded.planView.edges.firstWhere((item) => item.id == 'e3');

      expect(reloaded.planView.nodes, hasLength(4));
      expect(reloaded.planView.edges, hasLength(4));
      expect(movedNode.x, 320);
      expect(movedNode.y, 260);
      expect(edge.sideType, PlanSideType.langside);
      expect(edge.eavesHeightMm, 3300);
      expect(edge.ridgeHeightMm, 5000);
    });
  });
}
