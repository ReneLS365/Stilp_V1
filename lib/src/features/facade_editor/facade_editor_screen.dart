import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/facade_document.dart';
import '../../core/models/facade_section.dart';
import '../../core/models/facade_storey.dart';
import '../../core/models/plan_side.dart';
import '../plan_view/state/plan_view_controller.dart';
import '../project_session/state/project_session_controller.dart';
import 'facade_standing_height_input_parser.dart';
import 'state/facade_grid_adjustment_controller.dart';
import 'state/facade_grid_generation_controller.dart';
import 'state/facade_standing_height_controller.dart';

class FacadeEditorScreen extends ConsumerStatefulWidget {
  const FacadeEditorScreen({super.key});

  @override
  ConsumerState<FacadeEditorScreen> createState() => _FacadeEditorScreenState();
}

class _FacadeEditorScreenState extends ConsumerState<FacadeEditorScreen> {
  final _sectionsController = TextEditingController();
  final _sectionWidthController = TextEditingController();
  final _storeysController = TextEditingController();
  final _storeyHeightController = TextEditingController();
  final _standingHeightController = TextEditingController();

  String? _lastFacadeSideId;

  @override
  void dispose() {
    _sectionsController.dispose();
    _sectionWidthController.dispose();
    _storeysController.dispose();
    _storeyHeightController.dispose();
    _standingHeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(activeProjectDocumentProvider);
    final session = ref.watch(projectSessionControllerProvider);

    return projectAsync.when(
      data: (project) {
        if (project == null || session == null) {
          return const Center(child: Text('Ingen aktivt projekt fundet.'));
        }

        final facades = project.facades;
        if (facades.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Ingen facader endnu. Gå til Plan og vælg "Update facades from plan".',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final selectedSideId = session.selectedFacadeSideId;
        final hasSelected = selectedSideId != null &&
            facades.any((facade) => facade.sideId == selectedSideId);
        final selectedFacade =
            hasSelected ? facades.firstWhere((facade) => facade.sideId == selectedSideId) : null;
        final activeFacade = selectedFacade ?? facades.first;

        if (selectedFacade == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(projectSessionControllerProvider.notifier)
                .setSelectedFacadeSide(activeFacade.sideId);
          });
        }

        _syncFormWithFacade(activeFacade);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Facader (${facades.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: facades.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final facade = facades[index];
                    return ChoiceChip(
                      label: Text(facade.label),
                      selected: facade.sideId == activeFacade.sideId,
                      onSelected: (_) => ref
                          .read(projectSessionControllerProvider.notifier)
                          .setSelectedFacadeSide(facade.sideId),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _FacadeMetadataCard(facade: activeFacade),
                    const SizedBox(height: 12),
                    _FacadeGenerationForm(
                      sectionsController: _sectionsController,
                      sectionWidthController: _sectionWidthController,
                      storeysController: _storeysController,
                      storeyHeightController: _storeyHeightController,
                      onGeneratePressed: () => _generateGrid(project.projectId, activeFacade.sideId),
                    ),
                    const SizedBox(height: 12),
                    _FacadeStandingHeightCard(
                      controller: _standingHeightController,
                      onApplyPressed: () => _saveStandingHeight(
                        projectId: project.projectId,
                        facadeSideId: activeFacade.sideId,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FacadeGridCard(
                      projectId: project.projectId,
                      facade: activeFacade,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      error: (_, __) => const Center(child: Text('Kunne ikke indlæse facader.')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  void _syncFormWithFacade(FacadeDocument facade) {
    if (_lastFacadeSideId == facade.sideId) return;

    _lastFacadeSideId = facade.sideId;
    final sectionCount = facade.sections.isNotEmpty ? facade.sections.length : _defaultSections(facade);
    final sectionWidth = facade.sections.isNotEmpty ? facade.sections.first.widthM : 2.57;
    final storeyCount = facade.storeys.isNotEmpty ? facade.storeys.length : 2;
    final storeyHeight = facade.storeys.isNotEmpty ? facade.storeys.first.heightM : 2.0;

    _sectionsController.text = '$sectionCount';
    _sectionWidthController.text = sectionWidth.toStringAsFixed(2);
    _storeysController.text = '$storeyCount';
    _storeyHeightController.text = storeyHeight.toStringAsFixed(2);
    _standingHeightController.text = facade.standingHeightM?.toStringAsFixed(2) ?? '';
  }

  int _defaultSections(FacadeDocument facade) {
    if (facade.edgeLengthMm <= 0) return 2;
    final estimate = facade.edgeLengthMm / 2570;
    return math.max(1, estimate.round());
  }

  Future<void> _generateGrid(String projectId, String sideId) async {
    final numberOfSections = int.tryParse(_sectionsController.text.trim());
    final defaultSectionWidthM = double.tryParse(_sectionWidthController.text.trim());
    final numberOfStoreys = int.tryParse(_storeysController.text.trim());
    final defaultStoreyHeightM = double.tryParse(_storeyHeightController.text.trim());

    if (numberOfSections == null ||
        defaultSectionWidthM == null ||
        numberOfStoreys == null ||
        defaultStoreyHeightM == null) {
      _showMessage('Ugyldigt input. Indtast tal i alle felter.');
      return;
    }

    final result = await ref.read(facadeGridGenerationControllerProvider).generateGrid(
          projectId: projectId,
          facadeSideId: sideId,
          basisInput: FacadeGridBasisInput(
            numberOfSections: numberOfSections,
            defaultSectionWidthM: defaultSectionWidthM,
            numberOfStoreys: numberOfStoreys,
            defaultStoreyHeightM: defaultStoreyHeightM,
          ),
        );

    if (!mounted) return;

    ref.invalidate(activeProjectDocumentProvider);
    _showMessage(result.message);
  }

  Future<void> _saveStandingHeight({
    required String projectId,
    required String facadeSideId,
  }) async {
    final parseResult = parseFacadeStandingHeightInputM(_standingHeightController.text);
    if (!parseResult.isValid) {
      _showMessage('Ugyldig ståhøjde. Brug et positivt tal i meter.');
      return;
    }

    final result = await ref.read(facadeStandingHeightControllerProvider).saveStandingHeight(
          projectId: projectId,
          facadeSideId: facadeSideId,
          standingHeightM: parseResult.valueM,
        );

    if (!mounted) return;
    ref.invalidate(activeProjectDocumentProvider);
    _showMessage(result.message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FacadeStandingHeightCard extends StatelessWidget {
  const _FacadeStandingHeightCard({
    required this.controller,
    required this.onApplyPressed,
  });

  final TextEditingController controller;
  final VoidCallback onApplyPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ståhøjde', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Standing height (m)',
                hintText: 'Fx 3.20',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onApplyPressed,
                child: const Text('Apply standing height'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacadeMetadataCard extends StatelessWidget {
  const _FacadeMetadataCard({required this.facade});

  final FacadeDocument facade;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(facade.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Plan edge: ${facade.planEdgeId}'),
            Text('Order: ${facade.sideOrder + 1}'),
            Text('Length: ${(facade.edgeLengthMm / 1000).toStringAsFixed(2)} m'),
            Text('Type: ${facade.sideType.jsonValue}'),
            Text('Eaves: ${facade.eavesHeightMm?.toString() ?? '-'} mm'),
            Text('Ridge: ${facade.ridgeHeightMm?.toString() ?? '-'} mm'),
            Text(
              'Standing height: ${facade.standingHeightM?.toStringAsFixed(2) ?? '-'} m',
              key: const ValueKey('standing-height-label'),
            ),
            Text(
              'Top zone: ${facade.standingHeightM == null ? '-' : facade.topZoneM.toStringAsFixed(2)} m',
              key: const ValueKey('top-zone-label'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacadeGenerationForm extends StatelessWidget {
  const _FacadeGenerationForm({
    required this.sectionsController,
    required this.sectionWidthController,
    required this.storeysController,
    required this.storeyHeightController,
    required this.onGeneratePressed,
  });

  final TextEditingController sectionsController;
  final TextEditingController sectionWidthController;
  final TextEditingController storeysController;
  final TextEditingController storeyHeightController;
  final VoidCallback onGeneratePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basisinput', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: sectionsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              decoration: const InputDecoration(labelText: 'Number of sections'),
            ),
            TextField(
              controller: sectionWidthController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Default section width (m)'),
            ),
            TextField(
              controller: storeysController,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              decoration: const InputDecoration(labelText: 'Number of storeys'),
            ),
            TextField(
              controller: storeyHeightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Default storey height (m)'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onGeneratePressed,
                child: const Text('Generate grid'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacadeGridCard extends StatelessWidget {
  const _FacadeGridCard({
    required this.projectId,
    required this.facade,
  });

  final String projectId;
  final FacadeDocument facade;

  @override
  Widget build(BuildContext context) {
    final hasGrid = facade.sections.isNotEmpty && facade.storeys.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Facade grid', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (!hasGrid)
              const Text('No grid generated yet for this facade side.')
            else ...[
              Text('${facade.sections.length} sections · ${facade.storeys.length} storeys'),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 1.6,
                child: _AdjustableFacadeGrid(
                  projectId: projectId,
                  facade: facade,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FacadeGridPainter extends CustomPainter {
  const _FacadeGridPainter({
    required this.sections,
    required this.storeys,
    required this.standingHeightM,
    required this.topZoneM,
    required this.lineColor,
    this.activeVerticalDividerIndex,
    this.activeHorizontalDividerIndex,
  });

  final List<FacadeSection> sections;
  final List<FacadeStorey> storeys;
  final double? standingHeightM;
  final double topZoneM;
  final Color lineColor;
  final int? activeVerticalDividerIndex;
  final int? activeHorizontalDividerIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final gridPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final activePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3;
    final standingLinePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2;
    final topZonePaint = Paint()..color = Colors.orange.withValues(alpha: 0.14);

    canvas.drawRect(Offset.zero & size, borderPaint);

    final totalSectionWidth = sections.fold<double>(
      0,
      (sum, section) => sum + section.widthM,
    );
    final totalStoreyHeight = storeys.fold<double>(
      0,
      (sum, storey) => sum + storey.heightM,
    );

    if (totalSectionWidth <= 0 || totalStoreyHeight <= 0) {
      return;
    }

    var x = 0.0;
    for (var index = 0; index < sections.length - 1; index++) {
      x += sections[index].widthM / totalSectionWidth * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        activeVerticalDividerIndex == index ? activePaint : gridPaint,
      );
    }

    var y = size.height;
    for (var index = 0; index < storeys.length - 1; index++) {
      y -= storeys[index].heightM / totalStoreyHeight * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        activeHorizontalDividerIndex == index ? activePaint : gridPaint,
      );
    }

    final heightM = standingHeightM;
    if (heightM == null || heightM <= 0 || topZoneM <= 0) {
      return;
    }

    final lineY = (size.height - (heightM / totalStoreyHeight * size.height)).clamp(0.0, size.height);
    final topBandHeight = (topZoneM / totalStoreyHeight * size.height).clamp(0.0, size.height);
    final topBandTop = (lineY - topBandHeight).clamp(0.0, size.height);
    final bandRect = Rect.fromLTRB(0, topBandTop, size.width, lineY);
    if (bandRect.height > 0) {
      canvas.drawRect(bandRect, topZonePaint);
    }
    canvas.drawLine(
      Offset(0, lineY),
      Offset(size.width, lineY),
      standingLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FacadeGridPainter oldDelegate) {
    return oldDelegate.sections != sections ||
        oldDelegate.storeys != storeys ||
        oldDelegate.standingHeightM != standingHeightM ||
        oldDelegate.topZoneM != topZoneM ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.activeVerticalDividerIndex != activeVerticalDividerIndex ||
        oldDelegate.activeHorizontalDividerIndex != activeHorizontalDividerIndex;
  }
}

enum _GridDragAxis { vertical, horizontal }

class _AdjustableFacadeGrid extends ConsumerStatefulWidget {
  const _AdjustableFacadeGrid({
    required this.projectId,
    required this.facade,
    required this.child,
  });

  final String projectId;
  final FacadeDocument facade;
  final Widget child;

  @override
  ConsumerState<_AdjustableFacadeGrid> createState() => _AdjustableFacadeGridState();
}

class _AdjustableFacadeGridState extends ConsumerState<_AdjustableFacadeGrid> {
  static const double _hitSlopPx = 20;

  late List<FacadeSection> _previewSections;
  late List<FacadeStorey> _previewStoreys;
  _GridDragAxis? _dragAxis;
  int? _activeDividerIndex;
  Offset? _lastLocalPosition;

  @override
  void initState() {
    super.initState();
    _previewSections = widget.facade.sections;
    _previewStoreys = widget.facade.storeys;
  }

  @override
  void didUpdateWidget(covariant _AdjustableFacadeGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.facade.sideId != oldWidget.facade.sideId ||
        _dragAxis == null &&
            (widget.facade.sections != oldWidget.facade.sections ||
                widget.facade.storeys != oldWidget.facade.storeys)) {
      _previewSections = widget.facade.sections;
      _previewStoreys = widget.facade.storeys;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _onPanStart(details.localPosition, size),
          onPanUpdate: (details) => _onPanUpdate(details.localPosition, size),
          onPanEnd: (_) => _onPanEnd(),
          onPanCancel: _onPanCancel,
          child: CustomPaint(
            painter: _FacadeGridPainter(
              sections: _previewSections,
              storeys: _previewStoreys,
              standingHeightM: widget.facade.standingHeightM,
              topZoneM: widget.facade.topZoneM,
              lineColor: Theme.of(context).colorScheme.onSurface,
              activeVerticalDividerIndex:
                  _dragAxis == _GridDragAxis.vertical ? _activeDividerIndex : null,
              activeHorizontalDividerIndex:
                  _dragAxis == _GridDragAxis.horizontal ? _activeDividerIndex : null,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }

  void _onPanStart(Offset localPosition, Size size) {
    final verticalIndex = _findNearestVerticalDivider(localPosition.dx, size.width);
    final horizontalIndex = _findNearestHorizontalDivider(localPosition.dy, size.height);

    if (verticalIndex != null) {
      setState(() {
        _dragAxis = _GridDragAxis.vertical;
        _activeDividerIndex = verticalIndex;
        _lastLocalPosition = localPosition;
      });
      return;
    }

    if (horizontalIndex != null) {
      setState(() {
        _dragAxis = _GridDragAxis.horizontal;
        _activeDividerIndex = horizontalIndex;
        _lastLocalPosition = localPosition;
      });
    }
  }

  void _onPanUpdate(Offset localPosition, Size size) {
    if (_dragAxis == null || _activeDividerIndex == null || _lastLocalPosition == null) {
      return;
    }

    setState(() {
      if (_dragAxis == _GridDragAxis.vertical) {
        final totalWidth = _previewSections.fold<double>(0, (sum, section) => sum + section.widthM);
        if (totalWidth <= 0 || size.width <= 0) return;
        final deltaX = localPosition.dx - _lastLocalPosition!.dx;
        final deltaM = deltaX / size.width * totalWidth;
        _previewSections = FacadeGridAdjustmentController.resizeSectionsAtDivider(
          sections: _previewSections,
          dividerIndex: _activeDividerIndex!,
          deltaM: deltaM,
        );
      } else {
        final totalHeight = _previewStoreys.fold<double>(0, (sum, storey) => sum + storey.heightM);
        if (totalHeight <= 0 || size.height <= 0) return;
        final deltaY = _lastLocalPosition!.dy - localPosition.dy;
        final deltaM = deltaY / size.height * totalHeight;
        _previewStoreys = FacadeGridAdjustmentController.resizeStoreysAtDivider(
          storeys: _previewStoreys,
          dividerIndex: _activeDividerIndex!,
          deltaM: deltaM,
        );
      }
      _lastLocalPosition = localPosition;
    });
  }

  Future<void> _onPanEnd() async {
    final hadDrag = _dragAxis != null;
    final dragSideId = widget.facade.sideId;
    _resetDragState();
    if (!hadDrag) return;

    final result = await ref.read(facadeGridAdjustmentControllerProvider).saveAdjustedGrid(
          projectId: widget.projectId,
          facadeSideId: dragSideId,
          sections: _previewSections,
          storeys: _previewStoreys,
        );

    if (!mounted) return;
    ref.invalidate(activeProjectDocumentProvider);
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  void _onPanCancel() {
    _resetDragState();
    setState(() {
      _previewSections = widget.facade.sections;
      _previewStoreys = widget.facade.storeys;
    });
  }

  void _resetDragState() {
    setState(() {
      _dragAxis = null;
      _activeDividerIndex = null;
      _lastLocalPosition = null;
    });
  }

  int? _findNearestVerticalDivider(double localDx, double width) {
    if (_previewSections.length < 2 || width <= 0) return null;

    final totalWidth = _previewSections.fold<double>(0, (sum, section) => sum + section.widthM);
    if (totalWidth <= 0) return null;

    var x = 0.0;
    for (var index = 0; index < _previewSections.length - 1; index++) {
      x += _previewSections[index].widthM / totalWidth * width;
      if ((localDx - x).abs() <= _hitSlopPx) {
        return index;
      }
    }
    return null;
  }

  int? _findNearestHorizontalDivider(double localDy, double height) {
    if (_previewStoreys.length < 2 || height <= 0) return null;

    final totalHeight = _previewStoreys.fold<double>(0, (sum, storey) => sum + storey.heightM);
    if (totalHeight <= 0) return null;

    var y = height;
    for (var index = 0; index < _previewStoreys.length - 1; index++) {
      y -= _previewStoreys[index].heightM / totalHeight * height;
      if ((localDy - y).abs() <= _hitSlopPx) {
        return index;
      }
    }
    return null;
  }
}
