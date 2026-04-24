import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/state/app_shell_controller.dart';
import '../../../core/models/facade_marker.dart';
import '../../../data/projects/local_project_store.dart';
import '../../../data/projects/project_mutation_queue.dart';

final facadeMarkerEditingControllerProvider = Provider<FacadeMarkerEditingController>((ref) {
  final store = ref.watch(localProjectStoreProvider);
  final mutationQueue = ref.watch(projectMutationQueueProvider);
  return FacadeMarkerEditingController(
    store: store,
    now: DateTime.now,
    mutationQueue: mutationQueue,
  );
});

class FacadeMarkerEditingResult {
  const FacadeMarkerEditingResult({
    required this.isSuccess,
    required this.message,
  });

  final bool isSuccess;
  final String message;
}

class FacadeMarkerEditingController {
  FacadeMarkerEditingController({
    required LocalProjectStore store,
    required DateTime Function() now,
    ProjectMutationQueue? mutationQueue,
  })  : _store = store,
        _now = now,
        _mutationQueue = mutationQueue ?? ProjectMutationQueue();

  final LocalProjectStore _store;
  final DateTime Function() _now;
  final ProjectMutationQueue _mutationQueue;

  Future<FacadeMarkerEditingResult> moveMarker({
    required String projectId,
    required String facadeSideId,
    required String markerId,
    required double localDx,
    required double localDy,
  }) {
    return _mutationQueue.enqueue(projectId, () {
      return _updateMarker(
        projectId: projectId,
        facadeSideId: facadeSideId,
        markerId: markerId,
        transform: (marker) => marker.copyWith(
          localDx: localDx.clamp(0.0, 1.0).toDouble(),
          localDy: localDy.clamp(0.0, 1.0).toDouble(),
        ),
        successMessage: 'Markør flyttet.',
      );
    });
  }

  Future<FacadeMarkerEditingResult> updateTextNote({
    required String projectId,
    required String facadeSideId,
    required String markerId,
    required String text,
  }) {
    return _mutationQueue.enqueue(projectId, () {
      return _updateMarker(
        projectId: projectId,
        facadeSideId: facadeSideId,
        markerId: markerId,
        transform: (marker) {
          if (marker.type != FacadeMarkerType.textNote) {
            return marker;
          }
          final trimmedText = text.trim();
          return marker.copyWith(text: trimmedText.isEmpty ? 'Note' : trimmedText);
        },
        successMessage: 'Markør opdateret.',
      );
    });
  }

  Future<FacadeMarkerEditingResult> deleteMarker({
    required String projectId,
    required String facadeSideId,
    required String markerId,
  }) {
    return _mutationQueue.enqueue(projectId, () async {
      final project = await _store.getProject(projectId);
      if (project == null) {
        return const FacadeMarkerEditingResult(
          isSuccess: false,
          message: 'Kunne ikke finde projekt.',
        );
      }

      final facadeIndex = project.facades.indexWhere((facade) => facade.sideId == facadeSideId);
      if (facadeIndex == -1) {
        return const FacadeMarkerEditingResult(
          isSuccess: false,
          message: 'Kunne ikke finde valgt facade.',
        );
      }

      final facade = project.facades[facadeIndex];
      final markerExists = facade.markers.any((marker) => marker.id == markerId);
      if (!markerExists) {
        return const FacadeMarkerEditingResult(
          isSuccess: false,
          message: 'Kunne ikke finde markør.',
        );
      }

      final updatedFacades = [...project.facades];
      updatedFacades[facadeIndex] = facade.copyWith(
        markers: List.unmodifiable(
          facade.markers.where((marker) => marker.id != markerId),
        ),
      );

      await _store.saveProject(
        project.copyWith(
          updatedAt: _now(),
          facades: updatedFacades,
        ),
      );

      return const FacadeMarkerEditingResult(
        isSuccess: true,
        message: 'Markør slettet.',
      );
    });
  }

  Future<FacadeMarkerEditingResult> _updateMarker({
    required String projectId,
    required String facadeSideId,
    required String markerId,
    required FacadeMarker Function(FacadeMarker marker) transform,
    required String successMessage,
  }) async {
    final project = await _store.getProject(projectId);
    if (project == null) {
      return const FacadeMarkerEditingResult(
        isSuccess: false,
        message: 'Kunne ikke finde projekt.',
      );
    }

    final facadeIndex = project.facades.indexWhere((facade) => facade.sideId == facadeSideId);
    if (facadeIndex == -1) {
      return const FacadeMarkerEditingResult(
        isSuccess: false,
        message: 'Kunne ikke finde valgt facade.',
      );
    }

    final facade = project.facades[facadeIndex];
    final markerIndex = facade.markers.indexWhere((marker) => marker.id == markerId);
    if (markerIndex == -1) {
      return const FacadeMarkerEditingResult(
        isSuccess: false,
        message: 'Kunne ikke finde markør.',
      );
    }

    final updatedMarkers = [...facade.markers];
    updatedMarkers[markerIndex] = transform(updatedMarkers[markerIndex]);

    final updatedFacades = [...project.facades];
    updatedFacades[facadeIndex] = facade.copyWith(
      markers: List.unmodifiable(updatedMarkers),
    );

    await _store.saveProject(
      project.copyWith(
        updatedAt: _now(),
        facades: updatedFacades,
      ),
    );

    return FacadeMarkerEditingResult(
      isSuccess: true,
      message: successMessage,
    );
  }
}
