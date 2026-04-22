import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/state/app_shell_controller.dart';
import '../../../core/models/facade_section.dart';
import '../../../core/models/facade_storey.dart';
import '../../../data/projects/local_project_store.dart';

final facadeGridGenerationControllerProvider = Provider<FacadeGridGenerationController>((ref) {
  final store = ref.watch(localProjectStoreProvider);
  return FacadeGridGenerationController(
    store: store,
    now: DateTime.now,
  );
});

class FacadeGridBasisInput {
  const FacadeGridBasisInput({
    required this.numberOfSections,
    required this.defaultSectionWidthM,
    required this.numberOfStoreys,
    required this.defaultStoreyHeightM,
  });

  final int numberOfSections;
  final double defaultSectionWidthM;
  final int numberOfStoreys;
  final double defaultStoreyHeightM;

  bool get isValid {
    return numberOfSections > 0 &&
        defaultSectionWidthM > 0 &&
        numberOfStoreys > 0 &&
        defaultStoreyHeightM > 0;
  }
}

class FacadeGridGenerationResult {
  const FacadeGridGenerationResult({
    required this.isSuccess,
    required this.message,
  });

  final bool isSuccess;
  final String message;
}

class FacadeGridGenerationController {
  FacadeGridGenerationController({
    required LocalProjectStore store,
    required DateTime Function() now,
  })  : _store = store,
        _now = now;

  final LocalProjectStore _store;
  final DateTime Function() _now;

  Future<FacadeGridGenerationResult> generateGrid({
    required String projectId,
    required String facadeSideId,
    required FacadeGridBasisInput basisInput,
  }) async {
    if (!basisInput.isValid) {
      return const FacadeGridGenerationResult(
        isSuccess: false,
        message: 'Alle inputfelter skal have positive værdier.',
      );
    }

    final project = await _store.getProject(projectId);
    if (project == null) {
      return const FacadeGridGenerationResult(
        isSuccess: false,
        message: 'Kunne ikke finde projekt.',
      );
    }

    final facadeIndex = project.facades.indexWhere((facade) => facade.sideId == facadeSideId);
    if (facadeIndex == -1) {
      return const FacadeGridGenerationResult(
        isSuccess: false,
        message: 'Kunne ikke finde valgt facade.',
      );
    }

    final sections = generateSections(
      count: basisInput.numberOfSections,
      defaultWidthM: basisInput.defaultSectionWidthM,
    );
    final storeys = generateStoreys(
      count: basisInput.numberOfStoreys,
      defaultHeightM: basisInput.defaultStoreyHeightM,
    );

    final updatedFacades = [...project.facades];
    updatedFacades[facadeIndex] = updatedFacades[facadeIndex].copyWith(
      sections: sections,
      storeys: storeys,
    );

    final updatedProject = project.copyWith(
      updatedAt: _now(),
      facades: updatedFacades,
    );

    await _store.saveProject(updatedProject);

    return FacadeGridGenerationResult(
      isSuccess: true,
      message: 'Facadegrid genereret (${sections.length} sektioner, ${storeys.length} etager).',
    );
  }

  static List<FacadeSection> generateSections({
    required int count,
    required double defaultWidthM,
  }) {
    return List.generate(
      count,
      (index) => FacadeSection(id: 'sec-${index + 1}', widthM: defaultWidthM),
      growable: false,
    );
  }

  static List<FacadeStorey> generateStoreys({
    required int count,
    required double defaultHeightM,
  }) {
    return List.generate(
      count,
      (index) =>
          FacadeStorey(id: 'st-${index + 1}', heightM: defaultHeightM, kind: FacadeStoreyKind.main),
      growable: false,
    );
  }
}
