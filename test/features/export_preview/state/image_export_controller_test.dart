import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/features/export_preview/image/project_image_builder.dart';
import 'package:stilp_v1/src/features/export_preview/state/image_export_controller.dart';

void main() {
  test('export fails cleanly when there is no active project', () async {
    final controller = ImageExportController(
      builder: _FakeProjectImageBuilder(),
      gateway: _FakeImageExportGateway(),
      now: () => DateTime.utc(2026, 4, 25, 9, 0),
    );

    final result = await controller.exportActiveProject(null);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.errorMessage, 'Ingen aktivt projekt fundet.');
    expect(controller.state.successMessage, isNull);
    expect(result.errorMessage, 'Ingen aktivt projekt fundet.');
  });

  test('export succeeds for active project', () async {
    final gateway = _FakeImageExportGateway();
    final controller = ImageExportController(
      builder: _FakeProjectImageBuilder(),
      gateway: gateway,
      now: () => DateTime.utc(2026, 4, 25, 9, 0),
    );

    final project = ProjectDocument.empty(
      projectId: 'project-1',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    );

    final result = await controller.exportActiveProject(project);

    expect(controller.state.successMessage, 'Billede genereret.');
    expect(controller.state.errorMessage, isNull);
    expect(gateway.lastFilename, 'stilp_project-1_20260425_0900.png');
    expect(result.successMessage, 'Billede genereret.');
  });

  test('gateway receives png bytes and filename', () async {
    final gateway = _FakeImageExportGateway();
    final expectedBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
    final controller = ImageExportController(
      builder: _FakeProjectImageBuilder(result: expectedBytes),
      gateway: gateway,
      now: () => DateTime.utc(2026, 4, 25, 9, 0),
    );

    final project = ProjectDocument.empty(
      projectId: 'project-abc',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    );

    await controller.exportActiveProject(project);

    expect(gateway.lastBytes, expectedBytes);
    expect(gateway.lastFilename, endsWith('.png'));
  });

  test('filename is sanitized and ends with png', () {
    final filename = buildImageFilename(
      ' project id/with spaces ',
      DateTime.utc(2026, 4, 25, 13, 7),
    );

    expect(filename, 'stilp_project_id_with_spaces_20260425_1307.png');
    expect(filename, endsWith('.png'));
  });

  test('exportActiveProject returns final state directly', () async {
    final controller = ImageExportController(
      builder: _FakeProjectImageBuilder(),
      gateway: _FakeImageExportGateway(),
      now: () => DateTime.utc(2026, 4, 25, 9, 0),
    );
    final project = ProjectDocument.empty(
      projectId: 'project-direct-state',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    );

    final result = await controller.exportActiveProject(project);

    expect(identical(result, controller.state), isTrue);
    expect(result.successMessage, 'Billede genereret.');
  });

  test('export surfaces clear message for oversized image exports', () async {
    final controller = ImageExportController(
      builder: _FakeProjectImageBuilder(error: const ImageExportTooLargeException()),
      gateway: _FakeImageExportGateway(),
      now: () => DateTime.utc(2026, 4, 25, 9, 0),
    );
    final project = ProjectDocument.empty(
      projectId: 'project-too-large',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    );

    final result = await controller.exportActiveProject(project);

    expect(result.errorMessage, ImageExportTooLargeException.userMessage);
    expect(result.successMessage, isNull);
  });
}

class _FakeProjectImageBuilder extends ProjectImageBuilder {
  _FakeProjectImageBuilder({Uint8List? result, this.error})
      : _result = result ?? Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 9, 9]);

  final Uint8List _result;
  final Exception? error;

  @override
  Future<Uint8List> build(ProjectDocument project) async {
    if (error != null) {
      throw error!;
    }
    return _result;
  }
}

class _FakeImageExportGateway implements ImageExportGateway {
  Uint8List? lastBytes;
  String? lastFilename;

  @override
  Future<void> shareImage({required Uint8List bytes, required String filename}) async {
    lastBytes = bytes;
    lastFilename = filename;
  }
}
