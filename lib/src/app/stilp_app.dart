import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/export_preview/export_preview_screen.dart';
import '../features/facade_editor/facade_editor_screen.dart';
import '../features/manual_packing_list/manual_packing_list_screen.dart';
import '../features/new_project/new_project_screen.dart';
import '../features/plan_view/plan_view_screen.dart';
import '../features/project_session/state/project_session_controller.dart';
import '../features/project_session/state/project_session_state.dart';
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
    final projectSession = ref.watch(projectSessionControllerProvider);
    final controller = ref.read(appShellControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle(shellState, projectSession))),
      body: _screenBody(shellState),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shellState.flow.index,
        onDestinationSelected: (index) {
          switch (AppFlow.values[index]) {
            case AppFlow.projects:
              controller.showProjects();
              break;
            case AppFlow.newProject:
              controller.showNewProject();
              break;
            case AppFlow.workspace:
              controller.showWorkspace();
              break;
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
        return const ProjectWorkspaceScreen();
    }
  }

  String _screenTitle(
    AppShellState state,
    ProjectSessionState? projectSession,
  ) {
    switch (state.flow) {
      case AppFlow.projects:
        return 'Projektliste';
      case AppFlow.newProject:
        return 'Ny opgave';
      case AppFlow.workspace:
        if (projectSession == null) {
          return 'Workspace';
        }
        return _workspaceTitle(projectSession.activeTab);
    }
  }

  String _workspaceTitle(ProjectWorkspaceTab tab) {
    switch (tab) {
      case ProjectWorkspaceTab.plan:
        return 'Planvisning';
      case ProjectWorkspaceTab.facade:
        return 'Facadeeditor';
      case ProjectWorkspaceTab.packing:
        return 'Manuel pakkeliste';
      case ProjectWorkspaceTab.exportPreview:
        return 'Eksport-preview';
    }
  }
}

class ProjectWorkspaceScreen extends ConsumerWidget {
  const ProjectWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionControllerProvider);
    final sessionController = ref.read(projectSessionControllerProvider.notifier);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<ProjectWorkspaceTab>(
            segments: const [
              ButtonSegment(
                value: ProjectWorkspaceTab.plan,
                icon: Icon(Icons.home_work_outlined),
                label: Text('Plan'),
              ),
              ButtonSegment(
                value: ProjectWorkspaceTab.facade,
                icon: Icon(Icons.grid_on_outlined),
                label: Text('Facade'),
              ),
              ButtonSegment(
                value: ProjectWorkspaceTab.packing,
                icon: Icon(Icons.checklist_outlined),
                label: Text('Pakkeliste'),
              ),
              ButtonSegment(
                value: ProjectWorkspaceTab.exportPreview,
                icon: Icon(Icons.picture_as_pdf_outlined),
                label: Text('Eksport'),
              ),
            ],
            selected: {session?.activeTab ?? ProjectWorkspaceTab.plan},
            onSelectionChanged: (selection) {
              sessionController.setTab(selection.first);
            },
          ),
        ),
        if (session == null)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ingen aktiv projektsession. Åbn et projekt fra projektlisten for at starte workspace.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: _workspaceBody(session.activeTab),
          ),
      ],
    );
  }

  Widget _workspaceBody(ProjectWorkspaceTab tab) {
    switch (tab) {
      case ProjectWorkspaceTab.plan:
        return const PlanViewScreen();
      case ProjectWorkspaceTab.facade:
        return const FacadeEditorScreen();
      case ProjectWorkspaceTab.packing:
        return const ManualPackingListScreen();
      case ProjectWorkspaceTab.exportPreview:
        return const ExportPreviewScreen();
    }
  }
}
