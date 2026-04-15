import 'package:flutter/material.dart';

import '../../app/placeholder_screen.dart';

class ProjectsListScreen extends StatelessWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Projektliste',
      subtitle: 'Lokale projekter, opret, åbn, slet eller duplikér.',
    );
  }
}
