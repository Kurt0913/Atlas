import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../utils/date_helpers.dart';

/// A slim banner that shows the most urgent task: due date label + task name + client name.
class NextDeadlineStrip extends StatelessWidget {
  const NextDeadlineStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final active = [
      ...taskProvider.overdueTasks,
      ...taskProvider.dueTodayTasks,
      ...taskProvider.upcomingTasks,
    ];

    if (active.isEmpty) return const SizedBox.shrink();

    active.sort((a, b) =>
        DateHelpers.parseDateOnly(a.dueDate)
            .compareTo(DateHelpers.parseDateOnly(b.dueDate)));

    final next = active.first;
    final dueDate = DateHelpers.parseDateOnly(next.dueDate);
    final today = DateHelpers.startOfDay(DateTime.now());
    final diff = DateHelpers.startOfDay(dueDate).difference(today).inDays;

    String dueLabel;
    Color labelColor;
    if (diff < 0) {
      dueLabel = '${diff.abs()}d overdue';
      labelColor = const Color(0xFFDC2626);
    } else if (diff == 0) {
      dueLabel = 'Due today';
      labelColor = const Color(0xFF059669);
    } else {
      dueLabel = 'In $diff day${diff == 1 ? '' : 's'}';
      labelColor = isDark ? const Color(0xFF34D399) : const Color(0xFF143D2B);
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141F18) : const Color(0xFFF0F5F2),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF263B2F) : const Color(0xFFDDE6E0),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              diff < 0
                  ? Icons.warning_amber_rounded
                  : diff == 0
                      ? Icons.today_rounded
                      : Icons.schedule_rounded,
              size: 14,
              color: labelColor,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF8EA397)
                        : const Color(0xFF5A6E64),
                  ),
                  children: [
                    TextSpan(
                      text: dueLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                    const TextSpan(text: '  '),
                    TextSpan(
                      text: next.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFEDF5F0)
                            : const Color(0xFF0F1914),
                      ),
                    ),
                    TextSpan(
                      text: '  ·  ${next.clientName}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
