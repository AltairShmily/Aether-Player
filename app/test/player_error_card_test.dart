import 'package:aether/widgets/player_error_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 播放页强制横屏，错误卡片必须在最矮的横屏视口里也放得下。
///
/// 这几个测试存在的意义：卡片高度由图标 + 标题 + 最多 3 行文案 + 三个按钮叠出来，
/// 一旦超过视口就是 RenderFlex 溢出（黄黑条 + 抛异常），而 analyze 查不出来。
void main() {
  /// 在指定视口尺寸下挂载卡片
  Future<void> pumpCard(
    WidgetTester tester, {
    required Size size,
    String message = '连接服务器失败',
    VoidCallback? onRetry,
    VoidCallback? onSwitchQuality,
    VoidCallback? onBack,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // StackFit.expand：默认的 loose 只按「非定位子组件」定尺寸，
          // 而这里非定位子组件是个没有 child 的 ColoredBox（0×0），
          // 整个 Stack 会塌成 0×0，把 Positioned.fill 里的卡片一起压扁，
          // 于是所有溢出断言都在零尺寸上空过
          body: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.black),
              Positioned.fill(
                child: PlayerErrorCard(
                  message: message,
                  onRetry: onRetry,
                  onSwitchQuality: onSwitchQuality,
                  onBack: onBack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // 不能用 pumpAndSettle：AetherButton.primary 在可点击时有一个永久 repeat
    // 的发光脉冲动画，等不到静止。入场/按压动画是 200-350ms，给 400ms 即可
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('PlayerErrorCard 横屏适配', () {
    testWidgets('iPhone SE 横屏（568×320）长文案不溢出', (tester) async {
      await pumpCard(
        tester,
        size: const Size(568, 320),
        message: 'SocketException: OS Error: Connection refused, '
            'errno = 111, address = 192.168.1.20, port = 8096，'
            '请确认 aether-server 已启动并且 Emby 地址可达',
      );

      // 溢出会以 FlutterError 形式抛出，布局正常时为 null
      expect(tester.takeException(), isNull);
      expect(find.text('播放失败'), findsOneWidget);
    });

    testWidgets('常见手机横屏（640×360）不溢出', (tester) async {
      await pumpCard(tester, size: const Size(640, 360));
      expect(tester.takeException(), isNull);
    });

    testWidgets('桌面窗口（1280×720）不溢出且卡片不被拉宽', (tester) async {
      await pumpCard(tester, size: const Size(1280, 720));
      expect(tester.takeException(), isNull);

      // 宽屏下卡片应停在 maxWidth 380，而不是横向铺满整个播放器
      final cardSize = tester.getSize(find.byType(SingleChildScrollView));
      expect(cardSize.width, lessThanOrEqualTo(380));
    });
  });

  group('PlayerErrorCard 动作', () {
    testWidgets('重试 / 切换画质 / 返回三个动作都在且可点', (tester) async {
      var retried = 0;
      var switched = 0;
      var backed = 0;

      await pumpCard(
        tester,
        size: const Size(844, 390),
        onRetry: () => retried++,
        onSwitchQuality: () => switched++,
        onBack: () => backed++,
      );

      await tester.tap(find.text('重试'));
      await tester.tap(find.text('切换画质'));
      await tester.tap(find.text('返回'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(retried, 1);
      expect(switched, 1);
      expect(backed, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('未提供的动作回调不会让按钮抛异常', (tester) async {
      await pumpCard(tester, size: const Size(844, 390));
      await tester.tap(find.text('重试'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });

    testWidgets('错误文案原样展示，超长时截断而非撑破卡片', (tester) async {
      final long = List.filled(400, 'a').join();
      await pumpCard(tester, size: const Size(640, 360), message: long);

      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text(long));
      expect(text.maxLines, 3);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });
}
