import 'package:flutter/material.dart';

import '../../app/placeholder_screen.dart';

class PlanViewScreen extends StatelessWidget {
  const PlanViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Planvisning',
      subtitle: 'Tegn bygningens form, ret sider og generér facader.',
    );
  }
}
