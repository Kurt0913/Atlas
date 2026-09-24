import '../utils/date_helpers.dart';

enum TaskDeadlineVariant {
  today,
  overdue,
  upcoming,
}

class TaskItem {
  final int? id;
  final int clientId;
  final String title;
  final String dueDate;
  final String status;
  final String notes;
  final String? notificationIdDayBefore;
  final String? notificationIdDayOf;
  final String? notificationIdOverdue;
  final int overdueNotified;
  final String clientName;
  final double clientRate;
  final String clientCurrency;

  const TaskItem({
    this.id,
    required this.clientId,
    required this.title,
    required this.dueDate,
    this.status = 'todo',
    this.notes = '',
    this.notificationIdDayBefore,
    this.notificationIdDayOf,
    this.notificationIdOverdue,
    this.overdueNotified = 0,
    this.clientName = 'General',
    this.clientRate = 0.0,
    this.clientCurrency = 'PHP',
  });

  TaskItem copyWith({
    int? id,
    int? clientId,
    String? title,
    String? dueDate,
    String? status,
    String? notes,
    String? notificationIdDayBefore,
    String? notificationIdDayOf,
    String? notificationIdOverdue,
    int? overdueNotified,
    String? clientName,
    double? clientRate,
    String? clientCurrency,
  }) {
    return TaskItem(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      notificationIdDayBefore: notificationIdDayBefore ?? this.notificationIdDayBefore,
      notificationIdDayOf: notificationIdDayOf ?? this.notificationIdDayOf,
      notificationIdOverdue: notificationIdOverdue ?? this.notificationIdOverdue,
      overdueNotified: overdueNotified ?? this.overdueNotified,
      clientName: clientName ?? this.clientName,
      clientRate: clientRate ?? this.clientRate,
      clientCurrency: clientCurrency ?? this.clientCurrency,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'client_id': clientId,
      'title': title,
      'due_date': dueDate,
      'status': status,
      'notes': notes,
      'notification_id_day_before': notificationIdDayBefore,
      'notification_id_day_of': notificationIdDayOf,
      'notification_id_overdue': notificationIdOverdue,
      'overdue_notified': overdueNotified,
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] as int?,
      clientId: (map['client_id'] as num?)?.toInt() ?? 0,
      title: map['title'] as String? ?? '',
      dueDate: map['due_date'] as String? ?? '',
      status: map['status'] as String? ?? 'todo',
      notes: map['notes'] as String? ?? '',
      notificationIdDayBefore: map['notification_id_day_before'] as String?,
      notificationIdDayOf: map['notification_id_day_of'] as String?,
      notificationIdOverdue: map['notification_id_overdue'] as String?,
      overdueNotified: (map['overdue_notified'] as num?)?.toInt() ?? 0,
      clientName: map['client_name'] as String? ?? 'General',
      clientRate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      clientCurrency: map['currency'] as String? ?? 'PHP',
    );
  }

  TaskDeadlineVariant get deadlineVariant {
    final taskDate = DateHelpers.parseDateOnly(dueDate);
    final today = DateHelpers.startOfDay(DateTime.now());
    final taskStart = DateHelpers.startOfDay(taskDate);

    if (taskStart.isBefore(today)) return TaskDeadlineVariant.overdue;
    if (taskStart.isAtSameMomentAs(today)) return TaskDeadlineVariant.today;
    return TaskDeadlineVariant.upcoming;
  }
}
