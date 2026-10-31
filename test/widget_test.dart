import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrencoder/main.dart';

void main() {
  testWidgets('renders the editor and encodes live on input', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const QrEncoderApp());
    expect(find.text('QRENCODER'), findsOneWidget);
    expect(find.text('start typing'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();

    expect(find.text('start typing'), findsNothing);
    expect(find.text('MODULES'), findsOneWidget);
    expect(find.text('21 × 21'), findsOneWidget);
  });

  testWidgets('does nothing to save when there is no symbol', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const QrEncoderApp());
    await tester.tap(find.text('COPY IMAGE'));
    await tester.pump();
    expect(find.textContaining('COPIED'), findsNothing);
  });

  testWidgets('switching style keeps the payload', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const QrEncoderApp(initialPayload: 'hello'));
    await tester.pump();

    await tester.tap(find.text('LIQUID'));
    await tester.pump();

    expect(find.text('LIQUID'), findsOneWidget);
    expect(find.text('MODULES'), findsOneWidget);
  });
}
