import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPreviewWidget extends StatelessWidget {
  final String payload;
  final int errorCorrectionLevel;
  final Color fgColor;
  final Color bgColor;
  final VoidCallback? onTapFullscreen;

  const QrPreviewWidget({
    super.key,
    required this.payload,
    required this.errorCorrectionLevel,
    required this.fgColor,
    required this.bgColor,
    this.onTapFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    if (payload.trim().isEmpty) {
      return Center(
        child: Text(
          'Enter content to generate QR code',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
      );
    }

    try {
      final qrCode = QrCode.fromData(
        data: payload,
        errorCorrectLevel: errorCorrectionLevel,
      );

      return LayoutBuilder(
        builder: (context, constraints) {
          final maxSide = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;

          final displaySize = maxSide.clamp(120.0, 800.0);

          return Center(
            child: GestureDetector(
              onTap: onTapFullscreen,
              child: Tooltip(
                message: 'Tap for fullscreen scan view',
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: displaySize - 32,
                        height: displaySize - 32,
                        child: CustomPaint(
                          painter: _QrCanvasPainter(
                            qrCode: qrCode,
                            fgColor: fgColor,
                            bgColor: bgColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              'Payload too large for QR version / EC level',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      );
    }
  }
}

class _QrCanvasPainter extends CustomPainter {
  final QrCode qrCode;
  final Color fgColor;
  final Color bgColor;

  _QrCanvasPainter({
    required this.qrCode,
    required this.fgColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final moduleCount = qrCode.moduleCount;
    // Standard spec quiet zone: 4 modules on each side
    const quietZoneModules = 4.0;
    final totalModules = moduleCount + (2 * quietZoneModules);

    final modulePx = size.width / totalModules;
    final qrPx = moduleCount * modulePx;
    final offsetPx = quietZoneModules * modulePx;

    final painter = QrPainter.withQr(
      qr: qrCode,
      gapless: true,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: fgColor,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: fgColor,
      ),
    );

    canvas.save();
    canvas.translate(offsetPx, offsetPx);
    painter.paint(canvas, Size(qrPx, qrPx));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _QrCanvasPainter oldDelegate) {
    return oldDelegate.qrCode != qrCode ||
        oldDelegate.fgColor != fgColor ||
        oldDelegate.bgColor != bgColor;
  }
}

/// Helper function to generate PNG ByteData for copying to clipboard or saving to file
Future<ui.Image> renderQrToImage({
  required String payload,
  required int errorCorrectionLevel,
  required Color fgColor,
  required Color bgColor,
  required double moduleScale,
}) async {
  final qrCode = QrCode.fromData(
    data: payload,
    errorCorrectLevel: errorCorrectionLevel,
  );

  final moduleCount = qrCode.moduleCount;
  const quietZoneModules = 4.0;
  final totalModules = moduleCount + (2 * quietZoneModules);

  final totalSizePx = (totalModules * moduleScale).ceilToDouble();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final painter = _QrCanvasPainter(
    qrCode: qrCode,
    fgColor: fgColor,
    bgColor: bgColor,
  );

  painter.paint(canvas, Size(totalSizePx, totalSizePx));
  final picture = recorder.endRecording();

  return picture.toImage(totalSizePx.toInt(), totalSizePx.toInt());
}

/// Fullscreen scan dialog for display scanning
class FullscreenScanView extends StatelessWidget {
  final String payload;
  final int errorCorrectionLevel;
  final Color fgColor;
  final Color bgColor;

  const FullscreenScanView({
    super.key,
    required this.payload,
    required this.errorCorrectionLevel,
    required this.fgColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final qrCode = QrCode.fromData(
      data: payload,
      errorCorrectLevel: errorCorrectionLevel,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
        title: const Text(
          'Display Scan View',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxSide = constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth - 32
                    : constraints.maxHeight - 32;

                return Container(
                  width: maxSide,
                  height: maxSide,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CustomPaint(
                    painter: _QrCanvasPainter(
                      qrCode: qrCode,
                      fgColor: fgColor,
                      bgColor: bgColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
