import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state/app_shell_controller.dart';
import '../../core/models/plan_view_data.dart';
import 'state/plan_view_controller.dart';

class PlanViewScreen extends ConsumerStatefulWidget {
  const PlanViewScreen({super.key});

  @override
  ConsumerState<PlanViewScreen> createState() => _PlanViewScreenState();
}

class _PlanViewScreenState extends ConsumerState<PlanViewScreen> {
  String? _draggingNodeId;
  List<PlanViewNode>? _liveNodes;
  bool _isRunningAction = false;
  Future<void> _pendingMoveWrite = Future<void>.value();

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(activeProjectDocumentProvider);

    return projectAsync.when(
      data: (project) {
        if (project == null) {
          return const Center(child: Text('Ingen aktivt projekt fundet.'));
        }

        final plan = project.planView;
        final nodes = _draggingNodeId == null ? plan.nodes : (_liveNodes ?? plan.nodes);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _isRunningAction
                        ? null
                        : () => _runAction(() async {
                              await ref
                                  .read(planViewControllerProvider)
                                  .startRectangle(project.projectId);
                              ref.invalidate(activeProjectDocumentProvider);
                              ref.invalidate(projectsProvider);
                            }),
                    icon: const Icon(Icons.crop_square),
                    label: Text(plan.nodes.isEmpty ? 'Start rectangle' : 'Reset rectangle'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isRunningAction || plan.nodes.isEmpty
                        ? null
                        : () => _runAction(() async {
                              await ref
                                  .read(planViewControllerProvider)
                                  .clearPlan(project.projectId);
                              setState(() {
                                _draggingNodeId = null;
                                _liveNodes = null;
                              });
                              ref.invalidate(activeProjectDocumentProvider);
                              ref.invalidate(projectsProvider);
                            }),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear plan'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: plan.nodes.isEmpty
                      ? const _PlanEmptyState()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final canvasSize = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            return GestureDetector(
                              onPanStart: (details) => _onPanStart(details.localPosition, nodes),
                              onPanUpdate: (details) => _onPanUpdate(
                                details.localPosition,
                                project.projectId,
                                canvasSize,
                              ),
                              onPanEnd: (_) => _onPanEnd(),
                              child: CustomPaint(
                                painter: _PlanCanvasPainter(
                                  nodes: nodes,
                                  edges: plan.edges,
                                  highlightedNodeId: _draggingNodeId,
                                  colorScheme: Theme.of(context).colorScheme,
                                ),
                                child: const SizedBox.expand(),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
      error: (_, __) {
        return const Center(child: Text('Kunne ikke indlæse planvisning.'));
      },
      loading: () {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _isRunningAction = true;
    });

    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _isRunningAction = false;
        });
      }
    }
  }

  void _onPanStart(Offset pointer, List<PlanViewNode> nodes) {
    const maxDistance = 28.0;

    String? nearestNodeId;
    var nearestDistance = maxDistance;

    for (final node in nodes) {
      final distance = (Offset(node.x, node.y) - pointer).distance;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestNodeId = node.id;
      }
    }

    if (nearestNodeId == null) {
      return;
    }

    setState(() {
      _draggingNodeId = nearestNodeId;
      _liveNodes = nodes
          .map((node) => PlanViewNode(id: node.id, x: node.x, y: node.y))
          .toList(growable: false);
    });
  }

  void _onPanUpdate(
    Offset pointer,
    String projectId,
    Size canvasSize,
  ) {
    final draggingNodeId = _draggingNodeId;
    if (draggingNodeId == null) {
      return;
    }

    final clamped = Offset(
      pointer.dx.clamp(0, canvasSize.width),
      pointer.dy.clamp(0, canvasSize.height),
    );

    setState(() {
      final currentNodes = _liveNodes ?? const <PlanViewNode>[];
      _liveNodes = currentNodes
          .map(
            (node) => node.id == draggingNodeId
                ? PlanViewNode(id: node.id, x: clamped.dx, y: clamped.dy)
                : node,
          )
          .toList(growable: false);
    });

    _pendingMoveWrite = _pendingMoveWrite
        .catchError((_, __) {})
        .then(
          (_) => ref.read(planViewControllerProvider).moveNode(
                projectId: projectId,
                nodeId: draggingNodeId,
                nextPosition: clamped,
                canvasSize: canvasSize,
              ),
        );
  }

  Future<void> _onPanEnd() async {
    setState(() {
      _draggingNodeId = null;
    });

    await _pendingMoveWrite;

    if (!mounted) {
      return;
    }

    setState(() {
      _liveNodes = null;
    });
    ref.invalidate(activeProjectDocumentProvider);
  }
}

class _PlanEmptyState extends StatelessWidget {
  const _PlanEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Planen er tom. Brug "Start rectangle" for at oprette første form.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PlanCanvasPainter extends CustomPainter {
  const _PlanCanvasPainter({
    required this.nodes,
    required this.edges,
    required this.highlightedNodeId,
    required this.colorScheme,
  });

  final List<PlanViewNode> nodes;
  final List<PlanViewEdge> edges;
  final String? highlightedNodeId;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final nodeById = {for (final node in nodes) node.id: node};

    final edgePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final from = nodeById[edge.fromNodeId];
      final to = nodeById[edge.toNodeId];
      if (from == null || to == null) {
        continue;
      }

      canvas.drawLine(Offset(from.x, from.y), Offset(to.x, to.y), edgePaint);
    }

    for (final node in nodes) {
      final isHighlighted = node.id == highlightedNodeId;

      final fillPaint = Paint()
        ..color = isHighlighted ? colorScheme.tertiary : colorScheme.surface;

      final borderPaint = Paint()
        ..color = colorScheme.primary
        ..strokeWidth = isHighlighted ? 4 : 2
        ..style = PaintingStyle.stroke;

      final center = Offset(node.x, node.y);
      final radius = isHighlighted ? 10.0 : 8.0;

      canvas.drawCircle(center, radius, fillPaint);
      canvas.drawCircle(center, radius, borderPaint);
    }

    final guidePaint = Paint()
      ..color = colorScheme.outlineVariant
      ..strokeWidth = 1;

    const step = 40.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), guidePaint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }
  }

  @override
  bool shouldRepaint(_PlanCanvasPainter oldDelegate) {
    if (highlightedNodeId != oldDelegate.highlightedNodeId ||
        nodes.length != oldDelegate.nodes.length ||
        edges.length != oldDelegate.edges.length) {
      return true;
    }

    for (var index = 0; index < nodes.length; index++) {
      final current = nodes[index];
      final previous = oldDelegate.nodes[index];
      if (current.id != previous.id ||
          current.x != previous.x ||
          current.y != previous.y) {
        return true;
      }
    }

    for (var index = 0; index < edges.length; index++) {
      final current = edges[index];
      final previous = oldDelegate.edges[index];
      if (current.id != previous.id ||
          current.fromNodeId != previous.fromNodeId ||
          current.toNodeId != previous.toNodeId ||
          current.lengthMm != previous.lengthMm) {
        return true;
      }
    }

    return false;
  }
}
