import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/models/facade_document.dart';
import '../../../core/models/manual_packing_list_item.dart';
import '../../../core/models/plan_side.dart';
import '../../../core/models/project_document.dart';

class ProjectImageBuilder {
  static const double _imageWidth = 1080;
  static const double _outerPadding = 48;
  static const double _sectionPadding = 24;
  static const double _sectionSpacing = 24;
  static const double _lineSpacing = 8;

  Future<Uint8List> build(ProjectDocument project) async {
    final titleStyle = _textStyle(
      fontSize: 46,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF111827),
    );
    final headingStyle = _textStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1F2937),
    );
    final bodyStyle = _textStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF111827),
    );

    final blocks = _buildBlocks(project);
    final textMaxWidth =
        _imageWidth - (_outerPadding * 2) - (_sectionPadding * 2);

    final titlePainter = _layoutPainter('Stilp eksportoversigt', titleStyle, textMaxWidth);

    final measuredSections = blocks.map((block) {
      final headingPainter = _layoutPainter(block.title, headingStyle, textMaxWidth);
      final bodyPainters = block.lines
          .map((line) => _layoutPainter(line, bodyStyle, textMaxWidth))
          .toList(growable: false);
      final bodyHeight = bodyPainters.fold<double>(0, (sum, painter) {
        return sum + painter.height;
      });
      final linesSpacing =
          bodyPainters.length > 1 ? (bodyPainters.length - 1) * _lineSpacing : 0;
      final sectionHeight =
          _sectionPadding * 2 + headingPainter.height + 12 + bodyHeight + linesSpacing;

      return _MeasuredSection(
        titlePainter: headingPainter,
        bodyPainters: bodyPainters,
        height: sectionHeight,
      );
    }).toList(growable: false);

    final sectionsHeight = measuredSections.fold<double>(0, (sum, section) {
      return sum + section.height;
    });

    final calculatedHeight =
        _outerPadding +
        titlePainter.height +
        24 +
        sectionsHeight +
        (_sectionSpacing * (measuredSections.length - 1)) +
        _outerPadding;
    final imageHeight = calculatedHeight.ceil().clamp(1, 30000);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, _imageWidth, imageHeight.toDouble()),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, _imageWidth, imageHeight.toDouble()),
      Paint()..color = const Color(0xFFF9FAFB),
    );

    double y = _outerPadding;
    titlePainter.paint(canvas, Offset(_outerPadding, y));
    y += titlePainter.height + 24;

    for (final section in measuredSections) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(_outerPadding, y, _imageWidth - (_outerPadding * 2), section.height),
        const Radius.circular(16),
      );
      canvas.drawRRect(rect, Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawRRect(
        rect,
        Paint()
          ..color = const Color(0xFFE5E7EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      double sectionY = y + _sectionPadding;
      section.titlePainter.paint(canvas, Offset(_outerPadding + _sectionPadding, sectionY));
      sectionY += section.titlePainter.height + 12;
      for (final linePainter in section.bodyPainters) {
        linePainter.paint(canvas, Offset(_outerPadding + _sectionPadding, sectionY));
        sectionY += linePainter.height + _lineSpacing;
      }

      y += section.height + _sectionSpacing;
    }

    final image = await recorder.endRecording().toImage(_imageWidth.toInt(), imageHeight);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('Could not encode PNG bytes.');
    }
    return bytes.buffer.asUint8List();
  }

  List<_SectionBlock> _buildBlocks(ProjectDocument project) {
    return [
      _SectionBlock(
        title: 'Projekt',
        lines: [
          'Opgavetype: ${project.taskType.isEmpty ? 'Ikke valgt' : project.taskType}',
          'Projekt-id: ${_shortProjectId(project.projectId)}',
          'Oprettet: ${_formatDate(project.createdAt)}',
          'Opdateret: ${_formatDate(project.updatedAt)}',
        ],
      ),
      _SectionBlock(
        title: 'Noter',
        lines: [project.notes.trim().isEmpty ? 'Ingen noter.' : project.notes.trim()],
      ),
      _SectionBlock(
        title: 'Planoversigt',
        lines: _planLines(project),
      ),
      _SectionBlock(
        title: 'Facader',
        lines: _facadeLines(project.facades),
      ),
      _SectionBlock(
        title: 'Manuel pakkeliste',
        lines: _packingLines(project.manualPackingList),
      ),
    ];
  }

  List<String> _planLines(ProjectDocument project) {
    final plan = project.planView;
    if (plan.nodes.isEmpty && plan.edges.isEmpty) {
      return const ['Ingen plan tegnet endnu.'];
    }

    final lines = <String>[
      'Noder: ${plan.nodes.length}',
      'Sider: ${plan.edges.length}',
    ];
    for (final edge in plan.edges) {
      lines.add('${edge.id}: ${_planSideTypeLabel(edge.sideType)} · ${_formatLengthMm(edge.lengthMm)}');
    }
    return lines;
  }

  List<String> _facadeLines(List<FacadeDocument> facades) {
    if (facades.isEmpty) {
      return const ['Ingen facader oprettet endnu.'];
    }

    final lines = <String>[];
    for (final facade in facades) {
      lines.add('• ${facade.label.isEmpty ? facade.sideId : facade.label}');
      lines.add('  Plan-side: ${facade.planEdgeId}');
      lines.add('  Sidetype: ${_planSideTypeLabel(facade.sideType)}');
      lines.add('  Længde: ${_formatLengthMm(facade.edgeLengthMm)}');
      lines.add('  Sektioner: ${facade.sections.length}');
      lines.add('  Etager: ${facade.storeys.length}');
      lines.add('  Ståhøjde: ${_formatOptionalMeter(facade.standingHeightM)}');
      if (facade.standingHeightM != null) {
        lines.add('  Topzone: ${_formatOptionalMeter(facade.topZoneM)}');
      }
      lines.add('  Markører: ${facade.markers.length}');
    }
    return lines;
  }

  List<String> _packingLines(List<ManualPackingListItem> items) {
    if (items.isEmpty) {
      return const ['Ingen pakkelinjer endnu.'];
    }

    final lines = <String>[];
    for (final item in items) {
      lines.add('• ${item.text.trim().isEmpty ? '-' : item.text.trim()}');
      lines.add(
        '  Antal: ${_formatQuantity(item.quantity)} · Enhed: ${item.unit?.trim().isEmpty ?? true ? '-' : item.unit!.trim()}',
      );
    }
    return lines;
  }
}

class _SectionBlock {
  const _SectionBlock({required this.title, required this.lines});

  final String title;
  final List<String> lines;
}

class _MeasuredSection {
  const _MeasuredSection({
    required this.titlePainter,
    required this.bodyPainters,
    required this.height,
  });

  final TextPainter titlePainter;
  final List<TextPainter> bodyPainters;
  final double height;
}

TextPainter _layoutPainter(String text, TextStyle style, double maxWidth) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: null,
  );
  painter.layout(minWidth: 0, maxWidth: maxWidth);
  return painter;
}

TextStyle _textStyle({
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: 1.3,
  );
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
