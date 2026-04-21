import 'plan_side.dart';

class PlanViewData {
  const PlanViewData({required this.sides});

  final List<PlanSide> sides;

  factory PlanViewData.empty() {
    return const PlanViewData(sides: []);
  }

  PlanViewData copyWith({List<PlanSide>? sides}) {
    return PlanViewData(sides: sides ?? this.sides);
  }

  Map<String, dynamic> toJson() {
    return {
      'sides': sides.map((side) => side.toJson()).toList(growable: false),
    };
  }

  factory PlanViewData.fromJson(Map<String, dynamic> json) {
    final rawSides = json['sides'];
    final sideList = rawSides is List
        ? rawSides
              .whereType<Map>()
              .map(
                (side) =>
                    PlanSide.fromJson(Map<String, dynamic>.from(side)),
              )
              .toList(growable: false)
        : <PlanSide>[];

    return PlanViewData(sides: sideList);
  }
}
