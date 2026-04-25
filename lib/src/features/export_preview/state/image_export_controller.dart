import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/project_document.dart';
import '../image/project_image_builder.dart';

final projectImageBuilderProvider = Provider<ProjectImageBuilder>((ref) {
  return ProjectImageBuilder();
});

final imageExportGatewayProvider = Provider<ImageExportGateway>((ref) {
  return const SharePlusImageExportGateway();
});

final imageExportControllerProvider =
    StateNotifierProvider<ImageExportController, ImageExportState>((ref) {
  return ImageExportController(
    builder: ref.watch(projectImageBuilderProvider),
    gateway: ref.watch(imageExportGatewayProvider),
    now: DateTime.now,
  );
});

class ImageExportController extends StateNotifier<ImageExportState> {
  ImageExportController({
    required ProjectImageBuilder builder,
    required ImageExportGateway gateway,
    required DateTime Function() now,
  })  : _builder = builder,
        _gateway = gateway,
        _now = now,
        super(const ImageExportState());

  final ProjectImageBuilder _builder;
  final ImageExportGateway _gateway;
  final DateTime Function() _now;

  Future<ImageExportState> exportActiveProject(ProjectDocument? project) async {
    if (project == null) {
      const result = ImageExportState(errorMessage: 'Ingen aktivt projekt fundet.');
      state = result;
      return result;
    }

    state = const ImageExportState(isLoading: true);

    try {
      final pngBytes = await _builder.build(project);
      final filename = buildImageFilename(project.projectId, _now());
      await _gateway.shareImage(bytes: pngBytes, filename: filename);
      const result = ImageExportState(successMessage: 'Billede genereret.');
      state = result;
      return result;
    } catch (_) {
      const result = ImageExportState(errorMessage: 'Kunne ikke generere billede.');
      state = result;
      return result;
    }
  }
}

class ImageExportState {
  const ImageExportState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
}

String buildImageFilename(String projectId, DateTime timestamp) {
  final safeProjectId = projectId.trim().isEmpty
      ? 'project'
      : projectId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  final year = timestamp.year.toString().padLeft(4, '0');
  final month = timestamp.month.toString().padLeft(2, '0');
  final day = timestamp.day.toString().padLeft(2, '0');
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final datePart = '$year$month$day';
  final timePart = '$hour$minute';

  return 'stilp_${safeProjectId}_${datePart}_$timePart.png';
}

abstract class ImageExportGateway {
  Future<void> shareImage({
    required Uint8List bytes,
    required String filename,
  });
}

class SharePlusImageExportGateway implements ImageExportGateway {
  const SharePlusImageExportGateway();

  @override
  Future<void> shareImage({required Uint8List bytes, required String filename}) async {
    final tempDirectory = await getTemporaryDirectory();
    final file = File('${tempDirectory.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png', name: filename)],
      subject: filename,
    );
  }
}
