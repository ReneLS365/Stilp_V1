import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/facade_document.dart';
import '../../core/models/manual_packing_list_item.dart';
import '../../core/models/plan_side.dart';
import '../../core/models/plan_view_data.dart';
import '../../core/models/project_document.dart';
import '../plan_view/state/plan_view_controller.dart';
import 'state/pdf_export_controller.dart';

class ExportPreviewScreen extends ConsumerWidget {
  const ExportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(activeProjectDocumentProvider);
    final pdfExportState = ref.watch(pdfExportControllerProvider);
    final pdfExportController = ref.read(pdfExportControllerProvider.notifier);

    return projectAsync.when(
      data: (project) {
        if (project == null) {
          return const Center(child: Text('Ingen aktivt projekt fundet.'));
        }

        return ListView(
          key: const ValueKey('export-preview-screen'),
          padding: const EdgeInsets.all(16),
          children: [
            Text('Eksport-preview', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              key: const ValueKey('export-preview-pdf-button'),
              onPressed: pdfExportState.isLoading
                  ? null
                  : () async {
                      await pdfExportController.exportActiveProject(project);
                      final result = ref.read(pdfExportControllerProvider);
                      final message = result.errorMessage ?? result.successMessage;
                      if (message == null || !context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                    },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Eksportér PDF'),
            ),
            if (pdfExportState.isLoading) ...[
              const SizedBox(height: 8),
              Row(
                key: const ValueKey('export-preview-pdf-loading'),
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Genererer PDF...'),
                ],
              ),
            ],
            if (!pdfExportState.isLoading && pdfExportState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                pdfExportState.errorMessage!,
                key: const ValueKey('export-preview-pdf-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (!pdfExportState.isLoading && pdfExportState.successMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                pdfExportState.successMessage!,
                key: const ValueKey('export-preview-pdf-success'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
            const SizedBox(height: 12),
            _ProjectSummarySection(project: project),
            const SizedBox(height: 12),
            _NotesSection(notes: project.notes),
            const SizedBox(height: 12),
            _PlanPreviewSection(plan: project.planView),
            const SizedBox(height: 12),
            _FacadesPreviewSection(facades: project.facades),
            const SizedBox(height: 12),
            _PackingListPreviewSection(items: project.manualPackingList),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Center(child: Text('Kunne ikke indlæse eksport-preview.')),
    );
  }
}

class _ExportPreviewCard extends StatelessWidget {
  const _ExportPreviewCard({
    required this.title,
    required this.child,
    required this.cardKey,
  });

  final String title;
  final Widget child;
  final Key cardKey;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: cardKey,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProjectSummarySection extends StatelessWidget {
  const _ProjectSummarySection({required this.project});

  final ProjectDocument project;

  @override
  Widget build(BuildContext context) {
    return _ExportPreviewCard(
      title: 'Projekt',
      cardKey: const ValueKey('export-preview-project-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Opgavetype: ${project.taskType.isEmpty ? 'Ikke valgt' : project.taskType}'),
          Text('Projekt-id: ${_shortProjectId(project.projectId)}'),
          Text('Oprettet: ${_formatDate(project.createdAt)}'),
          Text('Opdateret: ${_formatDate(project.updatedAt)}'),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final trimmed = notes.trim();

    return _ExportPreviewCard(
      title: 'Noter',
      cardKey: const ValueKey('export-preview-notes-card'),
      child: trimmed.isEmpty
          ? const Text(
              'Ingen noter.',
              key: ValueKey('export-preview-empty-notes'),
            )
          : Text(trimmed),
    );
  }
}

class _PlanPreviewSection extends StatelessWidget {
  const _PlanPreviewSection({required this.plan});

  final PlanViewData plan;

  @override
  Widget build(BuildContext context) {
    final hasPlan = plan.nodes.isNotEmpty || plan.edges.isNotEmpty;

    return _ExportPreviewCard(
      title: 'Planoversigt',
      cardKey: const ValueKey('export-preview-plan-card'),
      child: !hasPlan
          ? const Text(
              'Ingen plan tegnet endnu.',
              key: ValueKey('export-preview-empty-plan'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Noder: ${plan.nodes.length}'),
                Text('Sider: ${plan.edges.length}'),
                if (plan.edges.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...plan.edges.map(
                    (edge) => Text(
                      '${edge.id}: ${_planSideTypeLabel(edge.sideType)} · ${_formatLengthMm(edge.lengthMm)}',
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _FacadesPreviewSection extends StatelessWidget {
  const _FacadesPreviewSection({required this.facades});

  final List<FacadeDocument> facades;

  @override
  Widget build(BuildContext context) {
    return _ExportPreviewCard(
      title: 'Facader',
      cardKey: const ValueKey('export-preview-facades-card'),
      child: facades.isEmpty
          ? const Text(
              'Ingen facader oprettet endnu.',
              key: ValueKey('export-preview-empty-facades'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: facades
                  .map(
                    (facade) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FacadeSummaryTile(facade: facade),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _FacadeSummaryTile extends StatelessWidget {
  const _FacadeSummaryTile({required this.facade});

  final FacadeDocument facade;

  @override
  Widget build(BuildContext context) {
    final standingHeight = facade.standingHeightM;

    return Container(
      key: ValueKey('export-preview-facade-${facade.sideId}'),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(facade.label.isEmpty ? facade.sideId : facade.label),
          Text('Plan-side: ${facade.planEdgeId}'),
          Text('Sidetype: ${_planSideTypeLabel(facade.sideType)}'),
          Text('Længde: ${_formatLengthMm(facade.edgeLengthMm)}'),
          Text('Sektioner: ${facade.sections.length}'),
          Text('Etager: ${facade.storeys.length}'),
          Text('Markører: ${facade.markers.length}'),
          Text('Ståhøjde: ${_formatOptionalMeter(standingHeight)}'),
          if (standingHeight != null) Text('Topzone: ${_formatOptionalMeter(facade.topZoneM)}'),
        ],
      ),
    );
  }
}

class _PackingListPreviewSection extends StatelessWidget {
  const _PackingListPreviewSection({required this.items});

  final List<ManualPackingListItem> items;

  @override
  Widget build(BuildContext context) {
    return _ExportPreviewCard(
      title: 'Manuel pakkeliste',
      cardKey: const ValueKey('export-preview-packing-list-card'),
      child: items.isEmpty
          ? const Text(
              'Ingen pakkelinjer endnu.',
              key: ValueKey('export-preview-empty-packing-list'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map(
                    (item) => Padding(
                      key: ValueKey('export-preview-packing-item-${item.id}'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.text),
                          Text(
                            'Antal: ${_formatQuantity(item.quantity)} · Enhed: ${item.unit?.trim().isEmpty ?? true ? '-' : item.unit!.trim()}',
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

String _shortProjectId(String projectId) {
  if (projectId.length <= 8) return projectId;
  return '${projectId.substring(0, 8)}…';
}

String _formatLengthMm(int lengthMm) {
  final meters = lengthMm / 1000;
  return '${meters.toStringAsFixed(2)} m';
}

String _formatOptionalMeter(double? value) {
  if (value == null) return 'Ikke sat';
  return '${value.toStringAsFixed(2)} m';
}

String _formatQuantity(double? value) {
  if (value == null) return '-';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day-$month-${date.year} $hour:$minute';
}

String _planSideTypeLabel(PlanSideType sideType) {
  switch (sideType) {
    case PlanSideType.langside:
      return 'Langside';
    case PlanSideType.gavl:
      return 'Gavl';
    case PlanSideType.andet:
      return 'Andet';
  }
}
