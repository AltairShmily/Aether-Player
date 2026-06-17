import 'package:flutter_test/flutter_test.dart';
import 'package:aether/app.dart';
import 'package:aether/i18n/strings.g.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(TranslationProvider(
      child: const AetherApp(backendReady: false),
    ));
    expect(find.text('后端服务启动失败'), findsOneWidget);
  });
}
