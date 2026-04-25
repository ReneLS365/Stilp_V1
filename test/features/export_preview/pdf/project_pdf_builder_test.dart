import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/facade_document.dart';
import 'package:stilp_v1/src/core/models/facade_marker.dart';
import 'package:stilp_v1/src/core/models/facade_section.dart';
import 'package:stilp_v1/src/core/models/facade_storey.dart';
import 'package:stilp_v1/src/core/models/manual_packing_list_item.dart';
import 'package:stilp_v1/src/core/models/plan_side.dart';
import 'package:stilp_v1/src/core/models/plan_view_data.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';
import 'package:stilp_v1/src/features/export_preview/pdf/project_pdf_builder.dart';

void main() {
  final builder = ProjectPdfBuilder();

  test('generates non-empty bytes for populated project', () async {
    final project = _populatedProject();

    final bytes = await builder.build(project);

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(200));
  });

  test('empty project sections do not crash builder and include empty states', () async {
    final project = ProjectDocument.empty(
      projectId: 'empty-project',
      taskType: 'Stillads',
      now: DateTime.utc(2026, 4, 25, 8),
    );

    final bytes = await builder.build(project);
    final pdfText = latin1.decode(bytes, allowInvalid: true);

    expect(bytes, isNotEmpty);
    expect(pdfText, contains('Ingen'));
    expect(pdfText, contains('plan'));
    expect(pdfText, contains('tegnet'));
    expect(pdfText, contains('endnu.'));
    expect(pdfText, contains('facader'));
    expect(pdfText, contains('oprettet'));
    expect(pdfText, contains('pakkelinjer'));
  });

  test('notes section handles note text and empty notes', () async {
    final withNotes = _populatedProject();
    final emptyNotes = withNotes.copyWith(notes: '   ');

    final withNotesBytes = await builder.build(withNotes);
    final emptyNotesBytes = await builder.build(emptyNotes);

    final withNotesText = latin1.decode(withNotesBytes, allowInvalid: true);
    final emptyNotesText = latin1.decode(emptyNotesBytes, allowInvalid: true);

    expect(withNotesText, contains('Projektnoter'));
    expect(withNotesText, contains('her'));
    expect(emptyNotesText, contains('Ingen'));
    expect(emptyNotesText, contains('noter.'));
  });

  test('manual packing list rows are included in generated pdf text stream', () async {
    final project = _populatedProject();

    final bytes = await builder.build(project);
    final pdfText = latin1.decode(bytes, allowInvalid: true);

    expect(pdfText, contains('Rammer'));
    expect(pdfText, contains('Planker'));
  });

  test('facade standing height and top zone values do not crash builder', () async {
    final project = _populatedProject();

    final bytes = await builder.build(project);
    final pdfText = latin1.decode(bytes, allowInvalid: true);

    expect(bytes, isNotEmpty);
    expect(pdfText, contains('Ståhøjde:'));
    expect(pdfText, contains('5.50'));
    expect(pdfText, contains('Topzone:'));
    expect(pdfText, contains('1.00'));
  });

  test('facade marker counts do not crash builder', () async {
    final project = _populatedProject();

    final bytes = await builder.build(project);
    final pdfText = latin1.decode(bytes, allowInvalid: true);

    expect(bytes, isNotEmpty);
    expect(pdfText, contains('Markører:'));
    expect(pdfText, contains('2'));
  });

  test('builds pdf with many facades without page overflow', () async {
    final facades = List.generate(
      80,
      (index) => FacadeDocument(
        sideId: 'e$index',
        label: 'Facade $index',
        planEdgeId: 'e$index',
        sideOrder: index,
        edgeLengthMm: 15000 + index,
        sideType: PlanSideType.langside,
        eavesHeightMm: null,
        ridgeHeightMm: null,
        standingHeightM: 5.0,
        topZoneM: 1.0,
        sections: const [FacadeSection(id: 's', widthM: 3.0)],
        storeys: const [FacadeStorey(id: 'st', heightM: 2.0, kind: FacadeStoreyKind.main)],
        markers: const [],
      ),
    );
    final project = _populatedProject().copyWith(facades: facades);

    final bytes = await builder.build(project);

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(200));
  });

  test('builds pdf with many packing rows without page overflow', () async {
    final items = List.generate(
      160,
      (index) => ManualPackingListItem(
        id: 'item-$index',
        text: 'Pakkelinje $index',
        quantity: index + 1,
        unit: 'stk',
      ),
    );
    final project = _populatedProject().copyWith(manualPackingList: items);

    final bytes = await builder.build(project);

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(200));
  });
}

ProjectDocument _populatedProject() {
  return ProjectDocument.empty(
    projectId: 'project-pdf-123',
    taskType: 'Murerstillads',
    now: DateTime.utc(2026, 4, 25, 8),
  ).copyWith(
    notes: 'Projektnoter her',
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
          lengthMm: 18000,
          sideType: PlanSideType.langside,
        ),
      ],
    ),
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
        ],
        storeys: [
          FacadeStorey(id: 'st1', heightM: 2.0, kind: FacadeStoreyKind.main),
        ],
        markers: [
          FacadeMarker(
            id: 'm1',
            type: FacadeMarkerType.console,
            sectionIndex: 0,
            storeyIndex: 0,
          ),
          FacadeMarker(
            id: 'm2',
            type: FacadeMarkerType.diagonal,
            sectionIndex: 0,
            storeyIndex: 0,
          ),
        ],
      ),
    ],
    manualPackingList: const [
      ManualPackingListItem(id: 'p1', text: 'Rammer', quantity: 40, unit: 'stk'),
      ManualPackingListItem(id: 'p2', text: 'Planker', quantity: 12.5, unit: 'm'),
    ],
  );
}
