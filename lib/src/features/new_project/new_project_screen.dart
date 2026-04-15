import 'package:flutter/material.dart';

import '../../app/placeholder_screen.dart';

class NewProjectScreen extends StatelessWidget {
  const NewProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Ny opgave',
      subtitle: 'Vælg opgavetype og noter. Start med eller uden planvisning.',
    );
  }
}
