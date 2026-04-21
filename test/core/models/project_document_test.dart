import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/facade_document.dart';
import 'package:stilp_v1/src/core/models/facade_marker.dart';
import 'package:stilp_v1/src/core/models/facade_section.dart';
import 'package:stilp_v1/src/core/models/facade_storey.dart';
import 'package:stilp_v1/src/core/models/manual_packing_list_item.dart';
import 'package:stilp_v1/src/core/models/plan_side.dart';
import 'package:stilp_v1/src/core/models/plan_view_data.dart';
import 'package:stilp_v1/src/core/models/project_document.dart';

void main() {
  test('ProjectDocument supports empty factory, copyWith, and json roundtrip', () {
    final created = DateTime.utc(2026, 4, 21, 10, 30, 0);

    final empty = ProjectDocument.empty(
      projectId: 'p-1',
      taskType: 'Facade stillads',
      notes: 'Initial note',
      now: created,
    );

    expect(empty.projectId, 'p-1');
    expect(empty.createdAt, created);
    expect(empty.updatedAt, created);
    expect(empty.planView.sides, isEmpty);
    expect(empty.facades, isEmpty);
    expect(empty.manualPackingList, isEmpty);

    final updated = empty.copyWith(
      notes: 'Updated note',
      updatedAt: DateTime.utc(2026, 4, 22, 11, 0, 0),
      planView: const PlanViewData(
        sides: [
          PlanSide(
            sideId: 'side-a',
            label: 'A',
            lengthM: 12.5,
            sideType: PlanSideType.wall,
          ),
        ],
      ),
      facades: const [
        FacadeDocument(
          sideId: 'side-a',
          label: 'Side A',
          standingHeightM: 6.0,
          topZoneM: 1.0,
          sections: [
            FacadeSection(id: 'section-1', widthM: 2.57),
          ],
          storeys: [
            FacadeStorey(
              id: 'storey-1',
              heightM: 2.0,
              kind: FacadeStoreyKind.main,
            ),
            FacadeStorey(
              id: 'storey-top',
              heightM: 1.0,
              kind: FacadeStoreyKind.topZone,
            ),
          ],
          markers: [
            FacadeMarker(
              id: 'marker-1',
              type: FacadeMarkerType.console,
              sectionId: 'section-1',
              storeyId: 'storey-1',
              xM: 0.5,
              yM: 1.0,
              text: 'Console marker',
            ),
          ],
        ),
      ],
      manualPackingList: const [
        ManualPackingListItem(
          id: 'pack-1',
          text: 'Diagonal braces',
          quantity: 8,
          unit: 'pcs',
        ),
      ],
    );

    final json = updated.toJson();
    final restored = ProjectDocument.fromJson(json);

    expect(restored.projectId, updated.projectId);
    expect(restored.taskType, updated.taskType);
    expect(restored.notes, updated.notes);
    expect(restored.createdAt, updated.createdAt);
    expect(restored.updatedAt, updated.updatedAt);
    expect(restored.planView.sides.single.sideId, 'side-a');
    expect(restored.facades.single.sections.single.widthM, 2.57);
    expect(restored.facades.single.storeys.last.kind, FacadeStoreyKind.topZone);
    expect(restored.facades.single.markers.single.type, FacadeMarkerType.console);
    expect(restored.manualPackingList.single.text, 'Diagonal braces');
  });
}
