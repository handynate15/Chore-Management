import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'parent_overview_tab.dart';
import 'parent_chores_tab.dart';
import 'parent_calendar_tab.dart';
import 'parent_approvals_tab.dart';
import 'parent_settings_tab.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = const [
    ParentOverviewTab(),
    ParentChoresTab(),
    ParentCalendarTab(),
    ParentApprovalsTab(),
    ParentSettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final pendingCount = provider.getPendingApprovals().length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _tabs[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.grid_view_rounded, 'Overview'),
                _navItem(1, Icons.task_alt_rounded, 'Chores'),
                _navItem(2, Icons.calendar_month_rounded, 'Calendar'),
                _navItemBadge(3, Icons.approval_rounded, 'Approvals', pendingCount),
                _navItem(4, Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 22,
              color: selected ? AppTheme.accent : AppTheme.textTertiary),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppTheme.accent : AppTheme.textTertiary,
              )),
        ],
      ),
    );
  }

  Widget _navItemBadge(int index, IconData icon, String label, int count) {
    final selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon,
                  size: 22,
                  color: selected ? AppTheme.accent : AppTheme.textTertiary),
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppTheme.accent : AppTheme.textTertiary,
              )),
        ],
      ),
    );
  }
}
