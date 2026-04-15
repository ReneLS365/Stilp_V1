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
}
