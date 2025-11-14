import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../utils/expression_evaluator.dart';

/// Configuration for a navigation tab group.
class TabGroupConfig {
  final String id;
  final String label;
  final IconData? icon;
  final List<String> pageIds;

  const TabGroupConfig({
    required this.id,
    required this.label,
    this.icon,
    required this.pageIds,
  });

  factory TabGroupConfig.fromMap(Map<String, dynamic> map) {
    return TabGroupConfig(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      icon: _getIconData(map['icon'] as String?),
      pageIds: (map['pages'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  static IconData? _getIconData(String? iconName) {
    if (iconName == null) return null;

    const iconMap = {
      'home': Icons.home,
      'dashboard': Icons.dashboard,
      'admin': Icons.admin_panel_settings,
      'settings': Icons.settings,
      'people': Icons.people,
      'inventory': Icons.inventory,
      'analytics': Icons.analytics,
      'business': Icons.business,
    };

    return iconMap[iconName];
  }
}

/// A tabbed navigation widget for grouping pages into tabs.
///
/// Displays tabs at the top or bottom and shows the pages grouped under each tab.
///
/// Example YAML configuration:
/// ```yaml
/// navigation:
///   tabs:
///     enabled: true
///     position: "top"  # or "bottom"
///     groups:
///       - id: "main"
///         label: "Main"
///         icon: "home"
///         pages: ["dashboard", "orders"]
///       - id: "admin"
///         label: "Admin"
///         icon: "admin"
///         pages: ["admin_dashboard", "users"]
/// ```
class TabbedNavigationWidget extends StatefulWidget {
  final List<TabGroupConfig> tabGroups;
  final TabBarPosition position;
  final Function(String pageId) onPageSelected;
  final String? initialPageId;

  const TabbedNavigationWidget({
    super.key,
    required this.tabGroups,
    this.position = TabBarPosition.top,
    required this.onPageSelected,
    this.initialPageId,
  });

  @override
  State<TabbedNavigationWidget> createState() =>
      _TabbedNavigationWidgetState();
}

class _TabbedNavigationWidgetState extends State<TabbedNavigationWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _initialTabIndex = 0;

  @override
  void initState() {
    super.initState();

    // Find initial tab index based on initialPageId
    if (widget.initialPageId != null) {
      for (int i = 0; i < widget.tabGroups.length; i++) {
        if (widget.tabGroups[i].pageIds.contains(widget.initialPageId)) {
          _initialTabIndex = i;
          break;
        }
      }
    }

    _tabController = TabController(
      length: widget.tabGroups.length,
      vsync: this,
      initialIndex: _initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabGroups.isEmpty) {
      return const Center(child: Text('No tab groups configured'));
    }

    return Column(
      children: [
        if (widget.position == TabBarPosition.top) _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.tabGroups
                .map((group) => _buildTabContent(group))
                .toList(),
          ),
        ),
        if (widget.position == TabBarPosition.bottom) _buildTabBar(),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: widget.tabGroups.map((group) {
        return Tab(
          icon: group.icon != null ? Icon(group.icon) : null,
          text: group.label,
        );
      }).toList(),
    );
  }

  Widget _buildTabContent(TabGroupConfig group) {
    final appConfig = context.read<AppConfig>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user!;

    // Get pages for this tab group
    final pages = appConfig.pages.where((page) {
      // Check if page is in this group
      if (!group.pageIds.contains(page.id)) return false;

      // Check visibility
      if (page.menu == null || page.menu!.visible == false) {
        return false;
      }

      // Check role-based visibility
      return ExpressionEvaluator.evaluate(page.visibleIf, user);
    }).toList();

    if (pages.isEmpty) {
      return Center(
        child: Text('No pages available in ${group.label}'),
      );
    }

    return ListView(
      children: pages.map((page) {
        return ListTile(
          leading: page.menu?.icon != null
              ? Icon(_getIconData(page.menu!.icon!))
              : null,
          title: Text(page.menu?.label ?? page.title),
          subtitle:
              page.menu?.description != null ? Text(page.menu!.description!) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => widget.onPageSelected(page.id),
        );
      }).toList(),
    );
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'home': Icons.home,
      'inventory': Icons.inventory,
      'people': Icons.people,
      'admin_panel_settings': Icons.admin_panel_settings,
      'dashboard': Icons.dashboard,
      'settings': Icons.settings,
      'analytics': Icons.analytics,
      'shopping_cart': Icons.shopping_cart,
      'business': Icons.business,
    };

    return iconMap[iconName] ?? Icons.circle;
  }
}

/// Tab bar position enum.
enum TabBarPosition {
  top,
  bottom,
}

/// Extension to parse TabBarPosition from string.
extension TabBarPositionExtension on TabBarPosition {
  static TabBarPosition fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'bottom':
        return TabBarPosition.bottom;
      case 'top':
      default:
        return TabBarPosition.top;
    }
  }
}
