import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/ledger_background.dart';
import '../widgets/notification_history_sheet.dart';
import '../widgets/quick_add_dialog.dart';
import 'clients_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'tasks_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ClientsScreen(),
    TasksScreen(),
    ProfileScreen(),
  ];

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'ATLAS';
      case 1:
        return 'Clients';
      case 2:
        return 'Tasks';
      case 3:
        return 'Profile';
      default:
        return 'ATLAS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taskProvider = context.watch<TaskProvider>();
    final alertCount =
        taskProvider.overdueTasks.length + taskProvider.dueTodayTasks.length;

    return Scaffold(
      extendBody: false,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 20,
        title: _currentIndex == 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 24,
                    color: isDark
                        ? const Color(0xFFEDF5F0)
                        : const Color(0xFF0F1914),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ATLAS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 4,
                      color: isDark
                          ? const Color(0xFFEDF5F0)
                          : const Color(0xFF0F1914),
                    ),
                  ),
                ],
              )
            : Text(
                _getAppBarTitle(_currentIndex),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark
                      ? const Color(0xFFEDF5F0)
                      : const Color(0xFF0F1914),
                ),
              ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 24,
                  color: isDark
                      ? const Color(0xFFEDF5F0)
                      : const Color(0xFF0F1914),
                ),
                if (alertCount > 0)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: taskProvider.overdueTasks.isNotEmpty
                            ? const Color(0xFFEF4444)
                            : (isDark
                                ? AppTheme.brassAccentDark
                                : AppTheme.brassAccent),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF0F1914)
                              : Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notification History',
            onPressed: () => NotificationHistorySheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LedgerBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: CustomBottomNav(
          currentIndex: _currentIndex,
          onTabSelected: (index) {
            setState(() => _currentIndex = index);
          },
          onQuickAdd: () {
            QuickAddDialog.show(context);
          },
        ),
      ),
    );
  }
}
