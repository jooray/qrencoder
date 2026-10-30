import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qrencoder/main.dart';

void main() {
  testWidgets('QREncoder renders with empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const QrEncoderApp());

    // App title should be present
    expect(find.text('QREncoder'), findsOneWidget);

    // Content label present
    expect(find.text('Content:'), findsOneWidget);

    // Empty-state message shown in preview
    expect(
      find.text('Enter content to generate QR code'),
      findsOneWidget,
    );
  });
}