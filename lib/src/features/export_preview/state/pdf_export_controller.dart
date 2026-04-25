import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/models/project_document.dart';
import '../pdf/project_pdf_builder.dart';

final projectPdfBuilderProvider = Provider<ProjectPdfBuilder>((ref) {
  return ProjectPdfBuilder();
});

final pdfExportGatewayProvider = Provider<PdfExportGateway>((ref) {
  return const PrintingPdfExportGateway();
});

final pdfExportControllerProvider =
    StateNotifierProvider<PdfExportController, PdfExportState>((ref) {
  return PdfExportController(
    builder: ref.watch(projectPdfBuilderProvider),
    gateway: ref.watch(pdfExportGatewayProvider),
    now: DateTime.now,
  );
});

class PdfExportController extends StateNotifier<PdfExportState> {
  PdfExportController({
    required ProjectPdfBuilder builder,
    required PdfExportGateway gateway,
    required DateTime Function() now,
  })  : _builder = builder,
        _gateway = gateway,
        _now = now,
        super(const PdfExportState());

  final ProjectPdfBuilder _builder;
  final PdfExportGateway _gateway;
  final DateTime Function() _now;

  Future<void> exportActiveProject(ProjectDocument? project) async {
    if (project == null) {
      state = const PdfExportState(errorMessage: 'Ingen aktivt projekt fundet.');
      return;
    }

    state = const PdfExportState(isLoading: true);

    try {
      final pdfBytes = await _builder.build(project);
      final filename = buildPdfFilename(project.projectId, _now());
      await _gateway.openPdf(bytes: pdfBytes, filename: filename);
      state = const PdfExportState(successMessage: 'PDF genereret.');
    } catch (_) {
      state = const PdfExportState(errorMessage: 'Kunne ikke generere PDF.');
    }
  }
}

class PdfExportState {
  const PdfExportState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
}

String buildPdfFilename(String projectId, DateTime timestamp) {
  final safeProjectId = projectId.trim().isEmpty
      ? 'project'
      : projectId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  final year = timestamp.year.toString().padLeft(4, '0');
  final month = timestamp.month.toString().padLeft(2, '0');
  final day = timestamp.day.toString().padLeft(2, '0');
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');

  return 'stilp_${safeProjectId}_${year}${month}${day}_${hour}${minute}.pdf';
}

abstract class PdfExportGateway {
  Future<void> openPdf({
    required Uint8List bytes,
    required String filename,
  });
}

class PrintingPdfExportGateway implements PdfExportGateway {
  const PrintingPdfExportGateway();

  @override
  Future<void> openPdf({
    required Uint8List bytes,
    required String filename,
  }) {
    return Printing.layoutPdf(
      name: filename,
      onLayout: (_) async => bytes,
    );
  }
}
