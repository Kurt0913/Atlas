import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/editorial_tip_card.dart';
import '../widgets/quick_add_dialog.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTasks = taskProvider.tasks.where((t) {
      if (_filter == 'all') return true;
      return t.status == _filter;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => taskProvider.loadAll(),
      color: AppTheme.brassAccent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Filter Segments (Quiet ink active state, not green) ───────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C2C23) : const Color(0xFFF0F5F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF263B2F) : const Color(0xFFDDE6E0),
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _filterButton('all', 'All', isDark),
                _filterButton('todo', 'To Do', isDark),
                _filterButton('in_progress', 'In Progress', isDark),
                _filterButton('done', 'Done', isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (filteredTasks.isEmpty)
            // ── Centered, Balanced Empty State ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF14241B)
                          : const Color(0xFFE8EFEA),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.checklist_outlined,
                      size: 36,
                      color: isDark
                          ? const Color(0xFF8EA397)
                          : const Color(0xFF5A6E64),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _filter == 'all'
                        ? 'No tasks recorded yet'
                        : 'No ${_filter == 'todo' ? 'to-do' : (_filter == 'in_progress' ? 'in-progress' : 'completed')} tasks',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFEDF5F0)
                          : const Color(0xFF0F1914),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track deliverables, client rates, and deadlines in one place.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: isDark
                          ? const Color(0xFF8EA397)
                          : const Color(0xFF5A6E64),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => QuickAddDialog.show(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Task'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...filteredTasks.map((task) => TaskCard(
                  task: task,
                  onStatusChange: (status) =>
                      taskProvider.updateTaskStatus(task.id!, status),
                  onEdit: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaskFormScreen(existingTask: task),
                      ),
                    );
                  },
                  onDelete: () => taskProvider.deleteTask(task.id!),
                )),
            // ── Distinct Editorial Guidance Card (Warm paper, dashed border, actionable) ─
            if (filteredTasks.length <= 2) ...[
              const SizedBox(height: 8),
              EditorialTipCard(
                eyebrow: 'Earnings & Invoices',
                title: 'Logging billable work',
                message:
                    'Marking a task "Done" logs its rate to your monthly earnings and prepares it for one-tap invoice PDF generation.',
                actionLabel: 'Log a task →',
                icon: Icons.receipt_long_outlined,
                onAction: () {
                  QuickAddDialog.show(context);
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _filterButton(String key, String label, bool isDark) {
    final isSelected = _filter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? const Color(0xFFEDF5F0)
                    : const Color(0xFF0F1914))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDark ? const Color(0xFF0F1914) : Colors.white)
                  : (isDark
                      ? const Color(0xFF8EA397)
                      : const Color(0xFF5A6E64)),
            ),
          ),
        ),
      ),
    );
  }
}
