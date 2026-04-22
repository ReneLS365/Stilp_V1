import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state/app_shell_controller.dart';
import '../../core/models/plan_side.dart';
import '../../core/models/plan_view_data.dart';
import '../facade_editor/state/facade_mapping_controller.dart';
import 'height_input_parser.dart';
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
                  OutlinedButton.icon(
                    onPressed: _isRunningAction
                        ? null
                        : () => _runAction(() async {
                              await _pendingMoveWrite.catchError((_, __) {});
                              final result = await ref
                                  .read(facadeMappingControllerProvider)
                                  .mapFromPlan(project.projectId);
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result.message)),
                              );
                              if (result.isSuccess) {
                                ref.invalidate(activeProjectDocumentProvider);
                                ref.invalidate(projectsProvider);
                              }
                            }),
                    icon: const Icon(Icons.sync_alt_outlined),
                    label: const Text('Update facades from plan'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  children: [
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
                                    onPanStart: (details) =>
                                        _onPanStart(details.localPosition, nodes),
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
                    const SizedBox(height: 12),
                    _SideEditorSection(
                      projectId: project.projectId,
                      edges: plan.edges,
                      isRunningAction: _isRunningAction,
                    ),
                  ],
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

class _SideEditorSection extends ConsumerWidget {
  const _SideEditorSection({
    required this.projectId,
    required this.edges,
    required this.isRunningAction,
  });

  final String projectId;
  final List<PlanViewEdge> edges;
  final bool isRunningAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (edges.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sides', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 230),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: edges.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final edge = edges[index];
                  return _SideEditorRow(
                    key: ValueKey(edge.id),
                    projectId: projectId,
                    edge: edge,
                    sideLabel: 'Side ${index + 1}',
                    isEnabled: !isRunningAction,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideEditorRow extends ConsumerStatefulWidget {
  const _SideEditorRow({
    super.key,
    required this.projectId,
    required this.edge,
    required this.sideLabel,
    required this.isEnabled,
  });

  final String projectId;
  final PlanViewEdge edge;
  final String sideLabel;
  final bool isEnabled;

  @override
  ConsumerState<_SideEditorRow> createState() => _SideEditorRowState();
}

class _SideEditorRowState extends ConsumerState<_SideEditorRow> {
  late final TextEditingController _eavesController;
  late final TextEditingController _ridgeController;

  @override
  void initState() {
    super.initState();
    _eavesController = TextEditingController(text: _asInput(widget.edge.eavesHeightMm));
    _ridgeController = TextEditingController(text: _asInput(widget.edge.ridgeHeightMm));
  }

  @override
  void didUpdateWidget(covariant _SideEditorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.edge.eavesHeightMm != widget.edge.eavesHeightMm &&
        _eavesController.text != _asInput(widget.edge.eavesHeightMm)) {
      _eavesController.text = _asInput(widget.edge.eavesHeightMm);
    }
    if (oldWidget.edge.ridgeHeightMm != widget.edge.ridgeHeightMm &&
        _ridgeController.text != _asInput(widget.edge.ridgeHeightMm)) {
      _ridgeController.text = _asInput(widget.edge.ridgeHeightMm);
    }
  }

  @override
  void dispose() {
    _eavesController.dispose();
    _ridgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(planViewControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.sideLabel} (${widget.edge.id}) · ${_formatLength(widget.edge.lengthMm)}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PlanSideType>(
          initialValue: widget.edge.sideType,
          decoration: const InputDecoration(
            labelText: 'Side type',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: PlanSideType.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value.jsonValue),
                ),
              )
              .toList(growable: false),
          onChanged: widget.isEnabled
              ? (value) async {
                  if (value == null) {
                    return;
                  }
                  await controller.updateSideType(
                    projectId: widget.projectId,
                    edgeId: widget.edge.id,
                    sideType: value,
                  );
                  ref.invalidate(activeProjectDocumentProvider);
                  ref.invalidate(projectsProvider);
                }
              : null,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _eavesController,
                enabled: widget.isEnabled,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Eaves (mm)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _saveHeights(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _ridgeController,
                enabled: widget.isEnabled,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ridge (mm)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _saveHeights(),
              ),
            ),
            IconButton(
              onPressed: widget.isEnabled ? _saveHeights : null,
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Save side heights',
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveHeights() async {
    final eavesParse = parseHeightInputMm(_eavesController.text);
    final ridgeParse = parseHeightInputMm(_ridgeController.text);
    if (!eavesParse.isValid || !ridgeParse.isValid) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid height format. Use whole millimetres (example: 3200).',
          ),
        ),
      );
      return;
    }

    final controller = ref.read(planViewControllerProvider);
    await controller.updateSideHeights(
      projectId: widget.projectId,
      edgeId: widget.edge.id,
      eavesHeightMm: eavesParse.valueMm,
      ridgeHeightMm: ridgeParse.valueMm,
    );
    ref.invalidate(activeProjectDocumentProvider);
    ref.invalidate(projectsProvider);
  }

  static String _asInput(int? value) => value?.toString() ?? '';
  static String _formatLength(int mm) => '${(mm / 1000).toStringAsFixed(2)} m';
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
