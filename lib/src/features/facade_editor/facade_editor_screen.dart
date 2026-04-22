import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/facade_document.dart';
import '../../core/models/facade_section.dart';
import '../../core/models/facade_storey.dart';
import '../plan_view/state/plan_view_controller.dart';
import '../project_session/state/project_session_controller.dart';
import 'state/facade_grid_generation_controller.dart';

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

  String? _lastFacadeSideId;

  @override
  void dispose() {
    _sectionsController.dispose();
    _sectionWidthController.dispose();
    _storeysController.dispose();
    _storeyHeightController.dispose();
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
                    _FacadeGridCard(facade: activeFacade),
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
  const _FacadeGridCard({required this.facade});

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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    painter: _FacadeGridPainter(
                      sections: facade.sections,
                      storeys: facade.storeys,
                      lineColor: Theme.of(context).colorScheme.onSurface,
                    ),
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
    required this.lineColor,
  });

  final List<FacadeSection> sections;
  final List<FacadeStorey> storeys;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    canvas.drawRect(Offset.zero & size, paint);

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
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    var y = size.height;
    for (var index = 0; index < storeys.length - 1; index++) {
      y -= storeys[index].heightM / totalStoreyHeight * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FacadeGridPainter oldDelegate) {
    return oldDelegate.sections != sections ||
        oldDelegate.storeys != storeys ||
        oldDelegate.lineColor != lineColor;
  }
}
