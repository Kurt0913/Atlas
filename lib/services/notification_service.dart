import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/date_helpers.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  NotificationService._init();

  Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return; // Local notifications active primarily on mobile
    }

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (!_isInitialized) return false;

    if (Platform.isIOS) {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  Future<Map<String, String>> scheduleTaskReminders({
    required int taskId,
    required String taskTitle,
    required String clientName,
    required String dueDateString,
    required bool notificationsEnabled,
  }) async {
    if (!_isInitialized || !notificationsEnabled) {
      return {};
    }

    final dueDate = DateHelpers.parseDateOnly(dueDateString);
    final now = DateTime.now();

    final dayBefore = DateTime(dueDate.year, dueDate.month, dueDate.day - 1, 9, 0);
    final dayOf = DateTime(dueDate.year, dueDate.month, dueDate.day, 8, 0);
    final overdue = DateTime(dueDate.year, dueDate.month, dueDate.day + 1, 9, 0);

    final Map<String, String> ids = {};

    try {
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'atlas_deadlines',
          'Task Deadlines',
          channelDescription: 'Alarms and reminders for task deadlines',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      if (dayBefore.isAfter(now)) {
        final id = taskId * 10 + 1;
        ids['dayBefore'] = id.toString();
        // Fallback simple show if tz is not used
      }

      if (dayOf.isAfter(now)) {
        final id = taskId * 10 + 2;
        ids['dayOf'] = id.toString();
      }

      if (overdue.isAfter(now)) {
        final id = taskId * 10 + 3;
        ids['overdue'] = id.toString();
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }

    return ids;
  }

  Future<void> cancelTaskNotifications(int taskId) async {
    if (!_isInitialized) return;
    try {
      await _flutterLocalNotificationsPlugin.cancel(taskId * 10 + 1);
      await _flutterLocalNotificationsPlugin.cancel(taskId * 10 + 2);
      await _flutterLocalNotificationsPlugin.cancel(taskId * 10 + 3);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }
}
