import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/task_item.dart';
import '../services/notification_service.dart';
import '../utils/date_helpers.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskItem> _tasks = [];
  List<CurrencySplit> _earningsSplit = [];
  List<TaskItem> _earningsTasks = [];
  String _timeframe = 'month';
  bool _isLoading = false;

  List<TaskItem> get tasks => _tasks;
  List<CurrencySplit> get earningsSplit => _earningsSplit;
  List<TaskItem> get earningsTasks => _earningsTasks;
  String get timeframe => _timeframe;
  bool get isLoading => _isLoading;

  List<TaskItem> get activeTasks =>
      _tasks.where((t) => t.status != 'done').toList();

  List<TaskItem> get dueTodayTasks {
    final now = DateTime.now();
    return activeTasks.where((task) {
      final taskDate = DateHelpers.parseDateOnly(task.dueDate);
      return DateHelpers.isSameDay(taskDate, now);
    }).toList();
  }

  List<TaskItem> get overdueTasks {
    final today = DateHelpers.startOfDay(DateTime.now());
    return activeTasks.where((task) {
      final taskDate = DateHelpers.parseDateOnly(task.dueDate);
      return DateHelpers.startOfDay(taskDate).isBefore(today);
    }).toList();
  }

  List<TaskItem> get upcomingTasks {
    final today = DateHelpers.startOfDay(DateTime.now());
    return activeTasks.where((task) {
      final taskDate = DateHelpers.parseDateOnly(task.dueDate);
      return DateHelpers.startOfDay(taskDate).isAfter(today);
    }).toList();
  }

  TaskProvider() {
    loadAll();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        AppDatabase.instance.getAllTasks(),
        AppDatabase.instance.getEarningsSplit(timeframe: _timeframe),
        AppDatabase.instance.getEarningsTasks(timeframe: _timeframe),
      ]);
      _tasks = results[0] as List<TaskItem>;
      _earningsSplit = results[1] as List<CurrencySplit>;
      _earningsTasks = results[2] as List<TaskItem>;
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setTimeframe(String newTimeframe) async {
    _timeframe = newTimeframe;
    notifyListeners();
    try {
      final results = await Future.wait([
        AppDatabase.instance.getEarningsSplit(timeframe: _timeframe),
        AppDatabase.instance.getEarningsTasks(timeframe: _timeframe),
      ]);
      _earningsSplit = results[0] as List<CurrencySplit>;
      _earningsTasks = results[1] as List<TaskItem>;
      notifyListeners();
    } catch (e) {
      debugPrint('Error reloading earnings: $e');
    }
  }

  Future<List<TaskItem>> getClientTasks(int clientId) async {
    return await AppDatabase.instance.getClientTasks(clientId);
  }

  Future<int> addTask(
    TaskItem task, {
    String clientName = 'Client',
    bool notificationsEnabled = true,
  }) async {
    final newId = await AppDatabase.instance.createTask(task);

    final notificationIds = await NotificationService.instance.scheduleTaskReminders(
      taskId: newId,
      taskTitle: task.title,
      clientName: clientName,
      dueDateString: task.dueDate,
      notificationsEnabled: notificationsEnabled,
    );

    if (notificationIds.isNotEmpty) {
      await AppDatabase.instance.updateTask(task.copyWith(
        id: newId,
        notificationIdDayBefore: notificationIds['dayBefore'],
        notificationIdDayOf: notificationIds['dayOf'],
        notificationIdOverdue: notificationIds['overdue'],
      ));
    }

    await loadAll();
    return newId;
  }

  Future<void> updateTask(
    TaskItem task, {
    String clientName = 'Client',
    bool notificationsEnabled = true,
  }) async {
    if (task.id != null) {
      await NotificationService.instance.cancelTaskNotifications(task.id!);
      final notificationIds = await NotificationService.instance.scheduleTaskReminders(
        taskId: task.id!,
        taskTitle: task.title,
        clientName: clientName,
        dueDateString: task.dueDate,
        notificationsEnabled: notificationsEnabled,
      );

      await AppDatabase.instance.updateTask(task.copyWith(
        notificationIdDayBefore: notificationIds['dayBefore'],
        notificationIdDayOf: notificationIds['dayOf'],
        notificationIdOverdue: notificationIds['overdue'],
      ));
    } else {
      await AppDatabase.instance.updateTask(task);
    }
    await loadAll();
  }

  Future<void> updateTaskStatus(int taskId, String status) async {
    await AppDatabase.instance.updateTaskStatus(taskId, status);
    if (status == 'done') {
      await NotificationService.instance.cancelTaskNotifications(taskId);
    }
    await loadAll();
  }

  Future<void> deleteTask(int taskId) async {
    await AppDatabase.instance.deleteTask(taskId);
    await NotificationService.instance.cancelTaskNotifications(taskId);
    await loadAll();
  }
}
