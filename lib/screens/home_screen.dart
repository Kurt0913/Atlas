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

          // ── Hero Earnings Card ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _buildFinancialHero(context, taskProvider, isDark, formatter),
          ),

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
  // Financial Hero — Luminous Gradient Hero Card with Abstract Shapes & Footer
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFinancialHero(
    BuildContext context,
    TaskProvider taskProvider,
    bool isDark,
    NumberFormat formatter,
  ) {
    final split = taskProvider.earningsSplit;
    final isMonth = taskProvider.timeframe == 'month';
    final completedCount = taskProvider.earningsTasks.length;
    final clientCount =
        taskProvider.earningsTasks.map((t) => t.clientId).toSet().length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF062A1E))
                .withValues(alpha: isDark ? 0.50 : 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark
                  ? const Color(0xFF263B2F)
                  : const Color(0xFF1B4E38).withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Upper Hero Section: Gradient with Abstract Shapes ──
              CustomPaint(
                painter: _HeroCardAbstractShapesPainter(isDark: isDark),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? const [Color(0xFF144633), Color(0xFF08261B)]
                          : const [Color(0xFF0F5A3E), Color(0xFF073322)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Timeframe Switcher + Burnished Brass Invoice Pill
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _timeframeChip(
                                    'month', 'Month', taskProvider, isDark),
                                _timeframeChip(
                                    'week', 'Week', taskProvider, isDark),
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
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 5,
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
                      const SizedBox(height: 16),

                      // Frosted Eyebrow Badge (Matching Reference Image)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isMonth
                                  ? 'Unclaimed & earned this month'
                                  : 'Unclaimed & earned this week',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Large Currency Display
                      if (split.isEmpty) ...[
                        _buildCurrencyRow('PHP', 0.0, formatter, isDark),
                        const SizedBox(height: 4),
                        _buildEmptyEarningsSparkline(isDark, isMonth),
                      ] else ...[
                        ...split.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _buildCurrencyRow(
                                  s.currency, s.total, formatter, isDark),
                            )),
                      ],
                      const SizedBox(height: 8),

                      // Contextual Descriptive Paragraph (Matching Reference Image)
                      Text(
                        completedCount > 0
                            ? 'Across $completedCount completed ${completedCount == 1 ? 'deliverable' : 'deliverables'} this ${isMonth ? 'month' : 'week'} billed across $clientCount ${clientCount == 1 ? 'client' : 'clients'}.'
                            : 'As you finish tasks, your gross earnings and client distributions will track here.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),

                      // Pipeline In-Progress Velocity
                      if (taskProvider.pipelineSplit.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFCD34D)
                                  .withValues(alpha: 0.40),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '✦ Pipeline: ${taskProvider.pipelineSplit.map((p) => '${_symbolFor(p.currency)}${formatter.format(p.total)}').join(', ')} in progress',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFCD34D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Lower Section: Clean White / Contrast Footer Banner ──
              InkWell(
                onTap: () => _showEarningsBreakdown(context, taskProvider),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141F18) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? const Color(0xFF263B2F)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'See your full earnings breakdown',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF0F5A3E),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF0F5A3E),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
        TweenAnimationBuilder<double>(
          key: ValueKey('currency_${currency}_$amount'),
          tween: Tween<double>(begin: 0.0, end: amount),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, child) {
            return Text(
              formatter.format(animatedValue),
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: isDark ? const Color(0xFFEDF5F0) : Colors.white,
                height: 1.1,
              ),
            );
          },
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
            Flexible(
              child: Text(
                'No upcoming deadlines — your slate is clean.',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF8EA397)
                      : const Color(0xFF5A6E64),
                ),
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

class _HeroCardAbstractShapesPainter extends CustomPainter {
  final bool isDark;

  const _HeroCardAbstractShapesPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Top-right large soft glowing gradient orb
    final glowPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF34D399) : const Color(0xFF4ADE80))
              .withValues(alpha: isDark ? 0.22 : 0.28),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.90, size.height * 0.12),
        radius: 120,
      ));
    canvas.drawCircle(
        Offset(size.width * 0.90, size.height * 0.12), 120, glowPaint1);

    // 2. Top-right crisp abstract concentric ring 1
    final ringPaint1 = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.12 : 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(
        Offset(size.width * 0.88, size.height * 0.10), 95, ringPaint1);

    // 3. Top-right crisp abstract concentric ring 2 (larger)
    final ringPaint2 = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.06 : 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(
        Offset(size.width * 0.88, size.height * 0.10), 140, ringPaint2);

    // 4. Bottom-left ambient glowing orb
    final glowPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF10B981) : const Color(0xFF34D399))
              .withValues(alpha: isDark ? 0.16 : 0.20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.08, size.height * 0.88),
        radius: 100,
      ));
    canvas.drawCircle(
        Offset(size.width * 0.08, size.height * 0.88), 100, glowPaint2);

    // 5. Bottom-left crisp abstract ring arc
    final ringPaint3 = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.09 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(
        Offset(size.width * 0.08, size.height * 0.88), 80, ringPaint3);
  }

  @override
  bool shouldRepaint(covariant _HeroCardAbstractShapesPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
