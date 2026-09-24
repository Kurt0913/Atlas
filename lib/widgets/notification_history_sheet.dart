import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client.dart';
import '../models/task_item.dart';
import '../providers/client_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_helpers.dart';

enum NotificationType {
  overdue,
  dueToday,
  upcoming,
  completed,
  timezone,
}

class NotificationEntry {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final int? taskId;

  const NotificationEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.taskId,
  });
}

class NotificationHistorySheet extends StatefulWidget {
  const NotificationHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationHistorySheet(),
    );
  }

  @override
  State<NotificationHistorySheet> createState() =>
      _NotificationHistorySheetState();
}

class _NotificationHistorySheetState extends State<NotificationHistorySheet> {
  static const String _keyClearedIds = 'atlas_cleared_notification_ids';
  Set<String> _clearedIds = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadClearedIds();
  }

  Future<void> _loadClearedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyClearedIds) ?? [];
    if (mounted) {
      setState(() {
        _clearedIds = list.toSet();
        _loaded = true;
      });
    }
  }

  Future<void> _clearAll(List<NotificationEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final allIds = entries.map((e) => e.id).toSet();
    _clearedIds.addAll(allIds);
    await prefs.setStringList(_keyClearedIds, _clearedIds.toList());
    if (mounted) {
      setState(() {});
    }
  }

  List<NotificationEntry> _generateNotifications(
    List<TaskItem> tasks,
    List<Client> clients,
  ) {
    final List<NotificationEntry> entries = [];
    final now = DateTime.now();
    final today = DateHelpers.startOfDay(now);

    // 1. Overdue tasks (High Priority)
    for (final task in tasks.where((t) => t.status != 'done')) {
      final dueDate = DateHelpers.parseDateOnly(task.dueDate);
      if (DateHelpers.startOfDay(dueDate).isBefore(today)) {
        final days = today.difference(DateHelpers.startOfDay(dueDate)).inDays;
        entries.add(NotificationEntry(
          id: 'overdue_${task.id}',
          type: NotificationType.overdue,
          title: 'Deadline Overdue',
          message:
              '"${task.title}" is $days ${days == 1 ? 'day' : 'days'} past due date (${task.dueDate}).',
          timestamp: dueDate,
          taskId: task.id,
        ));
      }
    }

    // 2. Due Today tasks
    for (final task in tasks.where((t) => t.status != 'done')) {
      final dueDate = DateHelpers.parseDateOnly(task.dueDate);
      if (DateHelpers.isSameDay(dueDate, now)) {
        entries.add(NotificationEntry(
          id: 'today_${task.id}',
          type: NotificationType.dueToday,
          title: 'Due Before End of Day',
          message:
              '"${task.title}" is scheduled for completion today for ${task.clientName.isNotEmpty ? task.clientName : 'client'}.',
          timestamp: DateTime(now.year, now.month, now.day, 8, 0),
          taskId: task.id,
        ));
      }
    }

    // 3. Upcoming tasks (due tomorrow or within 3 days)
    for (final task in tasks.where((t) => t.status != 'done')) {
      final dueDate = DateHelpers.parseDateOnly(task.dueDate);
      final diff = DateHelpers.startOfDay(dueDate).difference(today).inDays;
      if (diff >= 1 && diff <= 3) {
        entries.add(NotificationEntry(
          id: 'upcoming_${task.id}',
          type: NotificationType.upcoming,
          title: diff == 1 ? 'Due Tomorrow' : 'Approaching Deadline',
          message:
              '"${task.title}" is due in $diff days (${task.dueDate}).',
          timestamp: DateTime(now.year, now.month, now.day, 9, 0),
          taskId: task.id,
        ));
      }
    }

    // 4. Completed milestones (recent earnings)
    for (final task in tasks.where((t) => t.status == 'done').take(5)) {
      entries.add(NotificationEntry(
        id: 'done_${task.id}',
        type: NotificationType.completed,
        title: 'Deliverable Completed',
        message:
            '"${task.title}" marked done. Revenue logged to your earnings ledger.',
        timestamp: DateHelpers.parseDateOnly(task.dueDate),
        taskId: task.id,
      ));
    }

    // 5. Active client timezone overlap
    for (final client in clients) {
      final hour = DateHelpers.clientLocalHour(client.timezone);
      if (hour >= 9 && hour <= 18) {
        entries.add(NotificationEntry(
          id: 'tz_${client.id}_${now.day}',
          type: NotificationType.timezone,
          title: '${client.name} is in Active Hours',
          message:
              'Local time is ${DateHelpers.clientLocalTimeString(client.timezone)} (${DateHelpers.clientTimezoneLabel(client.timezone)}). Great time for updates.',
          timestamp: now,
        ));
      }
    }

    // Sort newest first
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taskProvider = context.watch<TaskProvider>();
    final clientProvider = context.watch<ClientProvider>();

    final allNotifications =
        _generateNotifications(taskProvider.tasks, clientProvider.clients);
    final visibleNotifications =
        allNotifications.where((n) => !_clearedIds.contains(n.id)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141F18) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.16),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(
                color:
                    isDark ? const Color(0xFF263B2F) : const Color(0xFFDDE6E0),
              ),
            ),
          ),
          child: Column(
            children: [
              // ── Drag Handle ──────────────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334A3D)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppTheme.brassAccentDark
                                : AppTheme.brassAccent)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        size: 20,
                        color: isDark
                            ? AppTheme.brassAccentDark
                            : AppTheme.brassAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFFEDF5F0)
                                      : const Color(0xFF0F1914),
                                ),
                              ),
                              if (visibleNotifications.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1B4E38)
                                        : const Color(0xFFD8EFE2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${visibleNotifications.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFF0F5A3E),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Deadlines, client awake hours & deliverable alerts',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF8EA397)
                                  : const Color(0xFF5A6E64),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (visibleNotifications.isNotEmpty)
                      TextButton(
                        onPressed: () => _clearAll(visibleNotifications),
                        child: Text(
                          'Clear all',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.brassAccentDark
                                : AppTheme.brassAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Divider(
                height: 1,
                color:
                    isDark ? const Color(0xFF263B2F) : const Color(0xFFE2E8F0),
              ),

              // ── Notifications List ───────────────────────────────────
              Expanded(
                child: !_loaded
                    ? const Center(child: CircularProgressIndicator())
                    : visibleNotifications.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            itemCount: visibleNotifications.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = visibleNotifications[index];
                              return _buildNotificationCard(item, isDark);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationEntry item, bool isDark) {
    Color iconColor;
    Color iconBg;
    IconData iconData;

    switch (item.type) {
      case NotificationType.overdue:
        iconColor = const Color(0xFFEF4444);
        iconBg = const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.12);
        iconData = Icons.warning_amber_rounded;
        break;
      case NotificationType.dueToday:
        iconColor = const Color(0xFFF59E0B);
        iconBg = const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.12);
        iconData = Icons.alarm_rounded;
        break;
      case NotificationType.upcoming:
        iconColor = isDark ? AppTheme.brassAccentDark : AppTheme.brassAccent;
        iconBg = (isDark ? AppTheme.brassAccentDark : AppTheme.brassAccent)
            .withValues(alpha: isDark ? 0.2 : 0.12);
        iconData = Icons.calendar_today_rounded;
        break;
      case NotificationType.completed:
        iconColor = const Color(0xFF10B981);
        iconBg = const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12);
        iconData = Icons.check_circle_outline_rounded;
        break;
      case NotificationType.timezone:
        iconColor = const Color(0xFF06B6D4);
        iconBg = const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.2 : 0.12);
        iconData = Icons.public_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2C23) : const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF263B2F) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFEDF5F0)
                              : const Color(0xFF0F1914),
                        ),
                      ),
                    ),
                    Text(
                      _formatRelativeTime(item.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF8EA397)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: isDark
                        ? const Color(0xFFC5DACD)
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C2C23) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: isDark
                    ? const Color(0xFF8EA397)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'All Caught Up',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFEDF5F0)
                    : const Color(0xFF0F1914),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No unread alerts. Approaching deadlines and client timezone updates will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? const Color(0xFF8EA397)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      if (diff.inMinutes <= 1) return 'Just now';
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24 && time.day == now.day) {
      return 'Today, ${DateFormat('h:mm a').format(time)}';
    } else if (diff.inDays <= 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
