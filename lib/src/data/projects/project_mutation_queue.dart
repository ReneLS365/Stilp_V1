class ProjectMutationQueue {
  final Map<String, Future<void>> _pendingByProject = {};

  Future<T> enqueue<T>(
    String projectId,
    Future<T> Function() action,
  ) {
    final previous = _pendingByProject[projectId] ?? Future<void>.value();
    final operation = previous.then((_) => action());
    final queuedOperation = operation.then<void>((_) {}, onError: (_, __) {});
    _pendingByProject[projectId] = queuedOperation;
    return operation.whenComplete(() {
      if (identical(_pendingByProject[projectId], queuedOperation)) {
        _pendingByProject.remove(projectId);
      }
    });
  }
}
