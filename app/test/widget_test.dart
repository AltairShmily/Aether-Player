import 'package:flutter_test/flutter_test.dart';
import 'package:aether/app.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const AetherApp());
    expect(find.text('Aether'), findsOneWidget);
  });
}
