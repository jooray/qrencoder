import 'dart:math';
import 'package:flutter/material.dart';

class ColorPickerUtils {
  static double calculateLuminance(Color color) {
    double r = (color.r * 255).clamp(0, 255) / 255.0;
    double g = (color.g * 255).clamp(0, 255) / 255.0;
    double b = (color.b * 255).clamp(0, 255) / 255.0;

    r = (r <= 0.03928) ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4).toDouble();
    g = (g <= 0.03928) ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4).toDouble();
    b = (b <= 0.03928) ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double contrastRatio(Color c1, Color c2) {
    final l1 = calculateLuminance(c1);
    final l2 = calculateLuminance(c2);
    final maxL = max(l1, l2);
    final minL = min(l1, l2);
    return (maxL + 0.05) / (minL + 0.05);
  }
}

class ColorPickersWidget extends StatelessWidget {
  final Color fgColor;
  final Color bgColor;
  final ValueChanged<Color> onFgChanged;
  final ValueChanged<Color> onBgChanged;

  const ColorPickersWidget({
    super.key,
    required this.fgColor,
    required this.bgColor,
    required this.onFgChanged,
    required this.onBgChanged,
  });

  static const List<Color> presetColors = [
    Colors.black,
    Colors.white,
    Color(0xFF1E293B), // Dark slate
    Color(0xFF0F172A), // Deep navy
    Color(0xFFB91C1C), // Deep red
    Color(0xFF15803D), // Forest green
    Color(0xFF1D4ED8), // Royal blue
    Color(0xFF6D28D9), // Purple
    Color(0xFFD97706), // Amber
  ];

  @override
  Widget build(BuildContext context) {
    final ratio = ColorPickerUtils.contrastRatio(fgColor, bgColor);
    final lowContrast = ratio < 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _ColorChipButton(
                label: 'Barcode',
                color: fgColor,
                onTap: () => _showColorPicker(context, 'Barcode Color', fgColor, onFgChanged),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ColorChipButton(
                label: 'Background',
                color: bgColor,
                onTap: () => _showColorPicker(context, 'Background Color', bgColor, onBgChanged),
              ),
            ),
          ],
        ),
        if (lowContrast) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade700),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Low contrast ratio (${ratio.toStringAsFixed(1)}:1). Scanners may fail.',
                    style: TextStyle(color: Colors.amber.shade900, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showColorPicker(
    BuildContext context,
    String title,
    Color currentColor,
    ValueChanged<Color> onSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 280,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: presetColors.map((c) {
              final isSelected = c.toARGB32() == currentColor.toARGB32();
              return InkWell(
                onTap: () {
                  onSelected(c);
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: ColorPickerUtils.calculateLuminance(c) > 0.5 ? Colors.black : Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ColorChipButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ColorChipButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
