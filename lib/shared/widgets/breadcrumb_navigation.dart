import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/rbs_theme.dart';

/// Ein Breadcrumb-Element
class BreadcrumbItem {
  final String label;
  final String? route;
  final IconData? icon;

  const BreadcrumbItem({
    required this.label,
    this.route,
    this.icon,
  });
}

/// v0.33.0: Breadcrumb-Navigation für Detail-Screens
/// 
/// Zeigt Navigationspfad: Home > Klassen > 12IT1 > Max Mustermann
/// 
/// Usage:
/// ```dart
/// BreadcrumbNavigation(
///   items: [
///     BreadcrumbItem(label: 'Home', route: '/', icon: Icons.home),
///     BreadcrumbItem(label: 'Klassen', route: '/klassen'),
///     BreadcrumbItem(label: '12IT1', route: '/klassen/abc123'),
///     BreadcrumbItem(label: 'Max Mustermann'),  // Aktuell, kein Route
///   ],
/// )
/// ```
class BreadcrumbNavigation extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final double height;

  const BreadcrumbNavigation({
    required this.items,
    super.key,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: RBSColors.paper,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) _buildSeparator(),
            _buildItem(context, items[i], isLast: i == items.length - 1),
          ],
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        Icons.chevron_right,
        size: 16,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildItem(BuildContext context, BreadcrumbItem item, {required bool isLast}) {
    final textStyle = TextStyle(
      fontSize: 13,
      color: isLast ? RBSColors.dynamicRed : Colors.grey[700],
      fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
    );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: 14,
            color: isLast ? RBSColors.dynamicRed : Colors.grey[600],
          ),
          const SizedBox(width: 4),
        ],
        Text(
          item.label,
          style: textStyle,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    // Letztes Element (aktuell) ist nicht klickbar
    if (isLast || item.route == null) {
      return child;
    }

    return InkWell(
      onTap: () => context.go(item.route!),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: child,
      ),
    );
  }
}
