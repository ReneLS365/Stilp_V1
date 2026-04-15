import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/app/stilp_app.dart';

void main() {
  testWidgets('renders shell title', (tester) async {
    await tester.pumpWidget(const StilpApp());

    expect(find.text('Projektliste'), findsOneWidget);
  });
}
