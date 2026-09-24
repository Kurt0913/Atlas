import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// An editorial guidance card designed to look like a field note or ledger annotation.
///
/// Visually distinct from content data cards:
/// - Tinted paper background (warm parchment tone)
/// - Subtle dashed / rule border
/// - Editorial serif / italicized body typography
/// - Actionable CTA link that immediately triggers the relevant workflow.
class EditorialTipCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  const EditorialTipCard({
    super.key,
    this.eyebrow = 'Field Note',
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomPaint(
      painter: _DashedBorderPainter(
        color: isDark ? const Color(0xFF2E4637) : const Color(0xFFD6CEBF),
        strokeWidth: 1.2,
        dashLength: 5,
        gapLength: 4,
        borderRadius: 12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF132319) : const Color(0xFFF9F7F2),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Eyebrow Header: Icon + Category + Actionable Link ────────
            Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isDark ? AppTheme.brassAccentDark : AppTheme.brassAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark
                        ? AppTheme.brassAccentDark
                        : AppTheme.brassAccent,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.brassAccentDark
                                : AppTheme.brassAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Title ──────────────────────────────────────────────────
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFEDF5F0) : const Color(0xFF1B2E24),
              ),
            ),
            const SizedBox(height: 4),

            // ── Editorial Body (Serif / Italic guidance tone) ──────────
            Text(
              message,
              style: TextStyle(
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                fontSize: 12.5,
                height: 1.45,
                color: isDark
                    ? const Color(0xFFA5B8AD)
                    : const Color(0xFF53675C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
