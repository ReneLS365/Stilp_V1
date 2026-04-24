import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/manual_packing_list_item.dart';
import '../plan_view/state/plan_view_controller.dart';
import '../project_session/state/project_session_controller.dart';
import 'state/manual_packing_list_controller.dart';

class ManualPackingListScreen extends ConsumerWidget {
  const ManualPackingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionControllerProvider);
    final projectAsync = ref.watch(activeProjectDocumentProvider);

    return projectAsync.when(
      data: (project) {
        if (session == null || project == null) {
          return const Center(child: Text('Ingen aktivt projekt fundet.'));
        }

        final items = project.manualPackingList;

        return Stack(
          key: const ValueKey('manual-packing-list-screen'),
          children: [
            Positioned.fill(
              child: items.isEmpty
                  ? const _ManualPackingEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          key: ValueKey('manual-packing-list-item-${item.id}'),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            title: Text(item.text),
                            subtitle: _quantityLabel(item),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  key: ValueKey('manual-packing-list-edit-${item.id}'),
                                  onPressed: () => _showEditSheet(
                                    context,
                                    ref,
                                    projectId: project.projectId,
                                    item: item,
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Redigér',
                                ),
                                IconButton(
                                  key: ValueKey('manual-packing-list-delete-${item.id}'),
                                  onPressed: () => _deleteItem(ref, project.projectId, item.id, context),
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Slet',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                key: const ValueKey('manual-packing-list-add-button'),
                onPressed: () => _showEditSheet(context, ref, projectId: project.projectId),
                icon: const Icon(Icons.add),
                label: const Text('Tilføj linje'),
              ),
            ),
          ],
        );
      },
      error: (_, __) => const Center(child: Text('Kunne ikke indlæse manuel pakkeliste.')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _quantityLabel(ManualPackingListItem item) {
    if (item.quantity == null && item.unit == null) {
      return const Text('Antal: - · Enhed: -');
    }

    final quantityLabel = item.quantity == null ? '-' : _formatQuantity(item.quantity!);
    final unitLabel = item.unit?.trim().isNotEmpty == true ? item.unit! : '-';
    return Text('Antal: $quantityLabel · Enhed: $unitLabel');
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toStringAsFixed(0);
    }
    return quantity.toString();
  }

  Future<void> _showEditSheet(
    BuildContext context,
    WidgetRef ref, {
    required String projectId,
    ManualPackingListItem? item,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _ManualPackingItemForm(
          item: item,
          onSave: (text, quantity, unit) async {
            final controller = ref.read(manualPackingListControllerProvider);
            final result = item == null
                ? await controller.addItem(
                    projectId: projectId,
                    text: text,
                    quantity: quantity,
                    unit: unit,
                  )
                : await controller.updateItem(
                    projectId: projectId,
                    itemId: item.id,
                    text: text,
                    quantity: quantity,
                    unit: unit,
                  );

            if (!context.mounted) return;

            if (result.isSuccess) {
              ref.invalidate(activeProjectDocumentProvider);
              Navigator.of(context).pop();
            }

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(result.message)));
          },
        );
      },
    );
  }

  Future<void> _deleteItem(WidgetRef ref, String projectId, String itemId, BuildContext context) async {
    final result = await ref
        .read(manualPackingListControllerProvider)
        .deleteItem(projectId: projectId, itemId: itemId);
    if (!context.mounted) return;

    if (result.isSuccess) {
      ref.invalidate(activeProjectDocumentProvider);
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message)));
  }
}

class _ManualPackingEmptyState extends StatelessWidget {
  const _ManualPackingEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('manual-packing-list-empty-state'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingen pakkelinjer endnu',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tilføj manuelle linjer til pakning uden automatisk optælling.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualPackingItemForm extends StatefulWidget {
  const _ManualPackingItemForm({required this.onSave, this.item});

  final ManualPackingListItem? item;
  final Future<void> Function(String text, String quantity, String unit) onSave;

  @override
  State<_ManualPackingItemForm> createState() => _ManualPackingItemFormState();
}

class _ManualPackingItemFormState extends State<_ManualPackingItemForm> {
  late final TextEditingController _textController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.item?.text ?? '');
    _quantityController = TextEditingController(
      text: widget.item?.quantity?.toString() ?? '',
    );
    _unitController = TextEditingController(text: widget.item?.unit ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEditing ? 'Redigér linje' : 'Tilføj linje', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('manual-packing-list-text-input'),
            controller: _textController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Tekst',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('manual-packing-list-quantity-input'),
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Antal',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('manual-packing-list-unit-input'),
            controller: _unitController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Enhed',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                key: const ValueKey('manual-packing-list-cancel-button'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuller'),
              ),
              const Spacer(),
              FilledButton(
                key: const ValueKey('manual-packing-list-save-button'),
                onPressed: () {
                  widget.onSave(
                    _textController.text,
                    _quantityController.text,
                    _unitController.text,
                  );
                },
                child: const Text('Gem'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
