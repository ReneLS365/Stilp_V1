import 'package:flutter/material.dart';

import '../core/storage/local_project_store.dart';
import '../features/export_preview/export_preview_screen.dart';
import '../features/facade_editor/facade_editor_screen.dart';
import '../features/manual_packing_list/manual_packing_list_screen.dart';
import '../features/new_project/new_project_screen.dart';
import '../features/plan_view/plan_view_screen.dart';
import '../features/projects/projects_list_screen.dart';
import 'app_screen.dart';

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
      home: StilpShell(projectStore: InMemoryProjectStore()),
    );
  }
}

class StilpShell extends StatefulWidget {
  const StilpShell({
    super.key,
    required this.projectStore,
  });

  final LocalProjectStore projectStore;

  @override
  State<StilpShell> createState() => _StilpShellState();
}

class _StilpShellState extends State<StilpShell> {
  AppScreen _currentScreen = AppScreen.projects;

  void _onDestinationSelected(int index) {
    setState(() {
      _currentScreen = AppScreen.values[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle(_currentScreen)),
      ),
      body: _screenBody(_currentScreen),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentScreen.index,
        onDestinationSelected: _onDestinationSelected,
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
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_on_outlined),
            selectedIcon: Icon(Icons.grid_on),
            label: 'Facade',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Pakkeliste',
          ),
          NavigationDestination(
            icon: Icon(Icons.picture_as_pdf_outlined),
            selectedIcon: Icon(Icons.picture_as_pdf),
            label: 'Eksport',
          ),
        ],
      ),
    );
  }

  Widget _screenBody(AppScreen screen) {
    switch (screen) {
      case AppScreen.projects:
        return const ProjectsListScreen();
      case AppScreen.newProject:
        return const NewProjectScreen();
      case AppScreen.planView:
        return const PlanViewScreen();
      case AppScreen.facadeEditor:
        return const FacadeEditorScreen();
      case AppScreen.manualPackingList:
        return const ManualPackingListScreen();
      case AppScreen.exportPreview:
        return const ExportPreviewScreen();
    }
  }

  String _screenTitle(AppScreen screen) {
    switch (screen) {
      case AppScreen.projects:
        return 'Projektliste';
      case AppScreen.newProject:
        return 'Ny opgave';
      case AppScreen.planView:
        return 'Planvisning';
      case AppScreen.facadeEditor:
        return 'Facadeeditor';
      case AppScreen.manualPackingList:
        return 'Manuel pakkeliste';
      case AppScreen.exportPreview:
        return 'Eksport-preview';
    }
  }
}
