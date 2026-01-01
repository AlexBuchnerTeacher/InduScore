import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/core/widgets/rbs_components.dart';
import 'package:induscore/widgets/rbs_drawer.dart';
import 'package:induscore/models/app_user.dart';
import 'package:induscore/providers/app_providers.dart';
import 'package:induscore/providers/permissions_providers.dart';
import 'package:induscore/widgets/dialogs/common_dialogs.dart';
import 'package:induscore/shared/widgets/app_snack_bars.dart';

/// Benutzerverwaltung - nur für Admins
class UserVerwaltungScreen extends ConsumerStatefulWidget {
  const UserVerwaltungScreen({super.key});

  @override
  ConsumerState<UserVerwaltungScreen> createState() => _UserVerwaltungScreenState();
}

class _UserVerwaltungScreenState extends ConsumerState<UserVerwaltungScreen> {
  String _searchQuery = '';
  UserRole? _filterRole;
  UserStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final canManage = ref.watch(canManageUsersProvider);
    final usersAsync = ref.watch(appUsersProvider);

    // Nur Admins dürfen diese Seite sehen
    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Benutzerverwaltung')),
        drawer: const RBSDrawer(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Zugriff verweigert',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Nur Administratoren können Benutzer verwalten.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benutzerverwaltung'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: 'Zum Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showUserDialog(context),
            tooltip: 'Neuer Benutzer',
          ),
        ],
      ),
      drawer: const RBSDrawer(),
      body: Column(
        children: [
          // Such- und Filterleiste
          Container(
            padding: const EdgeInsets.all(RBSSpacing.md),
            color: RBSColors.paper,
            child: Column(
              children: [
                // Suchfeld
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Suchen nach Name, Email oder Kürzel...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: RBSSpacing.sm),
                // Filter-Chips
                Row(
                  children: [
                    // Rollen-Filter
                    ...UserRole.values.map((role) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(role.label),
                        selected: _filterRole == role,
                        onSelected: (selected) {
                          setState(() => _filterRole = selected ? role : null);
                        },
                      ),
                    )),
                    const SizedBox(width: 16),
                    // Status-Filter
                    ...UserStatus.values.map((status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status.label),
                        selected: _filterStatus == status,
                        selectedColor: status == UserStatus.aktiv 
                            ? Colors.green.shade100 
                            : Colors.red.shade100,
                        onSelected: (selected) {
                          setState(() => _filterStatus = selected ? status : null);
                        },
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),

          // Benutzerliste
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Fehler: $e')),
              data: (users) {
                // Filter anwenden
                final filtered = users.where((u) {
                  // Suchfilter
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    if (!u.name.toLowerCase().contains(query) &&
                        !u.email.toLowerCase().contains(query) &&
                        !u.kuerzel.toLowerCase().contains(query)) {
                      return false;
                    }
                  }
                  // Rollen-Filter
                  if (_filterRole != null && u.rolle != _filterRole) {
                    return false;
                  }
                  // Status-Filter
                  if (_filterStatus != null && u.status != _filterStatus) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          users.isEmpty ? 'Keine Benutzer vorhanden' : 'Keine Treffer',
                          style: RBSTypography.h4,
                        ),
                        const SizedBox(height: 8),
                        RBSButton(
                          label: 'Benutzer anlegen',
                          icon: Icons.person_add,
                          onPressed: () => _showUserDialog(context),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(RBSSpacing.md),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return _buildUserCard(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    final isDeaktiviert = user.status == UserStatus.deaktiviert;
    
    return Card(
      margin: const EdgeInsets.only(bottom: RBSSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isAdmin 
              ? RBSColors.dynamicRed 
              : RBSColors.courtGreen,
          child: Text(
            user.kuerzel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDeaktiviert ? Colors.grey : null,
                  decoration: isDeaktiviert ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            // Rollen-Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: user.isAdmin 
                    ? RBSColors.dynamicRed.withValues(alpha: 0.1)
                    : RBSColors.courtGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.rolle.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: user.isAdmin ? RBSColors.dynamicRed : RBSColors.courtGreen,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            if (user.lastLoginAt != null)
              Text(
                'Letzter Login: ${_formatDateTime(user.lastLoginAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleUserAction(action, user),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Bearbeiten'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'reset_password',
              child: ListTile(
                leading: Icon(Icons.lock_reset),
                title: Text('Passwort zurücksetzen'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: isDeaktiviert ? 'activate' : 'deactivate',
              child: ListTile(
                leading: Icon(isDeaktiviert ? Icons.check_circle : Icons.block),
                title: Text(isDeaktiviert ? 'Aktivieren' : 'Deaktivieren'),
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Löschen', style: TextStyle(color: Colors.red)),
                dense: true,
              ),
            ),
          ],
        ),
        onTap: () => _showUserDialog(context, user: user),
      ),
    );
  }

  void _handleUserAction(String action, AppUser user) async {
    final firestoreService = ref.read(firestoreServiceProvider);

    switch (action) {
      case 'edit':
        _showUserDialog(context, user: user);
        break;
      case 'reset_password':
        _showResetPasswordDialog(user);
        break;
      case 'activate':
        await firestoreService.activateAppUser(user.id);
        if (mounted) {
          AppSnackBars.showSuccess(context, '${user.name} aktiviert');
        }
        break;
      case 'deactivate':
        await firestoreService.deactivateAppUser(user.id);
        if (mounted) {
          AppSnackBars.showInfo(context, '${user.name} deaktiviert');
        }
        break;
      case 'delete':
        _showDeleteConfirmation(user);
        break;
    }
  }

  void _showUserDialog(BuildContext context, {AppUser? user}) {
    final isEdit = user != null;
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final kuerzelController = TextEditingController(text: user?.kuerzel ?? '');
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    UserRole selectedRole = user?.rolle ?? UserRole.lehrer;
    final List<String> selectedKlassenIds = List.from(user?.favoriteKlassenIds ?? []);
    String? kuerzelError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => RBSDialog(
          title: isEdit ? 'Benutzer bearbeiten' : 'Neuer Benutzer',
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'z.B. Max Mustermann',
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Name erforderlich' : null,
                ),
                const SizedBox(height: RBSSpacing.md),
                
                // Email (immer editierbar)
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    hintText: 'z.B. mustermann@schule.de',
                    helperText: isEdit 
                        ? '⚠️ Email-Änderung erfordert Login-Update!' 
                        : null,
                    helperStyle: const TextStyle(color: RBSColors.dynamicRed),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Email erforderlich';
                    if (!v!.contains('@')) return 'Ungültige Email';
                    return null;
                  },
                ),
                const SizedBox(height: RBSSpacing.md),
                
                // Kürzel
                TextFormField(
                  controller: kuerzelController,
                  decoration: InputDecoration(
                    labelText: 'Kürzel *',
                    hintText: 'z.B. MU',
                    errorText: kuerzelError,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 4,
                  validator: (v) => v?.isEmpty ?? true ? 'Kürzel erforderlich' : null,
                  onChanged: (v) async {
                    if (v.length >= 2) {
                      final firestoreService = ref.read(firestoreServiceProvider);
                      final taken = await firestoreService.isKuerzelTaken(
                        v, 
                        excludeUserId: user?.id,
                      );
                      setDialogState(() {
                        kuerzelError = taken ? 'Kürzel bereits vergeben' : null;
                      });
                    }
                  },
                ),
                const SizedBox(height: RBSSpacing.md),
                
                // Rolle
                const Text('Rolle *', style: RBSTypography.label),
                const SizedBox(height: RBSSpacing.xs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: UserRole.values.map((role) => ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          role == UserRole.admin 
                              ? Icons.admin_panel_settings 
                              : role == UserRole.schueler
                                  ? Icons.school
                                  : Icons.person,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(role.label),
                      ],
                    ),
                    selected: selectedRole == role,
                    onSelected: (selected) {
                      if (selected) setDialogState(() => selectedRole = role);
                    },
                  )).toList(),
                ),
                const SizedBox(height: RBSSpacing.md),
                
                // Favoriten-Klassen (nur für Lehrer/Ausbilder)
                if (selectedRole == UserRole.lehrer || selectedRole == UserRole.ausbilder) ...[
                  const Text('Favoriten-Klassen (optional)', style: RBSTypography.label),
                  const SizedBox(height: RBSSpacing.xs),
                  Consumer(builder: (context, ref, _) {
                    final klassenAsync = ref.watch(klassenProvider);
                    return klassenAsync.when(
                      data: (klassen) {
                        if (klassen.isEmpty) {
                          return const Text('Keine Klassen vorhanden', 
                                     style: RBSTypography.bodySmall);
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: klassen.map((klasse) => FilterChip(
                            label: Text(klasse.name),
                            selected: selectedKlassenIds.contains(klasse.id),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedKlassenIds.add(klasse.id);
                                } else {
                                  selectedKlassenIds.remove(klasse.id);
                                }
                              });
                            },
                          )).toList(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Fehler: $e'),
                    );
                  }),
                  const SizedBox(height: RBSSpacing.md),
                ],
                
                // Passwort (nur bei Neuanlage)
                if (!isEdit) ...[
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Passwort *',
                      hintText: 'Mindestens 6 Zeichen',
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Passwort erforderlich';
                      if (v!.length < 6) return 'Mindestens 6 Zeichen';
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: kuerzelError != null ? null : () async {
                if (formKey.currentState?.validate() ?? false) {
                  await _saveUser(
                    context,
                    user: user,
                    name: nameController.text.trim(),
                    email: emailController.text.trim().toLowerCase(),
                    kuerzel: kuerzelController.text.trim().toUpperCase(),
                    rolle: selectedRole,
                    favoriteKlassenIds: selectedKlassenIds,
                    password: isEdit ? null : passwordController.text,
                  );
                }
              },
              child: Text(isEdit ? 'Speichern' : 'Anlegen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUser(
    BuildContext context, {
    required String name, required String email, required String kuerzel, required UserRole rolle, required List<String> favoriteKlassenIds, AppUser? user,
    String? password,
  }) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final authService = ref.read(authServiceProvider);
    
    try {
      if (user != null) {
        // Bearbeiten
        final updated = user.copyWith(
          name: name,
          email: email, // Email ist jetzt editierbar
          kuerzel: kuerzel,
          rolle: rolle,
          favoriteKlassenIds: favoriteKlassenIds,
        );
        await firestoreService.updateAppUser(updated);
        
        // Invalidiere Provider um Änderungen zu propagieren
        ref.invalidate(appUsersProvider);
        ref.invalidate(currentAppUserProvider);
      } else {
        // Neu anlegen - erst Firebase Auth User erstellen
        final userCredential = await authService.createUserWithEmailAndPassword(
          email, 
          password!,
        );
        
        // Dann AppUser in Firestore anlegen
        final newUser = AppUser(
          id: userCredential.user!.uid,
          email: email,
          name: name,
          kuerzel: kuerzel,
          rolle: rolle,
          favoriteKlassenIds: favoriteKlassenIds,
          createdAt: DateTime.now(),
        );
        await firestoreService.createAppUserWithId(userCredential.user!.uid, newUser);
        
        // Invalidiere Provider um neue User zu laden
        ref.invalidate(appUsersProvider);
      }

      if (context.mounted) {
        Navigator.pop(context);
        AppSnackBars.showSuccess(
          context,
          user != null ? 'Benutzer aktualisiert' : 'Benutzer angelegt',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBars.showError(context, 'Fehler', error: e);
      }
    }
  }

  void _showResetPasswordDialog(AppUser user) {
    final messenger = ScaffoldMessenger.of(context);
    
    CommonDialogs.showConfirmationDialog(
      context: context,
      title: 'Passwort zurücksetzen',
      message: 'Eine E-Mail zum Zurücksetzen des Passworts wird an ${user.email} gesendet.',
      confirmText: 'Email senden',
      onConfirm: () async {
        final authService = ref.read(authServiceProvider);
        try {
          await authService.sendPasswordResetEmail(user.email);
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text('Passwort-Reset Email an ${user.email} gesendet')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
            );
          }
        }
      },
    );
  }

  void _showDeleteConfirmation(AppUser user) {
    final messenger = ScaffoldMessenger.of(context);
    
    CommonDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Benutzer löschen?',
      itemName: '${user.name} (${user.email})',
      onDelete: () async {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.deleteAppUser(user.id);
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('${user.name} gelöscht')),
          );
        }
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
