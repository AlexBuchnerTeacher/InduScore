import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/rbs_theme.dart';
import '../providers/app_providers.dart';

class RBSDrawer extends ConsumerWidget {
  const RBSDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userEmail = currentUser?.email ?? '';

    return Drawer(
      child: Column(
        children: [
          // Header mit RBS Dynamic Red
          DrawerHeader(
            decoration: const BoxDecoration(color: RBSColors.dynamicRed),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.school, size: 48, color: RBSColors.white),
                const SizedBox(height: RBSSpacing.sm),
                Text(
                  'Notentool',
                  style: RBSTypography.h2.copyWith(color: RBSColors.white),
                ),
                const SizedBox(height: RBSSpacing.xs),
                Text(
                  userEmail,
                  style: RBSTypography.bodySmall.copyWith(
                    color: RBSColors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home_outlined,
                  title: 'Dashboard',
                  route: '/',
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.school_outlined,
                  title: 'Klassen',
                  route: '/klassen',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Schüler',
                  route: '/schueler',
                  disabled: true,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.book_outlined,
                  title: 'Fächer',
                  route: '/faecher',
                  disabled: true,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.assignment_outlined,
                  title: 'Noten',
                  route: '/noten',
                  disabled: true,
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'Statistiken',
                  route: '/statistiken',
                  disabled: true,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Einstellungen',
                  route: '/einstellungen',
                  disabled: true,
                ),
              ],
            ),
          ),

          // Logout am Ende
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_outlined),
            title: const Text('Abmelden'),
            onTap: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
          const SizedBox(height: RBSSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool disabled = false,
  }) {
    final isCurrentRoute = GoRouterState.of(context).uri.path == route;

    return ListTile(
      leading: Icon(
        icon,
        color: disabled
            ? RBSColors.textOnLight.withValues(alpha: 0.3)
            : (isCurrentRoute ? RBSColors.dynamicRed : null),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: disabled
              ? RBSColors.textOnLight.withValues(alpha: 0.3)
              : (isCurrentRoute ? RBSColors.dynamicRed : null),
          fontWeight: isCurrentRoute ? FontWeight.bold : null,
        ),
      ),
      selected: isCurrentRoute,
      selectedTileColor: RBSColors.redLight,
      enabled: !disabled,
      onTap: disabled
          ? null
          : () {
              Navigator.pop(context); // Drawer schließen
              context.go(route);
            },
    );
  }
}
