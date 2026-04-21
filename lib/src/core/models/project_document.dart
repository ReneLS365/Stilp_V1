import 'facade_document.dart';
import 'manual_packing_list_item.dart';
import 'plan_view_data.dart';

class ProjectDocument {
  const ProjectDocument({
    required this.projectId,
    required this.taskType,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.planView,
    required this.facades,
    required this.manualPackingList,
  });

  final String projectId;
  final String taskType;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PlanViewData planView;
  final List<FacadeDocument> facades;
  final List<ManualPackingListItem> manualPackingList;

  factory ProjectDocument.empty({
    required String projectId,
    required String taskType,
    String notes = '',
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();

    return ProjectDocument(
      projectId: projectId,
      taskType: taskType,
      notes: notes,
      createdAt: timestamp,
      updatedAt: timestamp,
      planView: PlanViewData.empty(),
      facades: const [],
      manualPackingList: const [],
    );
  }

  ProjectDocument copyWith({
    String? projectId,
    String? taskType,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    PlanViewData? planView,
    List<FacadeDocument>? facades,
    List<ManualPackingListItem>? manualPackingList,
  }) {
    return ProjectDocument(
      projectId: projectId ?? this.projectId,
      taskType: taskType ?? this.taskType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      planView: planView ?? this.planView,
      facades: facades ?? this.facades,
      manualPackingList: manualPackingList ?? this.manualPackingList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'taskType': taskType,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'planView': planView.toJson(),
      'facades': facades.map((facade) => facade.toJson()).toList(growable: false),
      'manualPackingList':
          manualPackingList.map((item) => item.toJson()).toList(growable: false),
    };
  }

  factory ProjectDocument.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'] as String?;
    final rawUpdatedAt = json['updatedAt'] as String?;

    List<T> readList<T>(
      Object? source,
      T Function(Map<String, dynamic> value) parse,
    ) {
      if (source is! List) return <T>[];
      return source
          .whereType<Map>()
          .map((value) => parse(Map<String, dynamic>.from(value)))
          .toList(growable: false);
    }

    final fallbackDate = DateTime.fromMillisecondsSinceEpoch(0);

    return ProjectDocument(
      projectId: (json['projectId'] as String?) ?? '',
      taskType: (json['taskType'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      createdAt: DateTime.tryParse(rawCreatedAt ?? '') ?? fallbackDate,
      updatedAt: DateTime.tryParse(rawUpdatedAt ?? '') ?? fallbackDate,
      planView: PlanViewData.fromJson(
        Map<String, dynamic>.from((json['planView'] as Map?) ?? const {}),
      ),
      facades: readList(json['facades'], FacadeDocument.fromJson),
      manualPackingList: readList(
        json['manualPackingList'],
        ManualPackingListItem.fromJson,
      ),
    );
  }
}
