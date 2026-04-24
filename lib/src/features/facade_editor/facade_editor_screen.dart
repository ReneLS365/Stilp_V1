import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/facade_document.dart';
import '../../core/models/facade_marker.dart';
import '../../core/models/facade_section.dart';
import '../../core/models/facade_storey.dart';
import '../../core/models/plan_side.dart';
import '../plan_view/state/plan_view_controller.dart';
import '../project_session/state/project_session_controller.dart';
import 'facade_standing_height_input_parser.dart';
import 'state/facade_grid_adjustment_controller.dart';
import 'state/facade_grid_generation_controller.dart';
import 'state/facade_marker_placement_controller.dart';
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
  FacadeMarkerType? _selectedMarkerTool;

  String? _lastFacadeSideId;
  _FacadeFormSnapshot? _lastFacadeSnapshot;

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
        final activeFacadeIndex = _activeFacadeIndex(
          facades: facades,
          activeFacadeSideId: activeFacade.sideId,
        );
        final isFirstFacade = activeFacadeIndex <= 0;
        final isLastFacade = activeFacadeIndex >= facades.length - 1;

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
              Row(
                children: [
                  IconButton(
                    key: const ValueKey('facade-previous-side-button'),
                    onPressed: isFirstFacade ? null : () => _selectPreviousFacade(facades, activeFacadeIndex),
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Previous facade',
                  ),
                  Text(
                    '${activeFacadeIndex + 1} / ${facades.length}',
                    key: const ValueKey('facade-side-position-indicator'),
                  ),
                  IconButton(
                    key: const ValueKey('facade-next-side-button'),
                    onPressed: isLastFacade ? null : () => _selectNextFacade(facades, activeFacadeIndex),
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next facade',
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                  key: const ValueKey('facade-editor-vertical-scroll'),
                  children: [
                    KeyedSubtree(
                      key: const ValueKey('facade-metadata-card'),
                      child: _FacadeMetadataCard(facade: activeFacade),
                    ),
                    const SizedBox(height: 12),
                    KeyedSubtree(
                      key: const ValueKey('facade-generation-card'),
                      child: _FacadeGenerationForm(
                        sectionsController: _sectionsController,
                        sectionWidthController: _sectionWidthController,
                        storeysController: _storeysController,
                        storeyHeightController: _storeyHeightController,
                        onGeneratePressed: () => _generateGrid(project.projectId, activeFacade.sideId),
                      ),
                    ),
                    const SizedBox(height: 12),
                    KeyedSubtree(
                      key: const ValueKey('facade-standing-height-card'),
                      child: _FacadeStandingHeightCard(
                        controller: _standingHeightController,
                        onApplyPressed: () => _saveStandingHeight(
                          projectId: project.projectId,
                          facadeSideId: activeFacade.sideId,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    KeyedSubtree(
                      key: const ValueKey('facade-grid-card'),
                      child: _FacadeGridCard(
                        projectId: project.projectId,
                        facade: activeFacade,
                        selectedMarkerTool: _selectedMarkerTool,
                        onMarkerToolChanged: (tool) {
                          setState(() {
                            _selectedMarkerTool = tool;
                          });
                        },
                        onMarkerPlaced: (localDx, localDy) => _placeMarker(
                          projectId: project.projectId,
                          facadeSideId: activeFacade.sideId,
                          markerType: _selectedMarkerTool,
                          localDx: localDx,
                          localDy: localDy,
                        ),
                      ),
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
    final snapshot = _FacadeFormSnapshot.fromFacade(facade);
    final shouldSync = _lastFacadeSideId != facade.sideId || _lastFacadeSnapshot != snapshot;
    if (!shouldSync) return;

    _lastFacadeSideId = facade.sideId;
    _lastFacadeSnapshot = snapshot;
    _sectionsController.text = '${snapshot.sectionCount}';
    _sectionWidthController.text = snapshot.sectionWidthM.toStringAsFixed(2);
    _storeysController.text = '${snapshot.storeyCount}';
    _storeyHeightController.text = snapshot.storeyHeightM.toStringAsFixed(2);
    _standingHeightController.text = snapshot.standingHeightM?.toStringAsFixed(2) ?? '';
  }

  int _activeFacadeIndex({
    required List<FacadeDocument> facades,
    required String activeFacadeSideId,
  }) {
    final index = facades.indexWhere((facade) => facade.sideId == activeFacadeSideId);
    return index >= 0 ? index : 0;
  }

  void _selectPreviousFacade(List<FacadeDocument> facades, int activeFacadeIndex) {
    if (activeFacadeIndex <= 0) return;
    final previousFacade = facades[activeFacadeIndex - 1];
    ref.read(projectSessionControllerProvider.notifier).setSelectedFacadeSide(previousFacade.sideId);
  }

  void _selectNextFacade(List<FacadeDocument> facades, int activeFacadeIndex) {
    if (activeFacadeIndex >= facades.length - 1) return;
    final nextFacade = facades[activeFacadeIndex + 1];
    ref.read(projectSessionControllerProvider.notifier).setSelectedFacadeSide(nextFacade.sideId);
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

  Future<void> _placeMarker({
    required String projectId,
    required String facadeSideId,
    required FacadeMarkerType? markerType,
    required double localDx,
    required double localDy,
  }) async {
    if (markerType == null) return;

    final result = await ref.read(facadeMarkerPlacementControllerProvider).placeMarker(
          projectId: projectId,
          facadeSideId: facadeSideId,
          markerType: markerType,
          localDx: localDx,
          localDy: localDy,
        );

    if (!mounted) return;
    ref.invalidate(activeProjectDocumentProvider);
    if (!result.isSuccess) {
      _showMessage(result.message);
    }
  }
}

class _FacadeFormSnapshot {
  const _FacadeFormSnapshot({
    required this.sectionCount,
    required this.sectionWidthM,
    required this.storeyCount,
    required this.storeyHeightM,
    required this.standingHeightM,
  });

  factory _FacadeFormSnapshot.fromFacade(FacadeDocument facade) {
    return _FacadeFormSnapshot(
      sectionCount: facade.sections.isNotEmpty
          ? facade.sections.length
          : _defaultSectionCountForFacade(facade),
      sectionWidthM: facade.sections.isNotEmpty ? facade.sections.first.widthM : 2.57,
      storeyCount: facade.storeys.isNotEmpty ? facade.storeys.length : 2,
      storeyHeightM: facade.storeys.isNotEmpty ? facade.storeys.first.heightM : 2.0,
      standingHeightM: facade.standingHeightM,
    );
  }

  final int sectionCount;
  final double sectionWidthM;
  final int storeyCount;
  final double storeyHeightM;
  final double? standingHeightM;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _FacadeFormSnapshot &&
        other.sectionCount == sectionCount &&
        other.sectionWidthM == sectionWidthM &&
        other.storeyCount == storeyCount &&
        other.storeyHeightM == storeyHeightM &&
        other.standingHeightM == standingHeightM;
  }

  @override
  int get hashCode {
    return Object.hash(
      sectionCount,
      sectionWidthM,
      storeyCount,
      storeyHeightM,
      standingHeightM,
    );
  }
}

int _defaultSectionCountForFacade(FacadeDocument facade) {
  if (facade.edgeLengthMm <= 0) return 2;
  final estimate = facade.edgeLengthMm / 2570;
  return math.max(1, estimate.round());
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
              key: const ValueKey('standing-height-input'),
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
                key: const ValueKey('standing-height-apply'),
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
            Text(
              'Plan edge: ${facade.planEdgeId}',
              key: const ValueKey('facade-plan-edge-label'),
            ),
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
              key: const ValueKey('generation-sections-input'),
              controller: sectionsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              decoration: const InputDecoration(labelText: 'Number of sections'),
            ),
            TextField(
              key: const ValueKey('generation-section-width-input'),
              controller: sectionWidthController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Default section width (m)'),
            ),
            TextField(
              key: const ValueKey('generation-storeys-input'),
              controller: storeysController,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              decoration: const InputDecoration(labelText: 'Number of storeys'),
            ),
            TextField(
              key: const ValueKey('generation-storey-height-input'),
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

class _MarkerToolbar extends StatelessWidget {
  const _MarkerToolbar({
    required this.selectedMarkerType,
    required this.onToolChanged,
  });

  final FacadeMarkerType? selectedMarkerType;
  final ValueChanged<FacadeMarkerType?> onToolChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final markerType in FacadeMarkerType.values)
          ChoiceChip(
            key: ValueKey('marker-tool-${markerType.jsonValue}'),
            label: Text(_markerLabel(markerType)),
            selected: selectedMarkerType == markerType,
            onSelected: (isSelected) => onToolChanged(isSelected ? markerType : null),
          ),
        ActionChip(
          key: const ValueKey('marker-tool-cancel'),
          label: const Text('Cancel marker'),
          onPressed: selectedMarkerType == null ? null : () => onToolChanged(null),
        ),
      ],
    );
  }

  String _markerLabel(FacadeMarkerType type) {
    switch (type) {
      case FacadeMarkerType.console:
        return 'Console';
      case FacadeMarkerType.diagonal:
        return 'Diagonal';
      case FacadeMarkerType.ladderDeck:
        return 'Ladder deck';
      case FacadeMarkerType.opening:
        return 'Opening';
      case FacadeMarkerType.textNote:
        return 'Text note';
    }
  }
}

class _FacadeGridCard extends StatelessWidget {
  const _FacadeGridCard({
    required this.projectId,
    required this.facade,
    required this.selectedMarkerTool,
    required this.onMarkerToolChanged,
    required this.onMarkerPlaced,
  });

  final String projectId;
  final FacadeDocument facade;
  final FacadeMarkerType? selectedMarkerTool;
  final ValueChanged<FacadeMarkerType?> onMarkerToolChanged;
  final void Function(double localDx, double localDy) onMarkerPlaced;

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
            _MarkerToolbar(
              selectedMarkerType: selectedMarkerTool,
              onToolChanged: onMarkerToolChanged,
            ),
            const SizedBox(height: 8),
            if (!hasGrid)
              const Text(
                'No grid generated yet for this facade side.',
                key: ValueKey('facade-grid-empty-state'),
              )
            else ...[
              Text(
                '${facade.sections.length} sections · ${facade.storeys.length} storeys',
                key: const ValueKey('facade-grid-generated-summary'),
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 1.6,
                child: _AdjustableFacadeGrid(
                  key: const ValueKey('facade-grid-canvas'),
                  projectId: projectId,
                  facade: facade,
                  selectedMarkerTool: selectedMarkerTool,
                  onMarkerPlaced: onMarkerPlaced,
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
    required this.markers,
    this.activeVerticalDividerIndex,
    this.activeHorizontalDividerIndex,
  });

  final List<FacadeSection> sections;
  final List<FacadeStorey> storeys;
  final double? standingHeightM;
  final double topZoneM;
  final Color lineColor;
  final List<FacadeMarker> markers;
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
    if (heightM != null && heightM > 0 && topZoneM > 0) {
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

    _paintMarkers(canvas, size);
  }

  void _paintMarkers(Canvas canvas, Size size) {
    for (final marker in markers) {
      final normalizedPosition = _resolveMarkerNormalizedPosition(marker);
      final dx = normalizedPosition.dx * size.width;
      final dy = normalizedPosition.dy * size.height;
      switch (marker.type) {
        case FacadeMarkerType.console:
          _drawConsole(canvas, Offset(dx, dy));
          break;
        case FacadeMarkerType.diagonal:
          _drawDiagonal(canvas, Offset(dx, dy));
          break;
        case FacadeMarkerType.ladderDeck:
          _drawLadderDeck(canvas, Offset(dx, dy));
          break;
        case FacadeMarkerType.opening:
          _drawOpening(canvas, Offset(dx, dy));
          break;
        case FacadeMarkerType.textNote:
          _drawTextNote(canvas, Offset(dx, dy), marker.text ?? 'Note');
          break;
      }
    }
  }

  Offset _resolveMarkerNormalizedPosition(FacadeMarker marker) {
    final localDx = marker.localDx;
    final localDy = marker.localDy;
    final normalizedDx =
        localDx?.clamp(0.0, 1.0).toDouble() ?? _normalizedSectionCenter(marker.sectionIndex);
    final normalizedDy =
        localDy?.clamp(0.0, 1.0).toDouble() ?? _normalizedStoreyCenterFromTop(marker.storeyIndex);
    return Offset(normalizedDx, normalizedDy);
  }

  double _normalizedSectionCenter(int sectionIndex) {
    final totalSectionWidth = sections.fold<double>(
      0,
      (sum, section) => sum + section.widthM,
    );
    if (totalSectionWidth <= 0 || sections.isEmpty) {
      return 0.5;
    }

    final clampedIndex = sectionIndex.clamp(0, sections.length - 1);
    final leadingWidth = sections
        .take(clampedIndex)
        .fold<double>(0, (sum, section) => sum + section.widthM);
    final currentWidth = sections[clampedIndex].widthM;
    final center = leadingWidth + (currentWidth / 2);
    return (center / totalSectionWidth).clamp(0.0, 1.0);
  }

  double _normalizedStoreyCenterFromTop(int storeyIndex) {
    final totalStoreyHeight = storeys.fold<double>(
      0,
      (sum, storey) => sum + storey.heightM,
    );
    if (totalStoreyHeight <= 0 || storeys.isEmpty) {
      return 0.5;
    }

    final clampedIndex = storeyIndex.clamp(0, storeys.length - 1);
    final storeysFromTop = storeys.reversed.toList(growable: false);
    final clampedTopIndex = (storeysFromTop.length - 1 - clampedIndex).clamp(
      0,
      storeysFromTop.length - 1,
    );
    final aboveHeight = storeysFromTop
        .take(clampedTopIndex)
        .fold<double>(0, (sum, storey) => sum + storey.heightM);
    final currentHeight = storeysFromTop[clampedTopIndex].heightM;
    final center = aboveHeight + (currentHeight / 2);
    return (center / totalStoreyHeight).clamp(0.0, 1.0);
  }

  void _drawConsole(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromCenter(center: center, width: 18, height: 12);
    canvas.drawRect(rect, paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, paint);
  }

  void _drawDiagonal(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(center.dx - 8, center.dy + 8),
      Offset(center.dx + 8, center.dy - 8),
      paint,
    );
  }

  void _drawLadderDeck(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.indigo
      ..strokeWidth = 2;
    canvas.drawLine(Offset(center.dx - 6, center.dy - 8), Offset(center.dx - 6, center.dy + 8), paint);
    canvas.drawLine(Offset(center.dx + 6, center.dy - 8), Offset(center.dx + 6, center.dy + 8), paint);
    for (var rung = -6.0; rung <= 6; rung += 4) {
      canvas.drawLine(
        Offset(center.dx - 6, center.dy + rung),
        Offset(center.dx + 6, center.dy + rung),
        paint,
      );
    }
  }

  void _drawOpening(Canvas canvas, Offset center) {
    final fill = Paint()..color = Colors.amber.withValues(alpha: 0.45);
    final border = Paint()
      ..color = Colors.amber.shade900
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromCenter(center: center, width: 16, height: 16);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, border);
  }

  void _drawTextNote(Canvas canvas, Offset center, String text) {
    final paint = Paint()..color = Colors.red.withValues(alpha: 0.18);
    final rect = Rect.fromCenter(center: center, width: 44, height: 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w600),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 40);
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _FacadeGridPainter oldDelegate) {
    return oldDelegate.sections != sections ||
        oldDelegate.storeys != storeys ||
        oldDelegate.standingHeightM != standingHeightM ||
        oldDelegate.topZoneM != topZoneM ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.markers != markers ||
        oldDelegate.activeVerticalDividerIndex != activeVerticalDividerIndex ||
        oldDelegate.activeHorizontalDividerIndex != activeHorizontalDividerIndex;
  }
}

enum _GridDragAxis { vertical, horizontal }

class _AdjustableFacadeGrid extends ConsumerStatefulWidget {
  const _AdjustableFacadeGrid({
    super.key,
    required this.projectId,
    required this.facade,
    required this.selectedMarkerTool,
    required this.onMarkerPlaced,
    required this.child,
  });

  final String projectId;
  final FacadeDocument facade;
  final FacadeMarkerType? selectedMarkerTool;
  final void Function(double localDx, double localDy) onMarkerPlaced;
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
          onTapUp: (details) => _onTapUp(details.localPosition, size),
          child: CustomPaint(
            painter: _FacadeGridPainter(
              sections: _previewSections,
              storeys: _previewStoreys,
              standingHeightM: widget.facade.standingHeightM,
              topZoneM: widget.facade.topZoneM,
              lineColor: Theme.of(context).colorScheme.onSurface,
              markers: widget.facade.markers,
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

  void _onTapUp(Offset localPosition, Size size) {
    if (widget.selectedMarkerTool == null) return;
    if (size.width <= 0 || size.height <= 0) return;
    final localDx = (localPosition.dx / size.width).clamp(0.0, 1.0).toDouble();
    final localDy = (localPosition.dy / size.height).clamp(0.0, 1.0).toDouble();
    widget.onMarkerPlaced(localDx, localDy);
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
