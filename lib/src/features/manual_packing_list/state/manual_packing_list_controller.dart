import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/state/app_shell_controller.dart';
import '../../../core/models/manual_packing_list_item.dart';
import '../../../data/projects/local_project_store.dart';
import '../../../data/projects/project_mutation_queue.dart';

final manualPackingListControllerProvider = Provider<ManualPackingListController>((ref) {
  final store = ref.watch(localProjectStoreProvider);
  final mutationQueue = ref.watch(projectMutationQueueProvider);
  return ManualPackingListController(
    store: store,
    now: DateTime.now,
    mutationQueue: mutationQueue,
  );
});

class ManualPackingListOperationResult {
  const ManualPackingListOperationResult({
    required this.isSuccess,
    required this.message,
  });

  final bool isSuccess;
  final String message;
}

class ManualPackingListController {
  ManualPackingListController({
    required LocalProjectStore store,
    required DateTime Function() now,
    ProjectMutationQueue? mutationQueue,
  })  : _store = store,
        _now = now,
        _mutationQueue = mutationQueue ?? ProjectMutationQueue();

  final LocalProjectStore _store;
  final DateTime Function() _now;
  final ProjectMutationQueue _mutationQueue;

  Future<ManualPackingListOperationResult> addItem({
    required String projectId,
    required String text,
    required String quantity,
    required String unit,
  }) {
    return _mutationQueue.enqueue(projectId, () async {
      final parsed = _parseInputs(text: text, quantity: quantity, unit: unit);
      if (!parsed.isValid) {
        return ManualPackingListOperationResult(
          isSuccess: false,
          message: parsed.errorMessage,
        );
      }

      final project = await _store.getProject(projectId);
      if (project == null) {
        return const ManualPackingListOperationResult(
          isSuccess: false,
          message: 'Kunne ikke finde projekt.',
        );
      }

      final item = ManualPackingListItem(
        id: 'pack_${_now().microsecondsSinceEpoch}',
        text: parsed.text!,
        quantity: parsed.quantity,
        unit: parsed.unit,
      );

      await _store.saveProject(
        project.copyWith(
          updatedAt: _now(),
          manualPackingList: [...project.manualPackingList, item],
        ),
      );

      return const ManualPackingListOperationResult(
        isSuccess: true,
        message: 'Pakkelinje tilføjet.',
      );
    });
  }

  Future<ManualPackingListOperationResult> updateItem({
    required String projectId,
    required String itemId,
    required String text,
    required String quantity,
    required String unit,
  }) {
    return _mutationQueue.enqueue(projectId, () async {
      final parsed = _parseInputs(text: text, quantity: quantity, unit: unit);
      if (!parsed.isValid) {
        return ManualPackingListOperationResult(
          isSuccess: false,
          message: parsed.errorMessage,
        );
      }

      final project = await _store.getProject(projectId);
      if (project == null) {
        return const ManualPackingListOperationResult(
          isSuccess: false,
          message: 'Kunne ikke finde projekt.',
        );
      }

      final index = project.manualPackingList.indexWhere((item) => item.id == itemId);
      if (index == -1) {
        return const ManualPackingListOperationResult(
          isSuccess: false,
          message: 'Kunne ikke finde pakkelinje.',
        );
      }

      final updatedItems = [...project.manualPackingList];
      updatedItems[index] = updatedItems[index].copyWith(
        text: parsed.text,
        quantity: parsed.quantity,
        unit: parsed.unit,
        clearQuantity: parsed.quantity == null,
        clearUnit: parsed.unit == null,
      );

      await _store.saveProject(
        project.copyWith(
          updatedAt: _now(),
          manualPackingList: updatedItems,
        ),
      );

      return const ManualPackingListOperationResult(
        isSuccess: true,
        message: 'Pakkelinje opdateret.',
      );
    });
  }

  Future<ManualPackingListOperationResult> deleteItem({
    required String projectId,
    required String itemId,
  }) {
    return _mutationQueue.enqueue(projectId, () async {
      final project = await _store.getProject(projectId);
      if (project == null) {
        return const ManualPackingListOperationResult(
          isSuccess: false,
          message: 'Kunne ikke finde projekt.',
        );
      }

      final itemExists = project.manualPackingList.any((item) => item.id == itemId);
      if (!itemExists) {
        return const ManualPackingListOperationResult(
          isSuccess: false,
          message: 'Kunne ikke finde pakkelinje.',
        );
      }

      final updatedItems =
          project.manualPackingList.where((item) => item.id != itemId).toList(growable: false);

      await _store.saveProject(
        project.copyWith(
          updatedAt: _now(),
          manualPackingList: updatedItems,
        ),
      );

      return const ManualPackingListOperationResult(
        isSuccess: true,
        message: 'Pakkelinje slettet.',
      );
    });
  }

  _ManualPackingInputParseResult _parseInputs({
    required String text,
    required String quantity,
    required String unit,
  }) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return const _ManualPackingInputParseResult.invalid('Tekst skal udfyldes.');
    }

    final trimmedQuantity = quantity.trim();
    double? parsedQuantity;
    if (trimmedQuantity.isNotEmpty) {
      final value = double.tryParse(trimmedQuantity);
      if (value == null || !value.isFinite) {
        return const _ManualPackingInputParseResult.invalid(
          'Antal skal være et gyldigt tal eller tomt.',
        );
      }
      parsedQuantity = value;
    }

    final trimmedUnit = unit.trim();

    return _ManualPackingInputParseResult.valid(
      text: trimmedText,
      quantity: parsedQuantity,
      unit: trimmedUnit.isEmpty ? null : trimmedUnit,
    );
  }
}

class _ManualPackingInputParseResult {
  const _ManualPackingInputParseResult._({
    required this.isValid,
    this.text,
    this.quantity,
    this.unit,
    this.errorMessage = '',
  });

  const _ManualPackingInputParseResult.valid({
    required String text,
    required double? quantity,
    required String? unit,
  }) : this._(
          isValid: true,
          text: text,
          quantity: quantity,
          unit: unit,
        );

  const _ManualPackingInputParseResult.invalid(String errorMessage)
      : this._(
          isValid: false,
          errorMessage: errorMessage,
        );

  final bool isValid;
  final String? text;
  final double? quantity;
  final String? unit;
  final String errorMessage;
}
