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
    expect(pdfText, contains('Ingen plan tegnet endnu.'));
    expect(pdfText, contains('Ingen facader oprettet endnu.'));
    expect(pdfText, contains('Ingen pakkelinjer endnu.'));
  });

  test('notes section handles note text and empty notes', () async {
    final withNotes = _populatedProject();
    final emptyNotes = withNotes.copyWith(notes: '   ');

    final withNotesBytes = await builder.build(withNotes);
    final emptyNotesBytes = await builder.build(emptyNotes);

    expect(latin1.decode(withNotesBytes, allowInvalid: true), contains('Projektnoter her'));
    expect(latin1.decode(emptyNotesBytes, allowInvalid: true), contains('Ingen noter.'));
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
    expect(pdfText, contains('Ståhøjde: 5.50 m'));
    expect(pdfText, contains('Topzone: 1.00 m'));
  });

  test('facade marker counts do not crash builder', () async {
    final project = _populatedProject();

    final bytes = await builder.build(project);
    final pdfText = latin1.decode(bytes, allowInvalid: true);

    expect(bytes, isNotEmpty);
    expect(pdfText, contains('Markører: 2'));
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
