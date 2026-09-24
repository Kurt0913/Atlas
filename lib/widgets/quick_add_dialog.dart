import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../models/task_item.dart';
import '../providers/client_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/task_provider.dart';
import '../utils/date_helpers.dart';

/// Custom spring-elastic curve simulating a rapid rubber balloon inflation:
/// starts fast, overshoots volume by ~9%, then gently snaps back into place.
class _BalloonPopCurve extends Curve {
  const _BalloonPopCurve();

  @override
  double transformInternal(double t) {
    const s = 1.70158 * 1.45;
    final t1 = t - 1.0;
    return t1 * t1 * ((s + 1.0) * t1 + s) + 1.0;
  }
}

class QuickAddDialog extends StatefulWidget {
  const QuickAddDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Quick Add Task',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return const QuickAddDialog();
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: const _BalloonPopCurve(),
          reverseCurve: Curves.easeInBack,
        );

        final fadeCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
          reverseCurve: const Interval(0.4, 1.0, curve: Curves.easeIn),
        );

        return FadeTransition(
          opacity: fadeCurve,
          child: ScaleTransition(
            // Originates directly at the center '+' button in the bottom navigation bar
            alignment: const Alignment(0.0, 0.92),
            scale: Tween<double>(begin: 0.05, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<QuickAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  int? _selectedClientId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final clients = context.read<ClientProvider>().clients;
    if (clients.isNotEmpty) {
      _selectedClientId = clients.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    final taskProvider = context.read<TaskProvider>();
    final clientProvider = context.read<ClientProvider>();
    final prefs = context.read<PreferencesProvider>();

    final client = clientProvider.clients
        .firstWhere((c) => c.id == _selectedClientId);

    final newTask = TaskItem(
      clientId: _selectedClientId!,
      title: _titleController.text.trim(),
      dueDate: DateHelpers.toDateOnlyString(_selectedDate),
      status: 'todo',
      notes: '',
    );

    await taskProvider.addTask(
      newTask,
      clientName: client.name,
      notificationsEnabled: prefs.notificationsEnabled,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Returns a widget label for [client] that shows its local time inline.
  Widget _buildClientLabel(Client client, bool isDark) {
    final localTime = DateHelpers.clientLocalTimeString(client.timezone);
    final isAwake = DateHelpers.clientLocalHour(client.timezone) >= 6 &&
        DateHelpers.clientLocalHour(client.timezone) < 22;
    final dotColor =
        isAwake ? const Color(0xFF059669) : const Color(0xFFDC2626);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            client.name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (localTime.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            localTime,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF8EA397) : const Color(0xFF5A6E64),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clients = context.watch<ClientProvider>().clients;

    // Find selected client for the time display in the due date hint
    final selectedClient = clients.isEmpty || _selectedClientId == null
        ? null
        : clients.where((c) => c.id == _selectedClientId).firstOrNull;

    final clientLocalTime = selectedClient != null
        ? DateHelpers.clientLocalTimeString(selectedClient.timezone)
        : '';
    final tzLabel = selectedClient != null
        ? DateHelpers.clientTimezoneLabel(selectedClient.timezone)
        : '';

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF141F18) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? const Color(0xFF263B2F) : const Color(0xFFDDE6E0),
        ),
      ),
      title: Text(
        'Quick Add Task',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFFEDF5F0) : const Color(0xFF0F1914),
        ),
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'e.g. Design Landing Page',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Task name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Client dropdown with inline local time
              DropdownButtonFormField<int>(
                value: _selectedClientId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Client'),
                hint: const Text('Select a client'),
                items: clients
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: _buildClientLabel(c, isDark),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedClientId = val);
                },
                validator: (val) => val == null ? 'Pick a client.' : null,
              ),
              // Client local time contextual hint
              if (clientLocalTime.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 13,
                        color: isDark
                            ? const Color(0xFF8EA397)
                            : const Color(0xFF5A6E64),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "It's $clientLocalTime $tzLabel for this client",
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
              ],
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                  ),
                  child: Text(
                    DateHelpers.toDateOnlyString(_selectedDate),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? const Color(0xFF8EA397) : const Color(0xFF5A6E64),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save Task'),
        ),
      ],
    );
  }
}
