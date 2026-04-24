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
  test('PlanViewData.toJson uses locked planView keys', () {
    const planView = PlanViewData(
      enabled: true,
      nodes: [
        PlanViewNode(id: 'n1', x: 10, y: 20),
      ],
      edges: [
        PlanViewEdge(
          id: 'e1',
          fromNodeId: 'n1',
          toNodeId: 'n1',
          lengthMm: 5000,
          sideType: PlanSideType.langside,
          eavesHeightMm: 3200,
          ridgeHeightMm: 4600,
        ),
      ],
    );

    final json = planView.toJson();

    expect(json.keys, containsAll(<String>['enabled', 'nodes', 'edges']));
    expect(json.keys, isNot(contains('sides')));
    expect((json['edges'] as List).single['sideType'], 'langside');
  });

  test('PlanSideType serializes and parses locked values', () {
    const side = PlanSide(
      sideId: 's1',
      label: 'S1',
      lengthM: 8,
      sideType: PlanSideType.gavl,
    );

    expect(side.toJson()['sideType'], 'gavl');
    expect(
      PlanSide.fromJson({
        'sideId': 's2',
        'label': 'S2',
        'lengthM': 9,
        'sideType': 'andet',
      }).sideType,
      PlanSideType.andet,
    );
  });

  test('FacadeMarker.toJson uses locked marker keys and type values', () {
    const marker = FacadeMarker(
      id: 'm1',
      type: FacadeMarkerType.ladderDeck,
      sectionIndex: 2,
      storeyIndex: 1,
      localDx: 0.25,
      localDy: 0.75,
      text: 'Access',
      meta: {'color': 'orange'},
    );

    final json = marker.toJson();

    expect(json['type'], 'ladder_deck');
    expect(json['sectionIndex'], 2);
    expect(json['storeyIndex'], 1);
    expect(json['localDx'], 0.25);
    expect(json['localDy'], 0.75);
    expect(json.containsKey('sectionId'), isFalse);
    expect(json.containsKey('storeyId'), isFalse);
  });

  test('Lock-compliant project JSON round-trips without data loss for affected fields', () {
    final created = DateTime.utc(2026, 4, 21, 10, 30, 0);
    final updatedAt = DateTime.utc(2026, 4, 22, 11, 0, 0);

    final project = ProjectDocument.empty(
      projectId: 'p-1',
      taskType: 'facade',
      notes: 'Initial note',
      now: created,
    ).copyWith(
      updatedAt: updatedAt,
      planView: const PlanViewData(
        enabled: true,
        nodes: [
          PlanViewNode(id: 'n1', x: 10, y: 20),
          PlanViewNode(id: 'n2', x: 40, y: 20),
        ],
        edges: [
          PlanViewEdge(
            id: 'e1',
            fromNodeId: 'n1',
            toNodeId: 'n2',
            lengthMm: 12000,
            sideType: PlanSideType.gavl,
          ),
        ],
      ),
      facades: const [
        FacadeDocument(
          sideId: 'side-a',
          label: 'Side A',
          planEdgeId: 'e1',
          sideOrder: 0,
          edgeLengthMm: 12000,
          sideType: PlanSideType.gavl,
          eavesHeightMm: 3200,
          ridgeHeightMm: 4600,
          standingHeightM: 6.0,
          topZoneM: 1.0,
          sections: [FacadeSection(id: 'section-1', widthM: 2.57)],
          storeys: [
            FacadeStorey(id: 'storey-1', heightM: 2.0, kind: FacadeStoreyKind.main),
          ],
          markers: [
            FacadeMarker(
              id: 'marker-1',
              type: FacadeMarkerType.textNote,
              sectionIndex: 0,
              storeyIndex: 0,
              localDx: 0.1,
              localDy: 0.9,
              text: 'North side note',
              meta: {'origin': 'manual'},
            ),
          ],
        ),
      ],
      manualPackingList: const [
        ManualPackingListItem(id: 'pack-1', text: 'Diagonal braces', quantity: 8, unit: 'pcs'),
      ],
    );

    final json = project.toJson();
    final restored = ProjectDocument.fromJson(json);

    expect(restored.planView.enabled, isTrue);
    expect(restored.planView.nodes.length, 2);
    expect(restored.planView.edges.single.sideType, PlanSideType.gavl);
    expect(restored.planView.toJson().keys, containsAll(<String>['enabled', 'nodes', 'edges']));
    expect(restored.facades.single.markers.single.type, FacadeMarkerType.textNote);
    expect(restored.facades.single.markers.single.sectionIndex, 0);
    expect(restored.facades.single.markers.single.storeyIndex, 0);
    expect(restored.facades.single.markers.single.localDx, 0.1);
    expect(restored.facades.single.markers.single.localDy, 0.9);
    expect(restored.manualPackingList, hasLength(1));
    expect(restored.manualPackingList.single.id, 'pack-1');
    expect(restored.manualPackingList.single.text, 'Diagonal braces');
    expect(restored.manualPackingList.single.quantity, 8);
    expect(restored.manualPackingList.single.unit, 'pcs');
  });
}
