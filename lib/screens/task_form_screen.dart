import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_item.dart';
import '../providers/client_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/task_provider.dart';
import '../utils/date_helpers.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskItem? existingTask;
  final int? preselectedClientId;

  const TaskFormScreen({
    super.key,
    this.existingTask,
    this.preselectedClientId,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _notesController;

  int? _selectedClientId;
  late DateTime _dueDate;
  late String _status;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');

    _dueDate = task != null
        ? DateHelpers.parseDateOnly(task.dueDate)
        : DateTime.now();

    _status = task?.status ?? 'todo';

    if (task != null) {
      _selectedClientId = task.clientId;
    } else if (widget.preselectedClientId != null) {
      _selectedClientId = widget.preselectedClientId;
    } else {
      final clients = context.read<ClientProvider>().clients;
      if (clients.isNotEmpty) {
        _selectedClientId = clients.first.id;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client.')),
      );
      return;
    }

    final clientProvider = context.read<ClientProvider>();
    final taskProvider = context.read<TaskProvider>();
    final prefs = context.read<PreferencesProvider>();

    final client = clientProvider.clients
        .firstWhere((c) => c.id == _selectedClientId, orElse: () => clientProvider.clients.first);

    if (widget.existingTask != null) {
      final updated = widget.existingTask!.copyWith(
        clientId: _selectedClientId!,
        title: _titleController.text.trim(),
        dueDate: DateHelpers.toDateOnlyString(_dueDate),
        status: _status,
        notes: _notesController.text.trim(),
        clientName: client.name,
      );
      await taskProvider.updateTask(
        updated,
        clientName: client.name,
        notificationsEnabled: prefs.notificationsEnabled,
      );
    } else {
      final newTask = TaskItem(
        clientId: _selectedClientId!,
        title: _titleController.text.trim(),
        dueDate: DateHelpers.toDateOnlyString(_dueDate),
        status: _status,
        notes: _notesController.text.trim(),
      );
      await taskProvider.addTask(
        newTask,
        clientName: client.name,
        notificationsEnabled: prefs.notificationsEnabled,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clients = context.watch<ClientProvider>().clients;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTask != null ? 'Edit Task' : 'New Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'e.g. Audit Q3 Tax Return',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Task name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: _selectedClientId,
                decoration: const InputDecoration(labelText: 'Client'),
                hint: const Text('Select a client'),
                items: clients
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: clients.isEmpty
                    ? null
                    : (val) {
                        setState(() => _selectedClientId = val);
                      },
                validator: (val) => val == null ? 'Please pick a client.' : null,
              ),
              if (clients.isEmpty) ...[
                const SizedBox(height: 4),
                const Text(
                  'No clients yet. Add one from the Clients tab.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
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
                    DateHelpers.toDateOnlyString(_dueDate),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Status segment selector
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF362B20) : const Color(0xFFF3E7D5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _statusOption('todo', 'To Do', isDark),
                    _statusOption('in_progress', 'In Progress', isDark),
                    _statusOption('done', 'Done', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Project brief, links, or deliverables',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusOption(String key, String label, bool isDark) {
    final isSelected = _status == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? const Color(0xFF5F4B38)
                    : const Color(0xFFF0DEC4))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDark
                      ? const Color(0xFFFFF2DF)
                      : const Color(0xFF5F452B))
                  : (isDark
                      ? const Color(0xFFD9C3A8)
                      : const Color(0xFF8B6D4C)),
            ),
          ),
        ),
      ),
    );
  }
}
