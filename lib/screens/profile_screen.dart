import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/client_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/task_provider.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      await BackupService.instance.exportBackup();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleImport() async {
    try {
      final parsed = await BackupService.instance.pickAndParseBackupFile();
      if (parsed == null || !mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Critical Overwrite'),
          content: const Text(
            'Importing this backup will completely wipe your current local databases. This action cannot be undone. Do you wish to override?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Overwrite Data'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isImporting = true);
        await BackupService.instance.restoreBackup(parsed);
        if (mounted) {
          await context.read<ClientProvider>().loadClients();
          await context.read<TaskProvider>().loadAll();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database successfully restored!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _openPortfolio() async {
    final uri = Uri.parse('https://github.com/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'Preferences',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFEDF5F0) : const Color(0xFF0F1914),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              // Theme Toggle
              SwitchListTile(
                secondary: Icon(
                  Icons.brightness_6_outlined,
                  color: isDark ? const Color(0xFFEDF5F0) : const Color(0xFF0F1914),
                ),
                title: const Text(
                  'Dark Mode',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Override system appearance.'),
                value: prefs.themeMode == ThemeMode.dark,
                onChanged: (val) {
                  prefs.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF263B2F)
                    : const Color(0xFFDDE6E0),
              ),
              // Base Currency
              ListTile(
                leading: Icon(
                  Icons.payments_outlined,
                  color: isDark ? const Color(0xFFEDF5F0) : const Color(0xFF0F1914),
                ),
                title: const Text(
                  'Base Currency',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Used as the default on records.'),
                trailing: SizedBox(
                  width: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _currencyPill('PHP', prefs.defaultCurrency == 'PHP', isDark, () {
                        prefs.setDefaultCurrency('PHP');
                      }),
                      const SizedBox(width: 6),
                      _currencyPill('USD', prefs.defaultCurrency == 'USD', isDark, () {
                        prefs.setDefaultCurrency('USD');
                      }),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF263B2F)
                    : const Color(0xFFDDE6E0),
              ),
              // Notifications
              SwitchListTile(
                secondary: Icon(
                  Icons.notifications_active_outlined,
                  color: isDark ? const Color(0xFFEDF5F0) : const Color(0xFF0F1914),
                ),
                title: const Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Alerts before task deadlines.'),
                value: prefs.notificationsEnabled,
                onChanged: (val) {
                  prefs.setNotificationsEnabled(val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Data & Backup',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFEDF5F0) : const Color(0xFF0F1914),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: _isExporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.cloud_upload_outlined,
                        color: isDark ? const Color(0xFFEDF5F0) : const Color(0xFF0F1914),
                      ),
                title: const Text(
                  'Back Up My Data',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Export clients and tasks to a JSON file.'),
                onTap: _isExporting ? null : _handleExport,
              ),
              Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF263B2F)
                    : const Color(0xFFDDE6E0),
              ),
              ListTile(
                leading: _isImporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.cloud_download_outlined,
                        color: isDark ? const Color(0xFFEDF5F0) : const Color(0xFF0F1914),
                      ),
                title: const Text(
                  'Restore from Backup',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Restore records from a previously saved file.'),
                onTap: _isImporting ? null : _handleImport,
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Center(
          child: Column(
            children: [
              Text(
                'Atlas Core v1.0.0',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF8EA397)
                      : const Color(0xFF5A6E64),
                ),
              ),
              TextButton(
                onPressed: _openPortfolio,
                child: Text(
                  'Built by Kurt',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.brassAccentDark
                        : AppTheme.brassAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _currencyPill(
      String label, bool isSelected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.brassAccentDark : AppTheme.brassAccent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppTheme.brassAccentDark : AppTheme.brassAccent)
                : (isDark ? const Color(0xFF263B2F) : const Color(0xFFDDE6E0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF8EA397) : const Color(0xFF5A6E64)),
          ),
        ),
      ),
    );
  }
}

