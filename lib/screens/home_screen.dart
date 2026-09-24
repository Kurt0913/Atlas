import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task_item.dart';
import '../providers/client_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_helpers.dart';
import '../widgets/greeting_header.dart';
import '../widgets/invoice_export_dialog.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeTab = 'today';

  String _symbolFor(String currency) {
    switch (currency.toUpperCase()) {
      case 'PHP':
        return '₱';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'AUD':
      case 'CAD':
      case 'SGD':
        return '\$';
      default:
        return '$currency ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final clientProvider = context.watch<ClientProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat('#,##0.##');

    final dueToday = taskProvider.dueTodayTasks;
    final overdue = taskProvider.overdueTasks;
    final upcoming = taskProvider.upcomingTasks;

    return RefreshIndicator(
      onRefresh: () => taskProvider.loadAll(),
      color: AppTheme.brassAccent,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── Greeting Header ─────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: GreetingHeader(userName: 'Kurt'),
          ),

          // ── Hero Earnings Card (Edge-to-edge full-bleed, zero-radius) ─
          _buildFinancialHero(context, taskProvider, isDark, formatter),

          const SizedBox(height: 16),

          // ── Screen Content with Standard Horizontal Inset ───────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Context Strip (Client local time on next due) ─────
                _buildNextDeadlineCard(
                    context, taskProvider, clientProvider, isDark),
                const SizedBox(height: 20),

                // ── Tab Bar (Clean underline style) ───────────────────
                _buildUnderlineTabBar(context, isDark, dueToday.length,
                    overdue.length, upcoming.length),
                const SizedBox(height: 16),

                // ── Task List ──────────────────────────────────────────
                if (_activeTab == 'today') ...[
                  if (dueToday.isEmpty)
                    _emptyState(
                      context,
                      icon: Icons.check_circle_outline_rounded,
                      message: 'Your slate is clean today. Enjoy the silence.',
                      isDark: isDark,
                    )
                  else
                    ...dueToday.map((task) => TaskCard(
                          task: task,
                          deadlineVariant: TaskDeadlineVariant.today,
                          onStatusChange: (status) =>
                              taskProvider.updateTaskStatus(task.id!, status),
                          onEdit: () => _editTask(task),
                          onDelete: () => taskProvider.deleteTask(task.id!),
                        )),
                ] else if (_activeTab == 'overdue') ...[
                  if (overdue.isEmpty)
                    _emptyState(
                      context,
                      icon: Icons.done_all_rounded,
                      message: 'Zero overdue tasks. Flawless tracking!',
                      isDark: isDark,
                    )
                  else
                    ...overdue.map((task) => TaskCard(
                          task: task,
                          deadlineVariant: TaskDeadlineVariant.overdue,
                          onStatusChange: (status) =>
                              taskProvider.updateTaskStatus(task.id!, status),
                          onEdit: () => _editTask(task),
                          onDelete: () => taskProvider.deleteTask(task.id!),
                        )),
                ] else ...[
                  if (upcoming.isEmpty)
                    _emptyState(
                      context,
                      icon: Icons.calendar_month_outlined,
                      message: 'No upcoming tasks plotted just yet.',
                      isDark: isDark,
                    )
                  else
                    ...upcoming.map((task) => TaskCard(
                          task: task,
                          deadlineVariant: TaskDeadlineVariant.upcoming,
                          onStatusChange: (status) =>
                              taskProvider.updateTaskStatus(task.id!, status),
                          onEdit: () => _editTask(task),
                          onDelete: () => taskProvider.deleteTask(task.id!),
                        )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editTask(TaskItem task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(existingTask: task),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Financial Hero — Distinct Full-Width Rectilinear Block
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFinancialHero(
    BuildContext context,
    TaskProvider taskProvider,
    bool isDark,
    NumberFormat formatter,
  ) {
    final split = taskProvider.earningsSplit;
    final isMonth = taskProvider.timeframe == 'month';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F261B) : AppTheme.ledgerGreen,
        borderRadius: BorderRadius.zero, // Structurally distinct 0 border-radius
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E382B) : const Color(0xFF0C2419),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Timeframe Switcher + Brass Action Invoice Button ──
          Row(
            children: [
              // Segmented pill
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B3D2C)
                      : const Color(0xFF1E4F39),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _timeframeChip('month', 'Month', taskProvider, isDark),
                    _timeframeChip('week', 'Week', taskProvider, isDark),
                  ],
                ),
              ),
              const Spacer(),
              // Action Accent: Burnished Brass Invoice Pill Button
              InkWell(
                onTap: () => InvoiceExportDialog.show(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.brassAccentDark
                        : AppTheme.brassAccent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '📋',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Invoice',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Eyebrow ────────────────────────────────────────────────
          Text(
            isMonth ? 'Earned this month' : 'Earned this week',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? const Color(0xFF8EA397)
                  : const Color(0xFFA3C7B3),
            ),
          ),
          const SizedBox(height: 6),

          // ── Genuinely Large Currency Display (Fixed ₱ glyph) ────────
          if (split.isEmpty) ...[
            GestureDetector(
              onTap: () => _showEarningsBreakdown(context, taskProvider),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrencyRow('PHP', 0.0, formatter, isDark),
                  const SizedBox(height: 4),
                  _buildEmptyEarningsSparkline(isDark, isMonth),
                ],
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: () => _showEarningsBreakdown(context, taskProvider),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...split.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _buildCurrencyRow(
                            s.currency, s.total, formatter, isDark),
                      )),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 13,
                        color: isDark
                            ? const Color(0xFF8EA397)
                            : const Color(0xFFA3C7B3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to inspect breakdown',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF8EA397)
                              : const Color(0xFFA3C7B3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a faint ghost sparkline / bar-chart outline when earnings are at ₱0,
  /// giving the earnings card texture and previewing what revenue tracking looks like.
  Widget _buildEmptyEarningsSparkline(bool isDark, bool isMonth) {
    final labels = isMonth
        ? ['W1', 'W2', 'W3', 'W4']
        : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final ghostHeights = isMonth
        ? [24.0, 36.0, 28.0, 18.0]
        : [14.0, 26.0, 36.0, 20.0, 32.0, 12.0, 22.0];

    final mintColor =
        isDark ? const Color(0xFF8EA397) : const Color(0xFFA3C7B3);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF132E21).withValues(alpha: 0.45)
            : const Color(0xFF0F3122).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: mintColor.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(labels.length, (i) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: ghostHeights[i],
                        decoration: BoxDecoration(
                          color: mintColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: mintColor.withValues(alpha: 0.22),
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: mintColor.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.insights_outlined,
                size: 13,
                color: mintColor.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 5),
              Text(
                'Ledger timeline: populates as tasks are completed',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: mintColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the currency row by cleanly rendering the currency symbol
  /// in default sans-serif (fixing the Peso ₱ strikethrough glyph bug in serifs)
  /// and the numeric amount in genuine 48px bold serif numerals.
  Widget _buildCurrencyRow(
    String currency,
    double amount,
    NumberFormat formatter,
    bool isDark,
  ) {
    final sym = _symbolFor(currency);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          sym,
          style: TextStyle(
            // Sans-serif avoids the strikethrough crossbar collision bug with serif ₱
            fontFamily: null,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: isDark
                ? const Color(0xFFC5DACD)
                : const Color(0xFFA3C7B3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          formatter.format(amount),
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            color: isDark ? const Color(0xFFEDF5F0) : Colors.white,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _timeframeChip(
    String value,
    String label,
    TaskProvider taskProvider,
    bool isDark,
  ) {
    final selected = taskProvider.timeframe == value;
    return GestureDetector(
      onTap: () async => await taskProvider.setTimeframe(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? AppTheme.ledgerGreen
                : (isDark
                    ? const Color(0xFF8EA397)
                    : const Color(0xFFA3C7B3)),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Next Deadline / Client Local Time Context Card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNextDeadlineCard(
    BuildContext context,
    TaskProvider taskProvider,
    ClientProvider clientProvider,
    bool isDark,
  ) {
    final active = [
      ...taskProvider.overdueTasks,
      ...taskProvider.dueTodayTasks,
      ...taskProvider.upcomingTasks,
    ];

    if (active.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141F18) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF263B2F) : const Color(0xFFDDE6E0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF94A3B8),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'No upcoming deadlines — your slate is clean.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF8EA397)
                    : const Color(0xFF5A6E64),
              ),
            ),
          ],
        ),
      );
    }

    active.sort((a, b) => DateHelpers.parseDateOnly(a.dueDate)
        .compareTo(DateHelpers.parseDateOnly(b.dueDate)));

    final next = active.first;
    final dueDate = DateHelpers.parseDateOnly(next.dueDate);
    final today = DateHelpers.startOfDay(DateTime.now());
    final diff = DateHelpers.startOfDay(dueDate).difference(today).inDays;

    String dueText;
    Color dotColor;
    if (diff < 0) {
      dueText = '${diff.abs()}d overdue';
      dotColor = AppTheme.statusOverdueText;
    } else if (diff == 0) {
      dueText = 'Due today';
      dotColor = AppTheme.statusInProgressText;
    } else if (diff == 1) {
      dueText = 'Due in 1 day';
      dotColor = AppTheme.brassAccent;
    } else {
      dueText = 'Due in $diff days';
      dotColor = const Color(0xFF94A3B8);
    }

    final client = clientProvider.clients
        .where((c) => c.id == next.clientId)
        .firstOrNull;
    final timezone = client?.timezone ?? 'UTC';
    final clientName = client?.name ?? next.clientName;
    final localTime = DateHelpers.clientLocalTimeString(timezone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141F18) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF263B2F) : const Color(0xFFDDE6E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFFEDF5F0)
                            : const Color(0xFF0F1914),
                      ),
                      children: [
                        TextSpan(
                          text: clientName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (localTime.isNotEmpty) ...[
                          TextSpan(
                            text: ' · $localTime',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF8EA397)
                                  : const Color(0xFF5A6E64),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dueText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: dotColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Underline Tab Bar (Evenly Distributed Across the Middle)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildUnderlineTabBar(
    BuildContext context,
    bool isDark,
    int todayCount,
    int overdueCount,
    int upcomingCount,
  ) {
    return Column(
      children: [
        Row(
          children: [
            _underlineTabItem('today', 'Today · $todayCount', isDark),
            _underlineTabItem('overdue', 'Overdue · $overdueCount', isDark),
            _underlineTabItem('upcoming', 'Upcoming · $upcomingCount', isDark),
          ],
        ),
        Container(
          height: 1,
          color: isDark ? const Color(0xFF263B2F) : const Color(0xFFE2EBE5),
        ),
      ],
    );
  }

  Widget _underlineTabItem(String key, String label, bool isDark) {
    final isSelected = _activeTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = key),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFFEDF5F0)
                          : const Color(0xFF0F1914))
                      : (isDark
                          ? const Color(0xFF8EA397)
                          : const Color(0xFF5A6E64)),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2.5,
              width: isSelected ? 56 : 0,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? const Color(0xFFEDF5F0)
                        : const Color(0xFF0F1914))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: isDark ? const Color(0xFF263B2F) : const Color(0xFFDDE6E0),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF8EA397) : const Color(0xFF5A6E64),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Earnings Breakdown Dialog
  // ─────────────────────────────────────────────────────────────────────────

  void _showEarningsBreakdown(BuildContext context, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final timeframe = taskProvider.timeframe;
            final tasks = taskProvider.earningsTasks;
            final formatter = NumberFormat('#,##0.##');

            return AlertDialog(
              title: Text(
                'Earnings Breakdown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFEDF5F0)
                      : const Color(0xFF0F1914),
                ),
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF141F18)
                            : const Color(0xFFF0F5F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await taskProvider.setTimeframe('month');
                                setModalState(() {});
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: timeframe == 'month'
                                      ? (isDark
                                          ? AppTheme.brassAccentDark
                                          : AppTheme.brassAccent)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'This Month',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: timeframe == 'month'
                                        ? Colors.white
                                        : (isDark
                                            ? const Color(0xFF8EA397)
                                            : const Color(0xFF5A6E64)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await taskProvider.setTimeframe('week');
                                setModalState(() {});
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: timeframe == 'week'
                                      ? (isDark
                                          ? AppTheme.brassAccentDark
                                          : AppTheme.brassAccent)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'This Week',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: timeframe == 'week'
                                        ? Colors.white
                                        : (isDark
                                            ? const Color(0xFF8EA397)
                                            : const Color(0xFF5A6E64)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: tasks.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No tasks completely finished for this timeframe.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF8EA397)
                                      : const Color(0xFF5A6E64),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: tasks.length,
                              separatorBuilder: (context, index) => Divider(
                                color: isDark
                                    ? const Color(0xFF263B2F)
                                    : const Color(0xFFDDE6E0),
                                height: 1,
                              ),
                              itemBuilder: (ctx, idx) {
                                final t = tasks[idx];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: isDark
                                                    ? const Color(0xFFEDF5F0)
                                                    : const Color(0xFF0F1914),
                                              ),
                                            ),
                                            Text(
                                              t.clientName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark
                                                    ? const Color(0xFF8EA397)
                                                    : const Color(0xFF5A6E64),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${t.clientCurrency} ${formatter.format(t.clientRate)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.statusDoneText,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.brassAccentDark
                          : AppTheme.brassAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
