import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/client_provider.dart';
import '../providers/task_provider.dart';
import '../utils/date_helpers.dart';

class GreetingHeader extends StatelessWidget {
  final String userName;

  const GreetingHeader({super.key, this.userName = 'Kurt'});

  String _buildBriefingText(
    TaskProvider taskProvider,
    ClientProvider clientProvider,
  ) {
    final overdue = taskProvider.overdueTasks.length;
    final dueToday = taskProvider.dueTodayTasks.length;
    final inProgress = taskProvider.inProgressTasks.length;
    final upcoming = taskProvider.upcomingTasks.length;

    // Count clients awake right now
    final clients = clientProvider.clients;
    final awakeClients = clients.where((c) {
      final hour = DateHelpers.clientLocalHour(c.timezone);
      return hour >= 6 && hour < 22;
    }).length;

    if (overdue > 0) {
      return '$overdue overdue ${overdue == 1 ? 'task' : 'tasks'} requires attention';
    } else if (dueToday > 0) {
      return '$dueToday ${dueToday == 1 ? 'task' : 'tasks'} due before your day ends';
    } else if (inProgress > 0) {
      return '$inProgress active ${inProgress == 1 ? 'deliverable' : 'deliverables'} in motion';
    } else if (upcoming > 0) {
      return 'All clear today · $upcoming upcoming ${upcoming == 1 ? 'task' : 'tasks'}';
    } else if (clients.isNotEmpty) {
      return '$awakeClients of ${clients.length} ${clients.length == 1 ? 'client' : 'clients'} active in their timezone';
    } else {
      return 'Your slate is quiet today. Ready for new projects.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taskProvider = context.watch<TaskProvider>();
    final clientProvider = context.watch<ClientProvider>();

    final now = DateTime.now();
    final greeting = DateHelpers.getGreeting(now);
    final formattedDate = DateHelpers.formatFullDate(now);
    final briefing = _buildBriefingText(taskProvider, clientProvider);

    final initial =
        userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'A';

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
                    color: isDark
                        ? const Color(0xFFEDF5F0)
                        : const Color(0xFF0F1914),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF8EA397)
                        : const Color(0xFF5A6E64),
                  ),
                ),
                const SizedBox(height: 6),
                // ── Live Contextual Briefing Line ─────────────────────────
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: taskProvider.overdueTasks.isNotEmpty
                            ? const Color(0xFFEF4444)
                            : (taskProvider.dueTodayTasks.isNotEmpty
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        briefing,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFA5B8AD)
                              : const Color(0xFF475E52),
                        ),
                      ),
                    ),
                  ],
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
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF0F1914),
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
