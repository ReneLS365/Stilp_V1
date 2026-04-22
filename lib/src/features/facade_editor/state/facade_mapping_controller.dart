import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/state/app_shell_controller.dart';
import '../../../core/models/facade_document.dart';
import '../../../core/models/plan_view_data.dart';
import '../../../data/projects/local_project_store.dart';

final facadeMappingControllerProvider = Provider<FacadeMappingController>((ref) {
  final store = ref.watch(localProjectStoreProvider);
  return FacadeMappingController(
    store: store,
    now: DateTime.now,
  );
});

class FacadeMappingResult {
  const FacadeMappingResult({
    required this.isSuccess,
    required this.message,
    this.facadeCount = 0,
  });

  final bool isSuccess;
  final String message;
  final int facadeCount;
}

class FacadeMappingController {
  FacadeMappingController({
    required LocalProjectStore store,
    required DateTime Function() now,
  })  : _store = store,
        _now = now;

  final LocalProjectStore _store;
  final DateTime Function() _now;

  Future<FacadeMappingResult> mapFromPlan(String projectId) async {
    final project = await _store.getProject(projectId);
    if (project == null) {
      return const FacadeMappingResult(
        isSuccess: false,
        message: 'Kunne ikke finde projekt.',
      );
    }

    if (!_isPlanValidForMapping(project.planView)) {
      return const FacadeMappingResult(
        isSuccess: false,
        message: 'Planen mangler sider. Opret mindst én planside først.',
      );
    }

    final existingBySideId = {for (final facade in project.facades) facade.sideId: facade};
    final mappedFacades = project.planView.edges
        .asMap()
        .entries
        .map(
          (entry) => FacadeDocument.fromPlanEdge(
            edge: entry.value,
            sideOrder: entry.key,
            label: _sideLabel(entry.key),
            existing: existingBySideId[entry.value.id],
          ),
        )
        .toList(growable: false);

    final updatedProject = project.copyWith(
      updatedAt: _now(),
      facades: mappedFacades,
    );

    await _store.saveProject(updatedProject);

    return FacadeMappingResult(
      isSuccess: true,
      message: 'Facader opdateret fra plan (${mappedFacades.length} sider).',
      facadeCount: mappedFacades.length,
    );
  }

  static bool _isPlanValidForMapping(PlanViewData planView) {
    return planView.enabled && planView.nodes.length >= 2 && planView.edges.isNotEmpty;
  }

  static String _sideLabel(int index) => 'Side ${index + 1}';
}
