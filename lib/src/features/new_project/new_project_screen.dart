import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state/app_shell_controller.dart';
import '../../data/projects/local_project_store.dart';
import '../project_session/state/project_session_controller.dart';

class NewProjectScreen extends ConsumerStatefulWidget {
  const NewProjectScreen({super.key});

  @override
  ConsumerState<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends ConsumerState<NewProjectScreen> {
  final _taskTypeController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _taskTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    final taskType = _taskTypeController.text.trim();
    final notes = _notesController.text.trim();

    if (taskType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opgavetype må ikke være tom.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      final projectId = 'project-${now.microsecondsSinceEpoch}';
      final store = ref.read(localProjectStoreProvider);

      await store.saveProject(
        ProjectDocument(
          projectId: projectId,
          taskType: taskType,
          notes: notes,
          updatedAt: now,
        ),
      );

      ref.invalidate(projectsProvider);
      ref.read(projectSessionControllerProvider.notifier).openProject(projectId);
      ref.read(appShellControllerProvider.notifier).showWorkspace();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _taskTypeController,
          textInputAction: TextInputAction.next,
          enabled: !_isSaving,
          decoration: const InputDecoration(
            labelText: 'Opgavetype',
            hintText: 'Fx Facadestillads',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          enabled: !_isSaving,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Noter',
            hintText: 'Skriv korte noter til opgaven',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isSaving ? null : _createProject,
          icon: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: Text(_isSaving ? 'Opretter...' : 'Opret projekt'),
        ),
      ],
    );
  }
}
