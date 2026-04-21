class ProjectSummary {
  const ProjectSummary({
    required this.projectId,
    required this.taskType,
    required this.notes,
    required this.updatedAt,
  });

  final String projectId;
  final String taskType;
  final String notes;
  final DateTime updatedAt;

  ProjectSummary copyWith({
    String? projectId,
    String? taskType,
    String? notes,
    DateTime? updatedAt,
  }) {
    return ProjectSummary(
      projectId: projectId ?? this.projectId,
      taskType: taskType ?? this.taskType,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
