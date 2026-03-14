import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.cardDark.withValues(alpha: 0.95)
              : AppColors.cardLight,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Дашборд',
                  index: 0,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => navigationShell.goBranch(0),
                ),
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Контент',
                  index: 1,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => navigationShell.goBranch(1),
                ),
                _NavItem(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Тренды',
                  index: 2,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => navigationShell.goBranch(2),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Статистика',
                  index: 3,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => navigationShell.goBranch(3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Профиль',
                  index: 4,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => navigationShell.goBranch(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final color = isSelected ? AppColors.primaryDark : AppColors.mutedForegroundDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
