import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/app_database.dart';

class BackupService {
  static final BackupService instance = BackupService._init();

  BackupService._init();

  Future<bool> exportBackup() async {
    try {
      final data = await AppDatabase.instance.exportDatabaseData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/atlas_backup.json');
      await file.writeAsString(jsonString, encoding: utf8);

      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Atlas Backup Data',
      );

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('Export failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> pickAndParseBackupFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (file == null) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes);

      final dynamic decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid JSON root format');
      }

      if (!decoded.containsKey('clients') && !decoded.containsKey('tasks')) {
        throw const FormatException('File does not contain Atlas backup schema');
      }

      return decoded;
    } catch (e) {
      debugPrint('Import failed: $e');
      rethrow;
    }
  }

  Future<void> restoreBackup(Map<String, dynamic> data) async {
    await AppDatabase.instance.importDatabaseData(data);
  }
}
