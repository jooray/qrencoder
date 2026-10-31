import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

import 'qr_preview.dart';

class ExportActions extends StatelessWidget {
  final String payload;
  final int errorCorrectionLevel;
  final Color fgColor;
  final Color bgColor;
  final double moduleScale;

  const ExportActions({
    super.key,
    required this.payload,
    required this.errorCorrectionLevel,
    required this.fgColor,
    required this.bgColor,
    required this.moduleScale,
  });

  @override
  Widget build(BuildContext context) {
    if (payload.trim().isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildButton(
          context,
          icon: Icons.content_paste_rounded,
          label: 'Copy image',
          onTap: () => _copyToClipboard(context),
        ),
        const SizedBox(width: 8),
        _buildButton(
          context,
          icon: Icons.save_alt_rounded,
          label: 'Save as PNG',
          onTap: () => _saveAsPng(context),
        ),
        const SizedBox(width: 8),
        _buildButton(
          context,
          icon: Icons.ios_share_rounded,
          label: 'Share',
          onTap: () => _share(context),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required VoidCallback onTap,
    required String label,
    required IconData icon,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 22),
          tooltip: label,
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    try {
      final image = await renderQrToImage(
        payload: payload,
        errorCorrectionLevel: errorCorrectionLevel,
        fgColor: fgColor,
        bgColor: bgColor,
        moduleScale: moduleScale,
      );

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Write the raw PNG image bytes (not text) to the system clipboard so
      // pasting yields an actual image in editors, chat apps, etc.
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        throw UnsupportedError('System clipboard not available on this platform');
      }
      final item = DataWriterItem(suggestedName: 'qrcode.png');
      item.add(Formats.png(pngBytes));
      await clipboard.write([item]);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code image copied to clipboard')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copy to clipboard failed: $e')),
        );
      }
    }
  }

  Future<void> _saveAsPng(BuildContext context) async {
    try {
      final image = await renderQrToImage(
        payload: payload,
        errorCorrectionLevel: errorCorrectionLevel,
        fgColor: fgColor,
        bgColor: bgColor,
        moduleScale: moduleScale,
      );

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Use file_picker to show a native "Save As" dialog
      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Save QR Code as PNG',
        fileName: 'qrcode.png',
        bytes: pngBytes,
      );

      if (context.mounted) {
        if (savedUri != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PNG saved to ${savedUri.toString()}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Save cancelled')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _share(BuildContext context) async {
    try {
      final image = await renderQrToImage(
        payload: payload,
        errorCorrectionLevel: errorCorrectionLevel,
        fgColor: fgColor,
        bgColor: bgColor,
        moduleScale: moduleScale,
      );

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final file = await File('${directory.path}/qrcode.png').writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'QR Code',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }
}