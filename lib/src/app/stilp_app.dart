import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/export_preview/export_preview_screen.dart';
import '../features/facade_editor/facade_editor_screen.dart';
import '../features/manual_packing_list/manual_packing_list_screen.dart';
import '../features/new_project/new_project_screen.dart';
import '../features/plan_view/plan_view_screen.dart';
import '../features/projects/projects_list_screen.dart';
import 'state/app_shell_controller.dart';
import 'state/app_shell_state.dart';

class StilpApp extends StatelessWidget {
  const StilpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stilp v1',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const StilpShell(),
    );
  }
}

class StilpShell extends ConsumerWidget {
  const StilpShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shellState = ref.watch(appShellControllerProvider);
    final controller = ref.read(appShellControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle(shellState))),
      body: _screenBody(shellState),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shellState.flow.index,
        onDestinationSelected: (index) {
          switch (AppFlow.values[index]) {
            case AppFlow.projects:
              controller.showProjects();
            case AppFlow.newProject:
              controller.showNewProject();
            case AppFlow.workspace:
              controller.showWorkspace();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_open_outlined),
            selectedIcon: Icon(Icons.folder_open),
            label: 'Projekter',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_add_outlined),
            selectedIcon: Icon(Icons.note_add),
            label: 'Ny',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspaces_outline),
            selectedIcon: Icon(Icons.workspaces),
            label: 'Workspace',
          ),
        ],
      ),
    );
  }

  Widget _screenBody(AppShellState state) {
    switch (state.flow) {
      case AppFlow.projects:
        return const ProjectsListScreen();
      case AppFlow.newProject:
        return const NewProjectScreen();
      case AppFlow.workspace:
        return ProjectWorkspaceScreen(state: state);
    }
  }

  String _screenTitle(AppShellState state) {
    switch (state.flow) {
      case AppFlow.projects:
        return 'Projektliste';
      case AppFlow.newProject:
        return 'Ny opgave';
      case AppFlow.workspace:
        return _workspaceTitle(state.workspaceScreen);
    }
  }

  String _workspaceTitle(WorkspaceScreen screen) {
    switch (screen) {
      case WorkspaceScreen.planView:
        return 'Planvisning';
      case WorkspaceScreen.facadeEditor:
        return 'Facadeeditor';
      case WorkspaceScreen.manualPackingList:
        return 'Manuel pakkeliste';
      case WorkspaceScreen.exportPreview:
        return 'Eksport-preview';
    }
  }
}

class ProjectWorkspaceScreen extends ConsumerWidget {
  const ProjectWorkspaceScreen({
    required this.state,
    super.key,
  });

  final AppShellState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appShellControllerProvider.notifier);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<WorkspaceScreen>(
            segments: const [
              ButtonSegment(
                value: WorkspaceScreen.planView,
                icon: Icon(Icons.home_work_outlined),
                label: Text('Plan'),
              ),
              ButtonSegment(
                value: WorkspaceScreen.facadeEditor,
                icon: Icon(Icons.grid_on_outlined),
                label: Text('Facade'),
              ),
              ButtonSegment(
                value: WorkspaceScreen.manualPackingList,
                icon: Icon(Icons.checklist_outlined),
                label: Text('Pakkeliste'),
              ),
              ButtonSegment(
                value: WorkspaceScreen.exportPreview,
                icon: Icon(Icons.picture_as_pdf_outlined),
                label: Text('Eksport'),
              ),
            ],
            selected: {state.workspaceScreen},
            onSelectionChanged: (selection) {
              controller.setWorkspaceScreen(selection.first);
            },
          ),
        ),
        if (state.activeProjectId == null)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Vælg et projekt i Projektliste for at aktivere projektkontekst.',
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(child: _workspaceBody(state.workspaceScreen)),
      ],
    );
  }

  Widget _workspaceBody(WorkspaceScreen screen) {
    switch (screen) {
      case WorkspaceScreen.planView:
        return const PlanViewScreen();
      case WorkspaceScreen.facadeEditor:
        return const FacadeEditorScreen();
      case WorkspaceScreen.manualPackingList:
        return const ManualPackingListScreen();
      case WorkspaceScreen.exportPreview:
        return const ExportPreviewScreen();
    }
  }
}
