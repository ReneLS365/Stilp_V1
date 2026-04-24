import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/state/app_shell_controller.dart';
import '../../../core/models/facade_marker.dart';
import '../../../data/projects/local_project_store.dart';
import '../../../data/projects/project_mutation_queue.dart';

final facadeMarkerPlacementControllerProvider = Provider<FacadeMarkerPlacementController>((ref) {
  final store = ref.watch(localProjectStoreProvider);
  final mutationQueue = ref.watch(projectMutationQueueProvider);
  return FacadeMarkerPlacementController(
    store: store,
    now: DateTime.now,
    mutationQueue: mutationQueue,
  );
});

class FacadeMarkerPlacementResult {
  const FacadeMarkerPlacementResult({
    required this.isSuccess,
    required this.message,
  });

  final bool isSuccess;
  final String message;
}

class FacadeMarkerPlacementController {
  FacadeMarkerPlacementController({
    required LocalProjectStore store,
    required DateTime Function() now,
    ProjectMutationQueue? mutationQueue,
  })  : _store = store,
        _now = now,
        _mutationQueue = mutationQueue ?? ProjectMutationQueue();

  final LocalProjectStore _store;
  final DateTime Function() _now;
  final ProjectMutationQueue _mutationQueue;

  Future<FacadeMarkerPlacementResult> placeMarker({
    required String projectId,
    required String facadeSideId,
    required FacadeMarkerType markerType,
    required double localDx,
    required double localDy,
    String? text,
  }) {
    return _mutationQueue.enqueue(projectId, () {
      return _placeMarkerInternal(
        projectId: projectId,
        facadeSideId: facadeSideId,
        markerType: markerType,
        localDx: localDx,
        localDy: localDy,
        text: text,
      );
    });
  }

  Future<FacadeMarkerPlacementResult> _placeMarkerInternal({
    required String projectId,
    required String facadeSideId,
    required FacadeMarkerType markerType,
    required double localDx,
    required double localDy,
    String? text,
  }) async {
    final project = await _store.getProject(projectId);
    if (project == null) {
      return const FacadeMarkerPlacementResult(
        isSuccess: false,
        message: 'Kunne ikke finde projekt.',
      );
    }

    final facadeIndex = project.facades.indexWhere((facade) => facade.sideId == facadeSideId);
    if (facadeIndex == -1) {
      return const FacadeMarkerPlacementResult(
        isSuccess: false,
        message: 'Kunne ikke finde valgt facade.',
      );
    }

    final clampedDx = localDx.clamp(0.0, 1.0).toDouble();
    final clampedDy = localDy.clamp(0.0, 1.0).toDouble();
    final markerText = markerType == FacadeMarkerType.textNote ? (text?.trim().isNotEmpty == true ? text!.trim() : 'Note') : null;

    final marker = FacadeMarker(
      id: 'm_${_now().microsecondsSinceEpoch}',
      type: markerType,
      sectionIndex: 0,
      storeyIndex: 0,
      localDx: clampedDx,
      localDy: clampedDy,
      text: markerText,
    );

    final updatedFacades = [...project.facades];
    final activeFacade = updatedFacades[facadeIndex];
    updatedFacades[facadeIndex] = activeFacade.copyWith(
      markers: List.unmodifiable([...activeFacade.markers, marker]),
    );

    await _store.saveProject(
      project.copyWith(
        updatedAt: _now(),
        facades: updatedFacades,
      ),
    );

    return const FacadeMarkerPlacementResult(
      isSuccess: true,
      message: 'Markør placeret.',
    );
  }
}
