import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/app/stilp_app.dart';

void main() {
  testWidgets('renders shell title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StilpApp()));

    final appBarTitleFinder = find.descendant(
      of: find.byType(AppBar),
      matching: find.text('Projektliste'),
    );

    expect(appBarTitleFinder, findsOneWidget);
  });
}
