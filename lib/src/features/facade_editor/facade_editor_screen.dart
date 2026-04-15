import 'package:flutter/material.dart';

import '../../app/placeholder_screen.dart';

class FacadeEditorScreen extends StatelessWidget {
  const FacadeEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Facadeeditor',
      subtitle: 'Generér grid, justér sektioner/etager og placer visuelle markører.',
    );
  }
}
