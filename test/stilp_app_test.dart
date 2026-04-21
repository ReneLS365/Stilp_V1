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

  testWidgets('can create a local project and open workspace', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StilpApp()));

    await tester.tap(find.text('Ny'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Facadestillads');
    await tester.enterText(find.byType(TextField).last, 'Klar til opstart');

    await tester.tap(find.widgetWithText(FilledButton, 'Opret projekt'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Planvisning')), findsOneWidget);

    await tester.tap(find.text('Projekter'));
    await tester.pumpAndSettle();

    expect(find.text('Facadestillads'), findsOneWidget);

    await tester.tap(find.text('Facadestillads'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Planvisning')), findsOneWidget);
  });
}
