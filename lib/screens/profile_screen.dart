import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/rbs_theme.dart';
import '../core/widgets/rbs_components.dart';
import '../providers/app_providers.dart';
import '../widgets/profile/profile_info_section.dart';
import '../widgets/profile/password_change_dialog.dart';
import '../widgets/profile/favorites_manager.dart';
import 'package:intl/intl.dart';

/// User-Profilscreen für persönliche Einstellungen
/// Getrennt von Admin Einstellungen - für ALLE User-Rollen verfügbar
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(currentAppUserProvider);

    return Scaffold(
      backgroundColor: RBSColors.paper,
      appBar: AppBar(
        backgroundColor: RBSColors.dynamicRed,
        foregroundColor: RBSColors.white,
        title: const Text(
          'Mein Profil',
          style: TextStyle(
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: RBSColors.white,
          unselectedLabelColor: RBSColors.white.withValues(alpha: 0.7),
          indicatorColor: RBSColors.white,
          tabs: const [
            Tab(text: 'Profil'),
            Tab(text: 'Sicherheit'),
            Tab(text: 'Favoriten'),
          ],
        ),
      ),
      body: appUserAsync.when(
        data: (appUser) {
          if (appUser == null) {
            return const Center(
              child: Text(
                'Benutzer nicht gefunden',
                style: TextStyle(fontFamily: 'OpenSans', color: Colors.grey),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _ProfileTab(user: appUser),
              const _SecurityTab(),
              _FavoritesTab(user: appUser),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Fehler: $error',
            style: const TextStyle(color: RBSColors.error),
          ),
        ),
      ),
    );
  }
}

/// Tab 1 - Profil (Readonly User-Info)
class _ProfileTab extends StatelessWidget {
  final dynamic user; // AppUser

  const _ProfileTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(RBSSpacing.md),
      child: ProfileInfoSection(user: user),
    );
  }
}

/// Tab 2 - Sicherheit (Passwort ändern)
class _SecurityTab extends ConsumerWidget {
  const _SecurityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(currentAppUserProvider);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(RBSSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passwort-Bereich
          RBSCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RBSHeadline(text: 'Passwort', level: RBSHeadlineLevel.h3),
                const SizedBox(height: RBSSpacing.sm),
                const Text(
                  'Ändern Sie Ihr Passwort, um die Sicherheit Ihres Accounts zu gewährleisten.',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: RBSSpacing.md),
                RBSButton(
                  label: 'Passwort ändern',
                  icon: Icons.lock_outlined,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => PasswordChangeDialog(
                        authService: ref.read(authServiceProvider),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: RBSSpacing.md),

          // Login-Info
          appUserAsync.when(
            data: (appUser) {
              if (appUser == null || appUser.lastLoginAt == null) {
                return const SizedBox.shrink();
              }

              return RBSCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RBSHeadline(
                      text: 'Login-Informationen',
                      level: RBSHeadlineLevel.h3,
                    ),
                    const SizedBox(height: RBSSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Letzter Login',
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          dateFormat.format(appUser.lastLoginAt!),
                          style: const TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Tab 3 - Favoriten (Favoriten-Klassen verwalten)
class _FavoritesTab extends StatelessWidget {
  final dynamic user; // AppUser

  const _FavoritesTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(RBSSpacing.md),
      child: FavoritesManager(
        userId: user.id,
        currentFavorites: user.favoriteKlassenIds,
      ),
    );
  }
}
