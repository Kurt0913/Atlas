import 'package:intl/intl.dart';

class DateHelpers {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  static String toDateOnlyString(DateTime date) {
    return _dateFormat.format(date);
  }

  static DateTime parseDateOnly(String dateString) {
    try {
      return _dateFormat.parse(dateString);
    } catch (_) {
      final parts = dateString.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      return DateTime.now();
    }
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String formatFullDate(DateTime date) {
    return DateFormat('EEEE, MMMM d').format(date);
  }

  static String getGreeting(DateTime date) {
    final hour = date.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Returns the client's current local time as a formatted string using their
  /// IANA timezone offset vs UTC. Uses a fixed offset table for common zones.
  static String clientLocalTimeString(String ianaTimezone) {
    try {
      final offsetMinutes = _ianaToOffsetMinutes(ianaTimezone);
      final utcNow = DateTime.now().toUtc();
      final clientNow = utcNow.add(Duration(minutes: offsetMinutes));
      return DateFormat('h:mm a').format(clientNow);
    } catch (_) {
      return '';
    }
  }

  /// Returns a short timezone label like "PHT", "EST", "UTC", etc.
  static String clientTimezoneLabel(String ianaTimezone) {
    return _ianaToLabel(ianaTimezone);
  }

  /// Returns the hour-only number (0–23) in the client's local timezone.
  static int clientLocalHour(String ianaTimezone) {
    try {
      final offsetMinutes = _ianaToOffsetMinutes(ianaTimezone);
      final utcNow = DateTime.now().toUtc();
      final clientNow = utcNow.add(Duration(minutes: offsetMinutes));
      return clientNow.hour;
    } catch (_) {
      return DateTime.now().hour;
    }
  }

  static int _ianaToOffsetMinutes(String tz) {
    const Map<String, int> offsets = {
      'UTC': 0,
      'GMT': 0,
      'Asia/Manila': 480,
      'Asia/Singapore': 480,
      'Asia/Hong_Kong': 480,
      'Asia/Taipei': 480,
      'Asia/Shanghai': 480,
      'Asia/Tokyo': 540,
      'Asia/Seoul': 540,
      'Asia/Kolkata': 330,
      'Asia/Colombo': 330,
      'Asia/Dubai': 240,
      'Asia/Riyadh': 180,
      'Asia/Baghdad': 180,
      'Asia/Tehran': 210,
      'Asia/Jakarta': 420,
      'Asia/Bangkok': 420,
      'Asia/Kuala_Lumpur': 480,
      'Australia/Sydney': 600,
      'Australia/Melbourne': 600,
      'Australia/Brisbane': 600,
      'Australia/Perth': 480,
      'Europe/London': 0,
      'Europe/Dublin': 0,
      'Europe/Lisbon': 0,
      'Europe/Paris': 60,
      'Europe/Berlin': 60,
      'Europe/Rome': 60,
      'Europe/Madrid': 60,
      'Europe/Amsterdam': 60,
      'Europe/Brussels': 60,
      'Europe/Vienna': 60,
      'Europe/Warsaw': 60,
      'Europe/Stockholm': 60,
      'Europe/Oslo': 60,
      'Europe/Helsinki': 120,
      'Europe/Athens': 120,
      'Europe/Bucharest': 120,
      'Europe/Istanbul': 180,
      'Europe/Moscow': 180,
      'America/New_York': -300,
      'America/Chicago': -360,
      'America/Denver': -420,
      'America/Los_Angeles': -480,
      'America/Anchorage': -540,
      'America/Honolulu': -600,
      'America/Phoenix': -420,
      'America/Toronto': -300,
      'America/Vancouver': -480,
      'America/Sao_Paulo': -180,
      'America/Argentina/Buenos_Aires': -180,
      'America/Bogota': -300,
      'America/Lima': -300,
      'America/Santiago': -240,
      'America/Mexico_City': -360,
      'Pacific/Auckland': 720,
      'Pacific/Fiji': 720,
    };
    return offsets[tz] ?? 0;
  }

  static String _ianaToLabel(String tz) {
    const Map<String, String> labels = {
      'UTC': 'UTC',
      'GMT': 'GMT',
      'Asia/Manila': 'PHT',
      'Asia/Singapore': 'SGT',
      'Asia/Hong_Kong': 'HKT',
      'Asia/Taipei': 'CST',
      'Asia/Shanghai': 'CST',
      'Asia/Tokyo': 'JST',
      'Asia/Seoul': 'KST',
      'Asia/Kolkata': 'IST',
      'Asia/Dubai': 'GST',
      'Asia/Riyadh': 'AST',
      'Asia/Jakarta': 'WIB',
      'Asia/Bangkok': 'ICT',
      'Asia/Kuala_Lumpur': 'MYT',
      'Australia/Sydney': 'AEST',
      'Australia/Melbourne': 'AEST',
      'Australia/Brisbane': 'AEST',
      'Australia/Perth': 'AWST',
      'Europe/London': 'GMT',
      'Europe/Paris': 'CET',
      'Europe/Berlin': 'CET',
      'Europe/Moscow': 'MSK',
      'America/New_York': 'EST',
      'America/Chicago': 'CST',
      'America/Denver': 'MST',
      'America/Los_Angeles': 'PST',
      'America/Sao_Paulo': 'BRT',
      'Pacific/Auckland': 'NZST',
    };
    return labels[tz] ?? 'UTC';
  }
}

