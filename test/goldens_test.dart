import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrencoder/main.dart';

Future<void> _loadFonts() async {
  Future<void> add(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File(f).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await add('Silkscreen', [
    'assets/fonts/Silkscreen-Regular.ttf',
    'assets/fonts/Silkscreen-Bold.ttf',
  ]);
  await add('Barlow', [
    'assets/fonts/Barlow-Regular.ttf',
    'assets/fonts/Barlow-Medium.ttf',
    'assets/fonts/Barlow-SemiBold.ttf',
    'assets/fonts/Barlow-Bold.ttf',
  ]);
  await add('CourierPrime', [
    'assets/fonts/CourierPrime-Regular.ttf',
    'assets/fonts/CourierPrime-Bold.ttf',
  ]);
}

const wifi = 'WIFI:T:WPA2;S:Cafe-Werkstatt-5G;P:mulligan-18-river;H:false;;';

void main() {
  setUpAll(_loadFonts);


  Future<void> shoot(
    WidgetTester tester,
    String payload,
    String file, {
    Size physical = const Size(1440, 900),
    double dpr = 1.0,
    Brightness brightness = Brightness.light,
    String? tap,
    List<String>? taps,
    String? fill,
    TargetPlatform platform = TargetPlatform.macOS,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    tester.view.physicalSize = physical;
    tester.view.devicePixelRatio = dpr;
    tester.binding.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.view.reset);
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );

    await tester.pumpWidget(QrEncoderApp(initialPayload: payload));
    await tester.pump(const Duration(milliseconds: 300));

    if (tap != null) {
      await tester.tap(find.text(tap));
      await tester.pumpAndSettle();
    }
    for (final label in taps ?? const <String>[]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    if (fill != null) {
      await tester.enterText(find.byType(TextField).first, fill);
      await tester.pumpAndSettle();
    }

    await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
    debugDefaultTargetPlatformOverride = null;
  }

  testWidgets('desktop — wifi payload', (tester) async {
    await shoot(tester, wifi, 'goldens/desktop.png');
  });

  testWidgets('desktop — dark', (tester) async {
    await shoot(
      tester,
      wifi,
      'goldens/desktop-dark.png',
      brightness: Brightness.dark,
    );
  });

  testWidgets('desktop — liquid', (tester) async {
    await shoot(tester, wifi, 'goldens/desktop-liquid.png', tap: 'LIQUID');
  });

  testWidgets('desktop — standard', (tester) async {
    await shoot(tester, wifi, 'goldens/desktop-standard.png', tap: 'STANDARD');
  });

  testWidgets('desktop — wi-fi template', (tester) async {
    await shoot(
      tester,
      '',
      'goldens/desktop-wifi.png',
      taps: const ['CHANGE', 'WI-FI'],
    );
  });

  testWidgets('desktop — wi-fi filled', (tester) async {
    await shoot(
      tester,
      '',
      'goldens/desktop-wifi-filled.png',
      taps: const ['CHANGE', 'WI-FI'],
      fill: 'Cafe-Werkstatt-5G',
    );
  });

  testWidgets('desktop — template picker', (tester) async {
    await shoot(tester, '', 'goldens/picker.png', taps: const ['CHANGE']);
  });

  testWidgets('empty state', (tester) async {
    await shoot(tester, '', 'goldens/empty.png');
  });

  testWidgets('phone — wifi payload', (tester) async {
    await shoot(
      tester,
      wifi,
      'goldens/phone.png',
      physical: const Size(780, 1688),
      dpr: 2,
      platform: TargetPlatform.android,
    );
  });

  testWidgets('phone — wi-fi template', (tester) async {
    await shoot(
      tester,
      '',
      'goldens/phone-wifi.png',
      physical: const Size(780, 1688),
      dpr: 2,
      platform: TargetPlatform.android,
      taps: const ['CHANGE', 'WI-FI'],
      fill: 'Cafe-Werkstatt-5G',
    );
  });

  testWidgets('phone — dark', (tester) async {
    await shoot(
      tester,
      wifi,
      'goldens/phone-dark.png',
      physical: const Size(780, 1688),
      dpr: 2,
      brightness: Brightness.dark,
      platform: TargetPlatform.android,
    );
  });

  testWidgets('phone — empty state', (tester) async {
    await shoot(
      tester,
      '',
      'goldens/phone-empty.png',
      physical: const Size(780, 1688),
      dpr: 2,
      platform: TargetPlatform.android,
    );
  });
}
