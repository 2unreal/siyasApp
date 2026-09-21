import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_logo.dart';
import '../../core/theme/app_colors.dart';

class ResponsiveShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ResponsiveShell({super.key, required this.navigationShell});

  @override
  ConsumerState<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends ConsumerState<ResponsiveShell> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isWide = MediaQuery.of(context).size.width >= 800;

    // Navigation items filtered strictly by RBAC:
    // Classes, Reports, and Settings are hidden from Managers!
    final navItems = [
      const NavigationItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', routeIndex: 0),
      const NavigationItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Customers', routeIndex: 1),
      const NavigationItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders', routeIndex: 2),
      const NavigationItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Payments', routeIndex: 3),
      const NavigationItem(icon: Icons.checkroom_outlined, activeIcon: Icons.checkroom, label: 'Rentals', routeIndex: 4),
      const NavigationItem(icon: Icons.straighten_outlined, activeIcon: Icons.straighten, label: 'Alterations', routeIndex: 5),
      if (authState.isOwner) ...[
        const NavigationItem(icon: Icons.school_outlined, activeIcon: Icons.school, label: 'Classes', routeIndex: 6),
        const NavigationItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Reports', routeIndex: 7),
        const NavigationItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', routeIndex: 8),
      ],
    ];

    if (isWide) {
      // Tablet and Web Navigation Rail / Sidebar with SingleChildScrollView to prevent overflow
      return Scaffold(
        body: Row(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: widget.navigationShell.currentIndex.clamp(0, navItems.length - 1),
                        onDestinationSelected: (index) {
                          if (index < navItems.length) {
                            widget.navigationShell.goBranch(navItems[index].routeIndex);
                          }
                        },
                        leading: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: AppLogo(
                            size: 40,
                            showWordmark: false,
                            monogramColor: AppColors.goldAccent,
                            textColor: AppColors.primaryWine,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        selectedIconTheme: const IconThemeData(color: AppColors.primaryWine),
                        selectedLabelTextStyle: const TextStyle(
                          color: AppColors.primaryWine,
                          fontWeight: FontWeight.bold,
                        ),
                        labelType: NavigationRailLabelType.all,
                        destinations: navItems
                            .map(
                              (item) => NavigationRailDestination(
                                icon: Icon(item.icon),
                                selectedIcon: Icon(item.activeIcon),
                                label: Text(item.label),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
            const VerticalDivider(thickness: 1, width: 1, color: AppColors.borderSubtle),
            Expanded(child: widget.navigationShell),
          ],
        ),
      );
    }

    // Mobile Bottom Navigation Bar with More sheet for extended authorized hubs
    final bool hasMore = navItems.length > 5;
    final List<NavigationItem> primaryMobileItems = hasMore ? navItems.take(4).toList() : navItems;
    final List<NavigationItem> moreItems = hasMore ? navItems.skip(4).toList() : const [];

    final bool isMoreActive = hasMore && moreItems.any((item) => item.routeIndex == widget.navigationShell.currentIndex);
    final int primaryIndex = primaryMobileItems.indexWhere(
      (item) => item.routeIndex == widget.navigationShell.currentIndex,
    );
    final int bottomBarIndex = isMoreActive
        ? 4
        : (primaryIndex >= 0 ? primaryIndex : 0);

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomBarIndex,
        onTap: (index) {
          if (hasMore && index == 4) {
            _showMoreNavSheet(context, moreItems);
          } else {
            widget.navigationShell.goBranch(primaryMobileItems[index].routeIndex);
          }
        },
        items: [
          ...primaryMobileItems.map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon),
              label: item.label,
            ),
          ),
          if (hasMore)
            const BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'More',
            ),
        ],
      ),
    );
  }

  void _showMoreNavSheet(BuildContext context, List<NavigationItem> items) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.ivoryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ...items.map(
                  (item) => ListTile(
                    leading: Icon(
                      widget.navigationShell.currentIndex == item.routeIndex
                          ? item.activeIcon
                          : item.icon,
                      color: widget.navigationShell.currentIndex == item.routeIndex
                          ? AppColors.primaryWine
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: widget.navigationShell.currentIndex == item.routeIndex
                            ? AppColors.primaryWine
                            : AppColors.textPrimary,
                        fontWeight: widget.navigationShell.currentIndex == item.routeIndex
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      widget.navigationShell.goBranch(item.routeIndex);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int routeIndex;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.routeIndex,
  });
}
