// QREncoder's own placement of the support ask (the shared module is tested by the synced *_test.dart files
// beside this one): a strip above the footer after an export, taken away again by the next edit, plus a
// permanent "Support the project" entry that works even after "don't ask again".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrencoder/main.dart';
import 'package:qrencoder/src/support/support_controller.dart';
import 'package:qrencoder/src/support/support_engine.dart';
import 'package:qrencoder/src/support/support_launch.dart';
import 'package:qrencoder/src/support/support_store.dart';
import 'package:qrencoder/support_ask.dart';

class FakeLauncher implements SupportLauncher {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

SupportController due(FakeLauncher launcher, {SupportState? from}) =>
    SupportController(
      config: qrEncoderSupport,
      store: MemorySupportStore(
        from ?? const SupportState(activeDays: 2, actions: 4),
      ),
      launcher: launcher,
    );

Future<void> pumpApp(
  WidgetTester tester,
  SupportController support, {
  Size size = const Size(1440, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    QrEncoderApp(initialPayload: 'hello', support: support),
  );
  await tester.pump();
}

const askText =
    'QREncoder is free and open source. Support it and get an e-book.';

void main() {
  testWidgets(
    'a due reader sees the ask after an export, with no price and no network word',
    (tester) async {
      final support = due(FakeLauncher());
      await pumpApp(tester, support);
      expect(find.text(askText), findsNothing);

      // The export that completes the fifth action: the app counts it and asks.
      await support.recordAction();
      expect(await support.evaluate(momentOfValue: true), isTrue);
      await tester.pump();

      expect(find.text(askText), findsOneWidget);
      expect(find.text('SUPPORT'), findsOneWidget);
      expect(find.text('NOT NOW'), findsOneWidget);
      expect(find.text("Don't ask again"), findsOneWidget);
      expect(find.textContaining('€'), findsNothing);
    },
  );

  testWidgets('the ask is gone as soon as the next payload is typed', (
    tester,
  ) async {
    final support = due(FakeLauncher());
    await pumpApp(tester, support);
    await support.recordAction();
    await support.evaluate(momentOfValue: true);
    await tester.pump();
    expect(find.text(askText), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hello again');
    await tester.pump();
    expect(find.text(askText), findsNothing);
    expect(support.state.asks, 1, reason: 'it was shown, so it stays counted');
  });

  testWidgets('Support opens the checkout with the export placement', (
    tester,
  ) async {
    final launcher = FakeLauncher();
    final support = due(launcher);
    await pumpApp(tester, support);
    await support.recordAction();
    await support.evaluate(momentOfValue: true);
    await tester.pump();
    await tester.tap(find.text('SUPPORT'));
    await tester.pump();
    await tester.pump();
    expect(
      launcher.opened.single.toString(),
      'https://hackyourself.io/support/s/qrencoder?theme=light&ref=after-export',
    );
    expect(find.text(askText), findsNothing);
  });

  testWidgets('a new reader sees no ask', (tester) async {
    final support = SupportController(
      config: qrEncoderSupport,
      store: MemorySupportStore(),
      launcher: FakeLauncher(),
    );
    await pumpApp(tester, support);
    await support.recordAction();
    expect(await support.evaluate(momentOfValue: true), isFalse);
    await tester.pump();
    expect(find.text(askText), findsNothing);
  });

  testWidgets(
    'the permanent entry opens the checkout and still works after "don\'t ask again"',
    (tester) async {
      final launcher = FakeLauncher();
      final support = due(launcher, from: const SupportState(declined: true));
      await pumpApp(tester, support);
      expect(find.text('SUPPORT THE PROJECT'), findsOneWidget);
      await tester.tap(find.text('SUPPORT THE PROJECT'));
      await tester.pump();
      expect(
        launcher.opened.single.toString(),
        'https://hackyourself.io/support/s/qrencoder?theme=light&ref=menu',
      );
      expect(support.state.declined, isTrue);
    },
  );

  testWidgets('on a phone the entry sits under the measurements', (
    tester,
  ) async {
    final support = due(
      FakeLauncher(),
      from: const SupportState(declined: true),
    );
    await pumpApp(tester, support, size: const Size(430, 900));
    await tester.scrollUntilVisible(
      find.text('SUPPORT THE PROJECT'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('SUPPORT THE PROJECT'), findsOneWidget);
  });
}
