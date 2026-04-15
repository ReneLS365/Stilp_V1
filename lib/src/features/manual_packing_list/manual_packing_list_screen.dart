import 'package:flutter/material.dart';

import '../../app/placeholder_screen.dart';

class ManualPackingListScreen extends StatelessWidget {
  const ManualPackingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Manuel pakkeliste',
      subtitle: 'Tilføj, redigér og slet manuelle pakkelinjer.',
    );
  }
}
