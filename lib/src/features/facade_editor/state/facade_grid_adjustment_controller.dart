import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/state/app_shell_controller.dart';
import '../../../core/models/facade_section.dart';
import '../../../core/models/facade_storey.dart';
import '../../../data/projects/local_project_store.dart';

final facadeGridAdjustmentControllerProvider = Provider<FacadeGridAdjustmentController>((ref) {
  final store = ref.watch(localProjectStoreProvider);
  return FacadeGridAdjustmentController(
    store: store,
    now: DateTime.now,
  );
});

class FacadeGridAdjustmentResult {
  const FacadeGridAdjustmentResult({
    required this.isSuccess,
    required this.message,
  });

  final bool isSuccess;
  final String message;
}

class FacadeGridAdjustmentController {
  FacadeGridAdjustmentController({
    required LocalProjectStore store,
    required DateTime Function() now,
  })  : _store = store,
        _now = now;

  static const double minimumSectionWidthM = 0.3;
  static const double minimumStoreyHeightM = 0.3;

  final LocalProjectStore _store;
  final DateTime Function() _now;

  static List<FacadeSection> resizeSectionsAtDivider({
    required List<FacadeSection> sections,
    required int dividerIndex,
    required double deltaM,
    double minWidthM = minimumSectionWidthM,
  }) {
    if (dividerIndex < 0 || dividerIndex >= sections.length - 1) {
      return sections;
    }

    final left = sections[dividerIndex];
    final right = sections[dividerIndex + 1];

    final minDelta = minWidthM - left.widthM;
    final maxDelta = right.widthM - minWidthM;
    final clampedDelta = deltaM.clamp(minDelta, maxDelta).toDouble();

    final updated = [...sections];
    updated[dividerIndex] = left.copyWith(widthM: left.widthM + clampedDelta);
    updated[dividerIndex + 1] = right.copyWith(widthM: right.widthM - clampedDelta);
    return List.unmodifiable(updated);
  }

  static List<FacadeStorey> resizeStoreysAtDivider({
    required List<FacadeStorey> storeys,
    required int dividerIndex,
    required double deltaM,
    double minHeightM = minimumStoreyHeightM,
  }) {
    if (dividerIndex < 0 || dividerIndex >= storeys.length - 1) {
      return storeys;
    }

    final top = storeys[dividerIndex];
    final bottom = storeys[dividerIndex + 1];

    final minDelta = minHeightM - top.heightM;
    final maxDelta = bottom.heightM - minHeightM;
    final clampedDelta = deltaM.clamp(minDelta, maxDelta).toDouble();

    final updated = [...storeys];
    updated[dividerIndex] = top.copyWith(heightM: top.heightM + clampedDelta);
    updated[dividerIndex + 1] = bottom.copyWith(heightM: bottom.heightM - clampedDelta);
    return List.unmodifiable(updated);
  }

  Future<FacadeGridAdjustmentResult> saveAdjustedGrid({
    required String projectId,
    required String facadeSideId,
    required List<FacadeSection> sections,
    required List<FacadeStorey> storeys,
  }) async {
    final project = await _store.getProject(projectId);
    if (project == null) {
      return const FacadeGridAdjustmentResult(
        isSuccess: false,
        message: 'Kunne ikke finde projekt.',
      );
    }

    final facadeIndex = project.facades.indexWhere((facade) => facade.sideId == facadeSideId);
    if (facadeIndex == -1) {
      return const FacadeGridAdjustmentResult(
        isSuccess: false,
        message: 'Kunne ikke finde valgt facade.',
      );
    }

    final updatedFacades = [...project.facades];
    updatedFacades[facadeIndex] = updatedFacades[facadeIndex].copyWith(
      sections: sections,
      storeys: storeys,
    );

    await _store.saveProject(
      project.copyWith(
        updatedAt: _now(),
        facades: updatedFacades,
      ),
    );

    return const FacadeGridAdjustmentResult(
      isSuccess: true,
      message: 'Facadegrid opdateret.',
    );
  }
}
