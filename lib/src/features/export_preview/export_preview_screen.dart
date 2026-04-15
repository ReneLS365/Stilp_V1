import 'package:flutter/material.dart';

import '../../app/placeholder_screen.dart';

class ExportPreviewScreen extends StatelessWidget {
  const ExportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Eksport-preview',
      subtitle: 'Preview af plan, facader, noter og manuel pakkeliste før eksport.',
    );
  }
}
