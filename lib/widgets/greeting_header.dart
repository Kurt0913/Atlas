import 'package:flutter/material.dart';
import '../utils/date_helpers.dart';

class GreetingHeader extends StatelessWidget {
  final String userName;

  const GreetingHeader({super.key, this.userName = 'Kurt'});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final greeting = DateHelpers.getGreeting(now);
    final formattedDate = DateHelpers.formatFullDate(now);

    final initial = userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'A';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,\n$userName',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.5,
                    color: isDark ? const Color(0xFFEDF5F0) : const Color(0xFF0F1914),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF8EA397) : const Color(0xFF5A6E64),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // User avatar circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F1914),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

