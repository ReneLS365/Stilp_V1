import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/state/app_shell_controller.dart';
import '../../../core/models/plan_side.dart';
import '../../../core/models/plan_view_data.dart';
import '../../../core/models/project_document.dart';
import '../../../data/projects/local_project_store.dart';
import '../../project_session/state/project_session_controller.dart';

final activeProjectDocumentProvider = FutureProvider<ProjectDocument?>((ref) async {
  final session = ref.watch(projectSessionControllerProvider);
  if (session == null) {
    return null;
  }

  final store = ref.watch(localProjectStoreProvider);
  return store.getProject(session.activeProjectId);
});

final planViewControllerProvider = Provider<PlanViewController>((ref) {
  final store = ref.watch(localProjectStoreProvider);
  return PlanViewController(
    store: store,
    now: DateTime.now,
  );
});

class PlanViewController {
  PlanViewController({
    required LocalProjectStore store,
    required DateTime Function() now,
  })  : _store = store,
        _now = now;

  final LocalProjectStore _store;
  final DateTime Function() _now;
  Future<void> _pendingSideMetadataSave = Future<void>.value();

  Future<void> startRectangle(String projectId) async {
    await _saveUpdatedPlanView(projectId, (_) => _defaultRectangle());
  }

  Future<void> clearPlan(String projectId) async {
    await _saveUpdatedPlanView(
      projectId,
      (_) => const PlanViewData(enabled: true, nodes: [], edges: []),
    );
  }

  Future<void> moveNode({
    required String projectId,
    required String nodeId,
    required Offset nextPosition,
    required Size canvasSize,
  }) async {
    await _saveUpdatedPlanView(projectId, (currentPlan) {
      final clampedPosition = Offset(
        nextPosition.dx.clamp(0, canvasSize.width),
        nextPosition.dy.clamp(0, canvasSize.height),
      );

      final nextNodes = currentPlan.nodes
          .map(
            (node) => node.id == nodeId
                ? PlanViewNode(
                    id: node.id,
                    x: clampedPosition.dx,
                    y: clampedPosition.dy,
                  )
                : node,
          )
          .toList(growable: false);

      return currentPlan.copyWith(
        enabled: true,
        nodes: nextNodes,
        edges: _rebuildEdges(nextNodes, previousEdges: currentPlan.edges),
      );
    });
  }

  Future<void> updateSideType({
    required String projectId,
    required String edgeId,
    required PlanSideType sideType,
  }) async {
    await _enqueueSideMetadataSave(() {
      return _saveUpdatedPlanView(projectId, (currentPlan) {
        final nextEdges = currentPlan.edges
            .map(
              (edge) => edge.id == edgeId ? edge.copyWith(sideType: sideType) : edge,
            )
            .toList(growable: false);
        return currentPlan.copyWith(edges: nextEdges);
      });
    });
  }

  Future<void> updateSideDimensions({
    required String projectId,
    required String edgeId,
    int? lengthMm,
    int? eavesMm,
    int? ridgeMm,
    int? overhangMm,
  }) async {
    await _enqueueSideMetadataSave(() {
      return _saveUpdatedPlanView(projectId, (currentPlan) {
        final nextEdges = currentPlan.edges
            .map(
              (edge) => edge.id == edgeId
                  ? edge.copyWith(
                      lengthMm: lengthMm,
                      eavesMm: eavesMm,
                      ridgeMm: ridgeMm,
                      overhangMm: overhangMm,
                    )
                  : edge,
            )
            .toList(growable: false);
        return currentPlan.copyWith(edges: nextEdges);
      });
    });
  }

  Future<void> updateSideHeights({
    required String projectId,
    required String edgeId,
    int? eavesHeightMm,
    int? ridgeHeightMm,
  }) {
    return updateSideDimensions(
      projectId: projectId,
      edgeId: edgeId,
      eavesMm: eavesHeightMm,
      ridgeMm: ridgeHeightMm,
    );
  }

  Future<void> _enqueueSideMetadataSave(Future<void> Function() action) async {
    _pendingSideMetadataSave = _pendingSideMetadataSave.catchError((_, __) {}).then(
          (_) => action(),
        );
    await _pendingSideMetadataSave;
  }

  Future<void> _saveUpdatedPlanView(
    String projectId,
    PlanViewData Function(PlanViewData currentPlan) update,
  ) async {
    final project = await _store.getProject(projectId);
    if (project == null) {
      return;
    }

    final updated = project.copyWith(
      updatedAt: _now(),
      planView: update(project.planView),
    );

    await _store.saveProject(updated);
  }

  static PlanViewData _defaultRectangle() {
    const nodes = [
      PlanViewNode(id: 'n1', x: 80, y: 80),
      PlanViewNode(id: 'n2', x: 280, y: 80),
      PlanViewNode(id: 'n3', x: 280, y: 220),
      PlanViewNode(id: 'n4', x: 80, y: 220),
    ];

    return PlanViewData(
      enabled: true,
      nodes: nodes,
      edges: _rebuildEdges(nodes),
    );
  }

  static List<PlanViewEdge> _rebuildEdges(
    List<PlanViewNode> nodes, {
    List<PlanViewEdge> previousEdges = const [],
  }) {
    if (nodes.length < 2) {
      return const [];
    }

    final previousById = {for (final edge in previousEdges) edge.id: edge};
    final edges = <PlanViewEdge>[];
    for (var index = 0; index < nodes.length; index++) {
      final from = nodes[index];
      final to = nodes[(index + 1) % nodes.length];
      final edgeId = 'e${index + 1}';
      final previous = previousById[edgeId];
      edges.add(
        PlanViewEdge(
          id: edgeId,
          fromNodeId: from.id,
          toNodeId: to.id,
          lengthMm: _distanceMm(from, to),
          sideType: previous?.sideType ?? PlanSideType.andet,
          eavesMm: previous?.eavesMm,
          ridgeMm: previous?.ridgeMm,
          overhangMm: previous?.overhangMm,
        ),
      );
    }

    return edges;
  }

  static int _distanceMm(PlanViewNode from, PlanViewNode to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final distancePx = math.sqrt(dx * dx + dy * dy);
    return (distancePx * 10).round();
  }
}
