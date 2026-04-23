import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/state/app_shell_controller.dart';
import '../../../data/projects/local_project_store.dart';
import '../../../data/projects/project_mutation_queue.dart';

const double facadeTopZoneHeightM = 1.0;

final facadeStandingHeightControllerProvider = Provider<FacadeStandingHeightController>((ref) {
  final store = ref.watch(localProjectStoreProvider);
  final mutationQueue = ref.watch(projectMutationQueueProvider);
  return FacadeStandingHeightController(
    store: store,
    now: DateTime.now,
    mutationQueue: mutationQueue,
  );
});

class FacadeStandingHeightSaveResult {
  const FacadeStandingHeightSaveResult({
    required this.isSuccess,
    required this.message,
  });

  final bool isSuccess;
  final String message;
}

class FacadeStandingHeightController {
  FacadeStandingHeightController({
    required LocalProjectStore store,
    required DateTime Function() now,
    ProjectMutationQueue? mutationQueue,
  })  : _store = store,
        _now = now,
        _mutationQueue = mutationQueue ?? ProjectMutationQueue();

  final LocalProjectStore _store;
  final DateTime Function() _now;
  final ProjectMutationQueue _mutationQueue;

  Future<FacadeStandingHeightSaveResult> saveStandingHeight({
    required String projectId,
    required String facadeSideId,
    required double? standingHeightM,
  }) async {
    return _mutationQueue.enqueue(projectId, () {
      return _saveStandingHeightInternal(
        projectId: projectId,
        facadeSideId: facadeSideId,
        standingHeightM: standingHeightM,
      );
    });
  }

  Future<FacadeStandingHeightSaveResult> _saveStandingHeightInternal({
    required String projectId,
    required String facadeSideId,
    required double? standingHeightM,
  }) async {
    final project = await _store.getProject(projectId);
    if (project == null) {
      return const FacadeStandingHeightSaveResult(
        isSuccess: false,
        message: 'Kunne ikke finde projekt.',
      );
    }

    final facadeIndex = project.facades.indexWhere((facade) => facade.sideId == facadeSideId);
    if (facadeIndex == -1) {
      return const FacadeStandingHeightSaveResult(
        isSuccess: false,
        message: 'Kunne ikke finde valgt facade.',
      );
    }

    final updatedFacades = [...project.facades];
    updatedFacades[facadeIndex] = updatedFacades[facadeIndex].copyWith(
      standingHeightM: standingHeightM,
      clearStandingHeightM: standingHeightM == null,
      topZoneM: standingHeightM == null ? 0 : facadeTopZoneHeightM,
    );

    await _store.saveProject(
      project.copyWith(
        updatedAt: _now(),
        facades: updatedFacades,
      ),
    );

    return FacadeStandingHeightSaveResult(
      isSuccess: true,
      message: standingHeightM == null
          ? 'Ståhøjde ryddet for facaden.'
          : 'Ståhøjde gemt for facaden.',
    );
  }
}
