import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../plan_view/state/plan_view_controller.dart';
import '../project_session/state/project_session_controller.dart';

class FacadeEditorScreen extends ConsumerWidget {
  const FacadeEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activeFacade.label, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Plan edge: ${activeFacade.planEdgeId}'),
                      Text('Order: ${activeFacade.sideOrder + 1}'),
                      Text('Length: ${(activeFacade.edgeLengthMm / 1000).toStringAsFixed(2)} m'),
                      Text('Type: ${activeFacade.sideType.jsonValue}'),
                      Text('Eaves: ${activeFacade.eavesHeightMm?.toString() ?? '-'} mm'),
                      Text('Ridge: ${activeFacade.ridgeHeightMm?.toString() ?? '-'} mm'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: facades.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final facade = facades[index];
                    return ListTile(
                      tileColor: facade.sideId == activeFacade.sideId
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : null,
                      title: Text(facade.label),
                      subtitle: Text(
                        '${(facade.edgeLengthMm / 1000).toStringAsFixed(2)} m · ${facade.sideType.jsonValue}',
                      ),
                      onTap: () => ref
                          .read(projectSessionControllerProvider.notifier)
                          .setSelectedFacadeSide(facade.sideId),
                    );
                  },
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
}
