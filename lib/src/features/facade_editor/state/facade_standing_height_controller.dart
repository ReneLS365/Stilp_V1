import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/state/app_shell_controller.dart';
import '../../../data/projects/local_project_store.dart';

const double facadeTopZoneHeightM = 1.0;

final facadeStandingHeightControllerProvider = Provider<FacadeStandingHeightController>((ref) {
  final store = ref.watch(localProjectStoreProvider);
  return FacadeStandingHeightController(
    store: store,
    now: DateTime.now,
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
  })  : _store = store,
        _now = now;

  final LocalProjectStore _store;
  final DateTime Function() _now;
  Future<void> _pendingSave = Future<void>.value();

  Future<FacadeStandingHeightSaveResult> saveStandingHeight({
    required String projectId,
    required String facadeSideId,
    required double? standingHeightM,
  }) async {
    final saveOperation = _pendingSave.then((_) {
      return _saveStandingHeightInternal(
        projectId: projectId,
        facadeSideId: facadeSideId,
        standingHeightM: standingHeightM,
      );
    });
    _pendingSave = saveOperation.then<void>((_) {}, onError: (_, __) {});
    return saveOperation;
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
