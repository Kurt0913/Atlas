import 'package:flutter/material.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';
import 'deadline_badge.dart';

class TaskCard extends StatefulWidget {
  final TaskItem task;
  final TaskDeadlineVariant? deadlineVariant;
  final ValueChanged<String>? onStatusChange;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.deadlineVariant,
    this.onStatusChange,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isHovered = false;

  Color _statusAccentColor(String status) {
    switch (status) {
      case 'done':
        return AppTheme.statusDoneText;
      case 'in_progress':
        return AppTheme.statusInProgressText;
      case 'todo':
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final variant = widget.deadlineVariant ?? task.deadlineVariant;
    final statusColor = _statusAccentColor(task.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('task_${task.id}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            // Delete confirmation
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Task'),
                content: const Text('Are you sure? This cannot be undone.'),
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
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              widget.onDelete?.call();
              return true;
            }
            return false;
          } else if (direction == DismissDirection.startToEnd) {
            // Edit trigger
            widget.onEdit?.call();
            return false;
          }
          return false;
        },
        background: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(
            Icons.edit_outlined,
            color: AppTheme.brassAccent,
            size: 24,
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3B1214) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.delete_outline,
            color: Color(0xFFDC2626),
            size: 24,
          ),
        ),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, _isHovered ? -1.5 : 0, 0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141F18) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isHovered
                    ? (isDark
                        ? const Color(0xFF385242)
                        : const Color(0xFFCBD5CF))
                    : (isDark
                        ? const Color(0xFF263B2F)
                        : const Color(0xFFDDE6E0)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                      alpha: isDark
                          ? (_isHovered ? 0.35 : 0.2)
                          : (_isHovered ? 0.06 : 0.02)),
                  blurRadius: _isHovered ? 10 : 6,
                  offset: Offset(0, _isHovered ? 4 : 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left status accent vertical bar
                    Container(
                      width: 4,
                      color: statusColor,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? const Color(0xFFEDF5F0)
                                          : const Color(0xFF0F1914),
                                    ),
                                  ),
                                ),
                                if (widget.onEdit != null)
                                  InkWell(
                                    onTap: widget.onEdit,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.edit_note_outlined,
                                        size: 20,
                                        color: isDark
                                            ? const Color(0xFF8EA397)
                                            : const Color(0xFF5A6E64),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                task.clientName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFF8EA397)
                                      : const Color(0xFF5A6E64),
                                ),
                              ),
                              DeadlineBadge(dueDate: task.dueDate, variant: variant),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStatusSegments(context, isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStatusSegments(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2C23) : const Color(0xFFF0F5F2),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _statusButton(
            context,
            statusKey: 'todo',
            label: 'To Do',
            isSelected: widget.task.status == 'todo',
            isDark: isDark,
          ),
          _statusButton(
            context,
            statusKey: 'in_progress',
            label: 'In Progress',
            isSelected: widget.task.status == 'in_progress',
            isDark: isDark,
          ),
          _statusButton(
            context,
            statusKey: 'done',
            label: 'Done',
            isSelected: widget.task.status == 'done',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _statusButton(
    BuildContext context, {
    required String statusKey,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    Color selectedBg;
    Color selectedTextColor;

    if (statusKey == 'done') {
      // Independent Forest Green for Done status
      selectedBg = isDark ? const Color(0xFF14532D) : AppTheme.statusDoneBg;
      selectedTextColor = isDark ? const Color(0xFF86EFAC) : AppTheme.statusDoneText;
    } else if (statusKey == 'in_progress') {
      // Independent Warm Amber for In Progress status (never green!)
      selectedBg = isDark ? const Color(0xFF451A03) : AppTheme.statusInProgressBg;
      selectedTextColor = isDark ? const Color(0xFFFCD34D) : AppTheme.statusInProgressText;
    } else {
      // Independent Slate for To Do status
      selectedBg = isDark ? const Color(0xFF1E293B) : AppTheme.statusTodoBg;
      selectedTextColor = isDark ? const Color(0xFFCBD5E1) : AppTheme.statusTodoText;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onStatusChange?.call(statusKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? selectedTextColor
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
