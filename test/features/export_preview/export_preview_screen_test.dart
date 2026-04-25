import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/facade_document.dart';
import 'package:stilp_v1/src/core/models/facade_marker.dart';
import 'package:stilp_v1/src/core/models/facade_section.dart';
import 'package:stilp_v1/src/core/models/facade_storey.dart';
import 'package:stilp_v1/src/core/models/manual_packing_list_item.dart';
import 'package:stilp_v1/src/core/models/plan_side.dart';
import 'package:stilp_v1/src/core/models/plan_view_data.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/features/export_preview/export_preview_screen.dart';
import 'package:stilp_v1/src/features/export_preview/pdf/project_pdf_builder.dart';
import 'package:stilp_v1/src/features/export_preview/state/pdf_export_controller.dart';
import 'package:stilp_v1/src/features/plan_view/state/plan_view_controller.dart';

void main() {
  testWidgets('no active project shows no-project state', (tester) async {
    await _pumpScreen(
      tester,
      overrides: [
        activeProjectDocumentProvider.overrideWith((ref) async => null),
      ],
    );

    expect(find.text('Ingen aktivt projekt fundet.'), findsOneWidget);
  });

  testWidgets('empty notes/plan/facades/packing list show empty states', (tester) async {
    final project = ProjectDocument.empty(
      projectId: 'project-empty',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    );

    await _pumpScreen(
      tester,
      overrides: [
        activeProjectDocumentProvider.overrideWith((ref) async => project),
      ],
    );

    expect(find.byKey(const ValueKey('export-preview-empty-notes')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-preview-empty-plan')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-preview-empty-facades')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-preview-empty-packing-list')), findsOneWidget);
  });

  testWidgets('project summary renders task type and project identity', (tester) async {
    final project = ProjectDocument.empty(
      projectId: 'project-identity-123',
      taskType: 'Murerstillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    );

    await _pumpScreen(
      tester,
      overrides: [
        activeProjectDocumentProvider.overrideWith((ref) async => project),
      ],
    );

    expect(find.byKey(const ValueKey('export-preview-project-card')), findsOneWidget);
    expect(find.textContaining('Opgavetype: Murerstillads'), findsOneWidget);
    expect(find.textContaining('Projekt-id: project-…'), findsOneWidget);
  });

  testWidgets('notes render when present', (tester) async {
    final project = ProjectDocument.empty(
      projectId: 'project-notes',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    ).copyWith(notes: 'Kørsel fra bagside og ekstra adgang.');

    await _pumpScreen(
      tester,
      overrides: [
        activeProjectDocumentProvider.overrideWith((ref) async => project),
      ],
    );

    expect(find.byKey(const ValueKey('export-preview-notes-card')), findsOneWidget);
    expect(find.text('Kørsel fra bagside og ekstra adgang.'), findsOneWidget);
  });

  testWidgets('plan overview renders node and edge counts', (tester) async {
    final project = ProjectDocument.empty(
      projectId: 'project-plan',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    ).copyWith(
      planView: const PlanViewData(
        enabled: true,
        nodes: [
          PlanViewNode(id: 'n1', x: 0, y: 0),
          PlanViewNode(id: 'n2', x: 100, y: 0),
        ],
        edges: [
          PlanViewEdge(
            id: 'e1',
            fromNodeId: 'n1',
            toNodeId: 'n2',
            lengthMm: 12500,
            sideType: PlanSideType.langside,
          ),
        ],
      ),
    );

    await _pumpScreen(
      tester,
      overrides: [
        activeProjectDocumentProvider.overrideWith((ref) async => project),
      ],
    );

    expect(find.text('Noder: 2'), findsOneWidget);
    expect(find.text('Sider: 1'), findsOneWidget);
    expect(find.text('e1: Langside · 12.50 m'), findsOneWidget);
  });

  testWidgets('facade summaries render key values including standing height/top zone', (tester) async {
    final project = ProjectDocument.empty(
      projectId: 'project-facades',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    ).copyWith(
      facades: const [
        FacadeDocument(
          sideId: 'e1',
          label: 'Facade A',
          planEdgeId: 'e1',
          sideOrder: 0,
          edgeLengthMm: 18000,
          sideType: PlanSideType.gavl,
          eavesHeightMm: null,
          ridgeHeightMm: null,
          standingHeightM: 5.5,
          topZoneM: 1.0,
          sections: [
            FacadeSection(id: 's1', widthM: 3.0),
            FacadeSection(id: 's2', widthM: 3.0),
          ],
          storeys: [
            FacadeStorey(id: 'st1', heightM: 2.0, kind: FacadeStoreyKind.main),
            FacadeStorey(id: 'st2', heightM: 2.0, kind: FacadeStoreyKind.main),
          ],
          markers: [
            FacadeMarker(
              id: 'm1',
              type: FacadeMarkerType.console,
              sectionIndex: 0,
              storeyIndex: 0,
            ),
          ],
        ),
      ],
    );

    await _pumpScreen(
      tester,
      overrides: [
        activeProjectDocumentProvider.overrideWith((ref) async => project),
      ],
    );

    expect(find.byKey(const ValueKey('export-preview-facades-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-preview-facade-e1')), findsOneWidget);
    expect(find.text('Facade A'), findsOneWidget);
    expect(find.text('Sidetype: Gavl'), findsOneWidget);
    expect(find.text('Længde: 18.00 m'), findsOneWidget);
    expect(find.text('Sektioner: 2'), findsOneWidget);
    expect(find.text('Etager: 2'), findsOneWidget);
    expect(find.text('Markører: 1'), findsOneWidget);
    expect(find.text('Ståhøjde: 5.50 m'), findsOneWidget);
    expect(find.text('Topzone: 1.00 m'), findsOneWidget);
  });

  testWidgets('manual packing list renders rows with text/quantity/unit', (tester) async {
    final project = ProjectDocument.empty(
      projectId: 'project-packing',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    ).copyWith(
      manualPackingList: const [
        ManualPackingListItem(id: 'p1', text: 'Rammer', quantity: 40, unit: 'stk'),
      ],
    );

    await _pumpScreen(
      tester,
      overrides: [
        activeProjectDocumentProvider.overrideWith((ref) async => project),
      ],
    );

    expect(find.byKey(const ValueKey('export-preview-packing-item-p1')), findsOneWidget);
    expect(find.text('Rammer'), findsOneWidget);
    expect(find.text('Antal: 40 · Enhed: stk'), findsOneWidget);
  });

  testWidgets('preview updates when provider data changes', (tester) async {
    final projectProvider = StateProvider<ProjectDocument?>((ref) {
      return ProjectDocument.empty(
        projectId: 'project-live',
        taskType: 'Stillads',
        now: DateTime.utc(2026, 4, 25, 8, 0),
      );
    });

    final container = ProviderContainer(
      overrides: [
        activeProjectDocumentProvider.overrideWith(
          (ref) async => ref.watch(projectProvider),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ExportPreviewScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('export-preview-empty-notes')), findsOneWidget);

    container.read(projectProvider.notifier).state = ProjectDocument.empty(
      projectId: 'project-live',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    ).copyWith(notes: 'Opdateret note');

    await tester.pumpAndSettle();
    expect(find.text('Opdateret note'), findsOneWidget);
  });

  testWidgets('export preview shows pdf export button', (tester) async {
    final project = ProjectDocument.empty(
      projectId: 'project-pdf-button',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    );

    await _pumpScreen(
      tester,
      overrides: [
        activeProjectDocumentProvider.overrideWith((ref) async => project),
      ],
    );

    expect(find.byKey(const ValueKey('export-preview-pdf-button')), findsOneWidget);
    expect(find.text('Eksportér PDF'), findsOneWidget);
  });

  testWidgets('tapping PDF export triggers export path and success state', (tester) async {
    final project = ProjectDocument.empty(
      projectId: 'project-pdf-export',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    );
    final controller = _TestPdfExportController(
      initialState: const PdfExportState(),
      onExport: (_) async => const PdfExportState(successMessage: 'PDF genereret.'),
    );

    await _pumpScreen(
      tester,
      overrides: [
        activeProjectDocumentProvider.overrideWith((ref) async => project),
        pdfExportControllerProvider.overrideWith((ref) => controller),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('export-preview-pdf-button')));
    await tester.pumpAndSettle();

    expect(controller.exportCalls, 1);
    expect(find.byKey(const ValueKey('export-preview-pdf-success')), findsOneWidget);
  });

  testWidgets('loading state is shown while pdf export is pending', (tester) async {
    final project = ProjectDocument.empty(
      projectId: 'project-pdf-loading',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    );

    await _pumpScreen(
      tester,
      overrides: [
        activeProjectDocumentProvider.overrideWith((ref) async => project),
        pdfExportControllerProvider.overrideWith(
          (ref) => _TestPdfExportController(
            initialState: const PdfExportState(isLoading: true),
          ),
        ),
      ],
    );

    expect(find.byKey(const ValueKey('export-preview-pdf-loading')), findsOneWidget);
    expect(find.text('Genererer PDF...'), findsOneWidget);
  });

  testWidgets('export failure shows clear error message', (tester) async {
    final project = ProjectDocument.empty(
      projectId: 'project-pdf-error',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8, 0),
    );
    final controller = _TestPdfExportController(
      initialState: const PdfExportState(),
      onExport: (_) async => const PdfExportState(errorMessage: 'Kunne ikke generere PDF.'),
    );

    await _pumpScreen(
      tester,
      overrides: [
        activeProjectDocumentProvider.overrideWith((ref) async => project),
        pdfExportControllerProvider.overrideWith((ref) => controller),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('export-preview-pdf-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('export-preview-pdf-error')), findsOneWidget);
    expect(find.text('Kunne ikke generere PDF.'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: ExportPreviewScreen()),
    ),
  );

  await tester.pumpAndSettle();
}

class _TestPdfExportController extends PdfExportController {
  _TestPdfExportController({
    required PdfExportState initialState,
    Future<PdfExportState> Function(ProjectDocument? project)? onExport,
  })  : _onExport = onExport,
        super(
          builder: _NoopBuilder(),
          gateway: _NoopGateway(),
          now: () => DateTime.utc(2026, 4, 25, 9, 0),
        ) {
    state = initialState;
  }

  final Future<PdfExportState> Function(ProjectDocument? project)? _onExport;
  int exportCalls = 0;

  @override
  Future<void> exportActiveProject(ProjectDocument? project) async {
    exportCalls += 1;
    if (_onExport == null) return;
    state = await _onExport(project);
  }
}

class _NoopBuilder extends ProjectPdfBuilder {}

class _NoopGateway implements PdfExportGateway {
  @override
  Future<void> openPdf({required Uint8List bytes, required String filename}) async {}
}
