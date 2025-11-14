import 'package:flutter/material.dart';

/// Represents a single breadcrumb item in the navigation path.
class BreadcrumbItem {
  /// The label text to display
  final String label;

  /// Optional callback when the breadcrumb is tapped
  final VoidCallback? onTap;

  /// Optional icon to display before the label
  final IconData? icon;

  const BreadcrumbItem({
    required this.label,
    this.onTap,
    this.icon,
  });
}

/// A breadcrumb navigation widget showing the current navigation path.
///
/// Displays a series of breadcrumb items separated by a separator,
/// allowing users to see and navigate through the hierarchy.
///
/// Example:
/// ```dart
/// BreadcrumbWidget(
///   items: [
///     BreadcrumbItem(label: 'Home', onTap: () => goHome()),
///     BreadcrumbItem(label: 'Orders', onTap: () => goToOrders()),
///     BreadcrumbItem(label: 'Order #12345'), // Current page (no onTap)
///   ],
/// )
/// ```
class BreadcrumbWidget extends StatelessWidget {
  /// The list of breadcrumb items to display
  final List<BreadcrumbItem> items;

  /// The separator to display between items (default: '›')
  final String separator;

  /// The color for clickable breadcrumbs
  final Color? linkColor;

  /// The color for the current (last) breadcrumb
  final Color? currentColor;

  /// The text style for breadcrumbs
  final TextStyle? textStyle;

  /// Whether to show icons
  final bool showIcons;

  const BreadcrumbWidget({
    super.key,
    required this.items,
    this.separator = '›',
    this.linkColor,
    this.currentColor,
    this.textStyle,
    this.showIcons = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final defaultLinkColor = linkColor ?? theme.colorScheme.primary;
    final defaultCurrentColor = currentColor ?? theme.textTheme.bodyLarge?.color;
    final defaultTextStyle = textStyle ?? theme.textTheme.bodySmall;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _buildBreadcrumbItem(
            context,
            items[i],
            isLast: i == items.length - 1,
            linkColor: defaultLinkColor,
            currentColor: defaultCurrentColor,
            textStyle: defaultTextStyle,
          ),
          if (i < items.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                separator,
                style: defaultTextStyle?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildBreadcrumbItem(
    BuildContext context,
    BreadcrumbItem item, {
    required bool isLast,
    required Color linkColor,
    required Color? currentColor,
    required TextStyle? textStyle,
  }) {
    final isClickable = item.onTap != null && !isLast;
    final color = isLast ? currentColor : linkColor;
    final fontWeight = isLast ? FontWeight.bold : FontWeight.normal;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcons && item.icon != null) ...[
          Icon(
            item.icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          item.label,
          style: textStyle?.copyWith(
            color: color,
            fontWeight: fontWeight,
            decoration: isClickable ? TextDecoration.underline : null,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );

    if (isClickable) {
      return InkWell(
        onTap: item.onTap,
        child: content,
      );
    }

    return content;
  }
}

/// A compact breadcrumb widget that shows only the last N items.
///
/// Useful when the breadcrumb path becomes too long.
class CompactBreadcrumbWidget extends StatelessWidget {
  /// The list of breadcrumb items
  final List<BreadcrumbItem> items;

  /// Maximum number of items to show (default: 3)
  final int maxItems;

  /// The separator between items
  final String separator;

  /// Whether to show icons
  final bool showIcons;

  const CompactBreadcrumbWidget({
    super.key,
    required this.items,
    this.maxItems = 3,
    this.separator = '›',
    this.showIcons = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    List<BreadcrumbItem> displayItems;

    if (items.length <= maxItems) {
      displayItems = items;
    } else {
      // Show first item, ellipsis, and last (maxItems - 1) items
      displayItems = [
        items.first,
        const BreadcrumbItem(label: '...'),
        ...items.sublist(items.length - (maxItems - 1)),
      ];
    }

    return BreadcrumbWidget(
      items: displayItems,
      separator: separator,
      showIcons: showIcons,
    );
  }
}

/// Helper class to build breadcrumbs from route information.
class BreadcrumbBuilder {
  /// Build breadcrumbs from a route path.
  ///
  /// Example:
  /// ```dart
  /// final breadcrumbs = BreadcrumbBuilder.fromRoutePath(
  ///   '/page/orders/record/12345',
  ///   pageConfigs: config.pages,
  ///   onNavigate: (pageId, recordId) => navigateToPage(pageId, recordId),
  /// );
  /// ```
  static List<BreadcrumbItem> fromRoutePath(
    String path, {
    required List<dynamic> pageConfigs,
    Function(String pageId, String? recordId)? onNavigate,
  }) {
    final items = <BreadcrumbItem>[];

    // Always add home
    items.add(BreadcrumbItem(
      label: 'Home',
      icon: Icons.home,
      onTap: onNavigate != null ? () => onNavigate('', null) : null,
    ));

    // Parse path segments
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) return items;

    // Handle /page/:pageId/record/:recordId pattern
    if (segments.length >= 2 && segments[0] == 'page') {
      final pageId = segments[1];

      // Find page config
      final pageConfig = pageConfigs.firstWhere(
        (p) => (p as Map)['id'] == pageId,
        orElse: () => {'id': pageId, 'title': pageId},
      ) as Map;

      final pageTitle = pageConfig['title'] as String? ?? pageId;

      items.add(BreadcrumbItem(
        label: pageTitle,
        onTap: onNavigate != null ? () => onNavigate(pageId, null) : null,
      ));

      // Handle record
      if (segments.length >= 4 && segments[2] == 'record') {
        final recordId = segments[3];
        items.add(BreadcrumbItem(
          label: 'Record #$recordId',
        ));
      }
    }

    // Handle /admin
    if (segments.length == 1 && segments[0] == 'admin') {
      items.add(BreadcrumbItem(
        label: 'Admin Dashboard',
        icon: Icons.admin_panel_settings,
      ));
    }

    return items;
  }

  /// Build breadcrumbs from page ID and record ID.
  static List<BreadcrumbItem> fromPageAndRecord({
    required String pageId,
    String? recordId,
    required List<dynamic> pageConfigs,
    Function(String pageId, String? recordId)? onNavigate,
  }) {
    final items = <BreadcrumbItem>[];

    // Home
    items.add(BreadcrumbItem(
      label: 'Home',
      icon: Icons.home,
      onTap: onNavigate != null ? () => onNavigate('', null) : null,
    ));

    // Find page config
    final pageConfig = pageConfigs.firstWhere(
      (p) => (p as Map)['id'] == pageId,
      orElse: () => {'id': pageId, 'title': pageId},
    ) as Map;

    final pageTitle = pageConfig['title'] as String? ?? pageId;

    items.add(BreadcrumbItem(
      label: pageTitle,
      onTap: recordId != null && onNavigate != null
          ? () => onNavigate(pageId, null)
          : null,
    ));

    // Add record if present
    if (recordId != null) {
      items.add(BreadcrumbItem(
        label: 'Record #$recordId',
      ));
    }

    return items;
  }
}
