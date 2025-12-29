import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/rbs_theme.dart';
import '../core/widgets/rbs_components.dart';
import '../providers/app_providers.dart';
import '../providers/permissions_providers.dart';

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
                  'InduScore',
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

          // Zeitgruppen Filter
          _buildZeitgruppenFilter(ref),

          // Navigation Items
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final canManageData = ref.watch(canManageDataProvider);
                final canImportCSV = ref.watch(canImportCSVProvider);
                final canManageUsers = ref.watch(canManageUsersProvider);
                
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.home_outlined,
                      title: 'Dashboard',
                      route: '/',
                    ),
                    const Divider(),
                    // Datenverwaltung (Admin + Lehrer + Ausbilder)
                    if (canManageData) ...[
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
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.book_outlined,
                        title: 'Fächer',
                        route: '/faecher',
                      ),
                    ],
                    _buildDrawerItem(
                      context,
                      icon: Icons.assignment_outlined,
                      title: 'Leistungsnachweise',
                      route: '/leistungsnachweise',
                    ),
                    const Divider(),
                    // CSV Import (nur Admin)
                    if (canImportCSV)
                      _buildDrawerItem(
                        context,
                        icon: Icons.upload_file_outlined,
                        title: 'CSV Import',
                        route: '/import',
                      ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.download_outlined,
                      title: 'Daten Export',
                      route: '/export',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.analytics_outlined,
                      title: 'Statistiken',
                      route: '/statistiken',
                      disabled: true,
                    ),
                    const Divider(),
                    // Einstellungen (Berufe & Fächer)
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Einstellungen',
                      route: '/einstellungen',
                    ),
                    // Benutzerverwaltung (nur Admin)
                    if (canManageUsers)
                      _buildDrawerItem(
                        context,
                        icon: Icons.people_outlined,
                        title: 'Benutzerverwaltung',
                        route: '/einstellungen/benutzer',
                      ),
                  ],
                );
              },
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
          Padding(
            padding: const EdgeInsets.only(
              left: RBSSpacing.lg,
              right: RBSSpacing.lg,
              bottom: RBSSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Consumer(
                builder: (context, ref, _) {
                  final versionAsync = ref.watch(appVersionProvider);
                  return Text(
                    'Version ${versionAsync.when(
                      data: (v) => v,
                      loading: () => '...',
                      error: (e, _) => '?',
                    )}',
                    style: RBSTypography.bodySmall.copyWith(
                      color: RBSColors.textOnLight.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ),
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

  Widget _buildZeitgruppenFilter(WidgetRef ref) {
    final selectedZG = ref.watch(zeitgruppenFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RBSSpacing.md,
        vertical: RBSSpacing.sm,
      ),
      color: RBSColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zeitgruppe',
            style: RBSTypography.bodySmall.copyWith(
              color: RBSColors.textOnLight.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: RBSSpacing.xs),
          Wrap(
            spacing: 8,
            children: [
              RBSFilterChip(
                label: 'ZG1',
                selected: selectedZG.contains(1),
                color: RBSColors.courtGreen,
                onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(1),
              ),
              RBSFilterChip(
                label: 'ZG2',
                selected: selectedZG.contains(2),
                color: RBSColors.courtGreen,
                onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(2),
              ),
              RBSFilterChip(
                label: 'ZG3',
                selected: selectedZG.contains(3),
                color: RBSColors.courtGreen,
                onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
