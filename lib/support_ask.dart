import 'package:flutter/material.dart';

import 'src/support/support_controller.dart';
import 'src/support/support_copy.dart';
import 'src/support/support_engine.dart';
import 'src/support/support_strip.dart';

/// QREncoder's side of the support ask.
///
/// `lib/src/support/` is a synced copy of a shared module (see lib/src/support/README.md); this file is the
/// app's own: its numbers, its placement and its look. Change words or rules in the shared module, and only
/// the look or the numbers here.
///
/// The app never talks to a server for this, and the app has no network permission at all: tapping Support
/// hands a link to the user's browser, nothing more.
const qrEncoderSupport = SupportConfig(
  appId: 'qrencoder',
  // The placement: under the export controls, after a PNG was saved or an image copied.
  ref: 'after-export',
  // QREncoder is a quick tool: two days of use and five exports before the first ask.
  trigger: SupportTrigger(minDays: 2, minActions: 5),
);

/// The specimen voice: no card, no shadow, square corners, a hairline box, and the accent as a highlighter
/// (a 4 px cap) rather than a fill. Support is an outlined key, never lime-filled and never white on lime.
SupportStyle qrEncoderSupportStyle({
  required Color ground,
  required Color ink,
  required Color muted,
  required Color hair,
  required Color accent,
  required bool dark,
  required TextStyle body,
  required TextStyle label,
  required TextStyle small,
}) => SupportStyle(
  ground: ground,
  border: hair,
  ink: ink,
  mid: muted,
  faint: muted,
  // On the dark ground the accent is the focus ring, on the light one it would not show.
  focus: dark ? accent : ink,
  body: body,
  label: label,
  small: small,
  cap: accent,
);

/// The strip with the margins of the place it sits in.
class QrEncoderSupportStrip extends StatelessWidget {
  const QrEncoderSupportStrip({
    super.key,
    required this.controller,
    required this.style,
    required this.dark,
    required this.margin,
  });

  final SupportController controller;
  final SupportStyle style;
  final bool dark;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.visible) return const SizedBox.shrink();
        return Padding(
          padding: margin,
          child: SupportStrip(
            controller: controller,
            // QREncoder is English-only: English copy, and the checkout follows the browser's language.
            copy: SupportCopy.forLanguage('en', 'QREncoder'),
            style: style,
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
        );
      },
    );
  }
}
