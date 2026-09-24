import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';
import '../utils/date_helpers.dart';

class DeadlineBadge extends StatelessWidget {
  final String dueDate;
  final TaskDeadlineVariant variant;

  const DeadlineBadge({
    super.key,
    required this.dueDate,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color textColor;
    String label;

    final parsed = DateHelpers.parseDateOnly(dueDate);
    final formattedDate = DateFormat('MMM d').format(parsed);

    switch (variant) {
      case TaskDeadlineVariant.overdue:
        bg = isDark ? const Color(0xFF3B1214) : AppTheme.statusOverdueBg;
        textColor = isDark ? const Color(0xFFFCA5A5) : AppTheme.statusOverdueText;
        label = 'Overdue';
        break;
      case TaskDeadlineVariant.today:
        // Use Amber for today's deadline — distinct from brand green
        bg = isDark ? const Color(0xFF382305) : AppTheme.statusInProgressBg;
        textColor = isDark ? const Color(0xFFFCD34D) : AppTheme.statusInProgressText;
        label = 'Today';
        break;
      case TaskDeadlineVariant.upcoming:
        bg = isDark ? const Color(0xFF1E293B) : AppTheme.statusTodoBg;
        textColor = isDark ? const Color(0xFF94A3B8) : AppTheme.statusTodoText;
        label = 'Due $formattedDate';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        variant == TaskDeadlineVariant.upcoming ? label : '$label · $formattedDate',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
