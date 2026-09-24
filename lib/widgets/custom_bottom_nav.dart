import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onQuickAdd;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      height: 62,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141F18) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF263B2F) : const Color(0xFFDDE6E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _navItem(
            context,
            index: 0,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            isDark: isDark,
          ),
          _navItem(
            context,
            index: 1,
            icon: Icons.group_outlined,
            activeIcon: Icons.group,
            isDark: isDark,
          ),
          // Center Quick Add Button — Single Action Accent: Burnished Brass
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: onQuickAdd,
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.brassAccentDark : AppTheme.brassAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? AppTheme.brassAccentDark : AppTheme.brassAccent)
                            .withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          _navItem(
            context,
            index: 2,
            icon: Icons.checklist_rtl_outlined,
            activeIcon: Icons.checklist_rtl,
            isDark: isDark,
          ),
          _navItem(
            context,
            index: 3,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required bool isDark,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? const Color(0xFF1E2C24)
                      : const Color(0xFFE8ECE9))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0F1914))
                  : (isDark
                      ? const Color(0xFF6B8274)
                      : const Color(0xFF8C9E95)),
            ),
          ),
        ),
      ),
    );
  }
}
