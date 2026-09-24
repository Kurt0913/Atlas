import 'dart:ui';
import 'package:flutter/material.dart';

/// A system-wide subtle ledger paper backdrop that draws a restrained,
/// barely-there dot grid across the page background.
///
/// Keeps screens from reading as flat digital voids when content is sparse,
/// evoking tactile stationery and accountant ledgers without competing with cards.
class LedgerBackground extends StatelessWidget {
  final Widget child;

  const LedgerBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomPaint(
      painter: _LedgerDotGridPainter(
        dotColor: isDark
            ? const Color(0xFFEDF5F0).withValues(alpha: 0.03)
            : const Color(0xFF0F1914).withValues(alpha: 0.038),
        spacing: 22.0,
        dotRadius: 0.8,
      ),
      child: child,
    );
  }
}

class _LedgerDotGridPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double dotRadius;

  static Size? _lastSize;
  static double? _lastSpacing;
  static List<Offset> _cachedPoints = const [];

  _LedgerDotGridPainter({
    required this.dotColor,
    required this.spacing,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (_lastSize != size || _lastSpacing != spacing) {
      _lastSize = size;
      _lastSpacing = spacing;
      final pts = <Offset>[];
      for (double x = spacing; x < size.width; x += spacing) {
        for (double y = spacing; y < size.height; y += spacing) {
          pts.add(Offset(x, y));
        }
      }
      _cachedPoints = pts;
    }

    if (_cachedPoints.isNotEmpty) {
      final paint = Paint()
        ..color = dotColor
        ..strokeWidth = dotRadius * 2
        ..strokeCap = StrokeCap.round;
      canvas.drawPoints(PointMode.points, _cachedPoints, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LedgerDotGridPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.dotRadius != dotRadius;
  }
}
