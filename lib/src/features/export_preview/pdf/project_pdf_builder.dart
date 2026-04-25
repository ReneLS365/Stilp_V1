import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/facade_document.dart';
import '../../../core/models/manual_packing_list_item.dart';
import '../../../core/models/plan_side.dart';
import '../../../core/models/project_document.dart';

class ProjectPdfBuilder {
  Future<Uint8List> build(ProjectDocument project) async {
    final document = pw.Document(compress: false);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            'Stilp v1 — Projekteksport',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          _section(
            title: 'Projektoversigt',
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Opgavetype: ${project.taskType.trim().isEmpty ? 'Ikke valgt' : project.taskType.trim()}'),
                pw.Text('Projekt-id: ${_shortProjectId(project.projectId)}'),
                pw.Text('Oprettet: ${_formatDate(project.createdAt)}'),
                pw.Text('Opdateret: ${_formatDate(project.updatedAt)}'),
              ],
            ),
          ),
          _section(
            title: 'Noter',
            child: pw.Text(
              project.notes.trim().isEmpty ? 'Ingen noter.' : project.notes.trim(),
            ),
          ),
          _buildPlanOverview(project),
          _buildFacadeOverview(project.facades),
          _buildPackingList(project.manualPackingList),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _buildPlanOverview(ProjectDocument project) {
    final plan = project.planView;
    final hasPlan = plan.nodes.isNotEmpty || plan.edges.isNotEmpty;

    if (!hasPlan) {
      return _section(title: 'Planoversigt', child: pw.Text('Ingen plan tegnet endnu.'));
    }

    return _section(
      title: 'Planoversigt',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Noder: ${plan.nodes.length}'),
          pw.Text('Sider: ${plan.edges.length}'),
          if (plan.edges.isNotEmpty) pw.SizedBox(height: 6),
          ...plan.edges.map(
            (edge) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '${edge.id}: ${_planSideTypeLabel(edge.sideType)} · ${_formatLengthMm(edge.lengthMm)}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFacadeOverview(List<FacadeDocument> facades) {
    if (facades.isEmpty) {
      return _section(title: 'Facader', child: pw.Text('Ingen facader oprettet endnu.'));
    }

    return _section(
      title: 'Facader',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: facades
            .map(
              (facade) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey500),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      facade.label.trim().isEmpty ? facade.sideId : facade.label.trim(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Plan-side: ${facade.planEdgeId}'),
                    pw.Text('Sidetype: ${_planSideTypeLabel(facade.sideType)}'),
                    pw.Text('Længde: ${_formatLengthMm(facade.edgeLengthMm)}'),
                    pw.Text('Sektioner: ${facade.sections.length}'),
                    pw.Text('Etager: ${facade.storeys.length}'),
                    pw.Text('Markører: ${facade.markers.length}'),
                    pw.Text('Ståhøjde: ${_formatOptionalMeter(facade.standingHeightM)}'),
                    if (facade.standingHeightM != null)
                      pw.Text('Topzone: ${_formatOptionalMeter(facade.topZoneM)}'),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  pw.Widget _buildPackingList(List<ManualPackingListItem> items) {
    if (items.isEmpty) {
      return _section(title: 'Manuel pakkeliste', child: pw.Text('Ingen pakkelinjer endnu.'));
    }

    return _section(
      title: 'Manuel pakkeliste',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items
            .map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  '${item.text} · Antal: ${_formatQuantity(item.quantity)} · Enhed: ${_formatUnit(item.unit)}',
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  pw.Widget _section({required String title, required pw.Widget child}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

String _shortProjectId(String projectId) {
  if (projectId.length <= 8) return projectId;
  return '${projectId.substring(0, 8)}…';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day-$month-${date.year} $hour:$minute';
}

String _formatLengthMm(int lengthMm) {
  final meters = lengthMm / 1000;
  return '${meters.toStringAsFixed(2)} m';
}

String _formatOptionalMeter(double? value) {
  if (value == null) return 'Ikke sat';
  return '${value.toStringAsFixed(2)} m';
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

String _formatQuantity(double? value) {
  if (value == null) return '-';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

String _formatUnit(String? unit) {
  final trimmed = unit?.trim() ?? '';
  if (trimmed.isEmpty) return '-';
  return trimmed;
}
