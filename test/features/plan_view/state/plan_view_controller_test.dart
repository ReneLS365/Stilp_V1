import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/data/projects/file_local_project_store.dart';
import 'package:stilp_v1/src/data/projects/in_memory_project_store.dart';
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

    test('moveNode updates node coordinates and edge length in project state', () async {
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
      await controller.moveNode(
        projectId: projectId,
        nodeId: 'n2',
        nextPosition: const Offset(300, 120),
        canvasSize: const Size(400, 300),
      );

      final updated = await store.getProject(projectId);
      final movedNode = updated!.planView.nodes.firstWhere((node) => node.id == 'n2');
      final updatedEdge = updated.planView.edges.firstWhere((edge) => edge.id == 'e1');

      expect(movedNode.x, 300);
      expect(movedNode.y, 120);
      expect(updatedEdge.lengthMm, greaterThan(0));
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

    test('plan edits persist through FileLocalProjectStore reload', () async {
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

      final freshStore = FileLocalProjectStore(projectsDirectory: projectsDirectory);
      final reloaded = await freshStore.getProject(projectId);
      final movedNode = reloaded!.planView.nodes.firstWhere((node) => node.id == 'n3');

      expect(reloaded.planView.nodes, hasLength(4));
      expect(reloaded.planView.edges, hasLength(4));
      expect(movedNode.x, 320);
      expect(movedNode.y, 260);
    });
  });
}
