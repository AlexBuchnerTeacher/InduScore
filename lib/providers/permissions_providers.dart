import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:induscore/models/app_user.dart';
import 'package:induscore/providers/app_providers.dart';
import 'package:induscore/models/leistungsnachweis.dart';

/// **Benutzerverwaltung** (Issue #39)
///
/// Admin: Voller Zugriff auf Benutzerverwaltung
/// Lehrer/Ausbilder: Kein Zugriff
final canManageUsersProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentAppUserProvider);
  return currentUser.maybeWhen(
    data: (user) => user?.rolle == UserRole.admin,
    orElse: () => false,
  );
});

/// **Stammdaten-Verwaltung** (Issue #39)
///
/// Admin: Alle Klassen, Fächer, Schüler bearbeiten
/// Lehrer: Nur favorisierte Klassen und deren Schüler/Fächer
/// Ausbilder: Reserviert für separate App (aktuell wie Lehrer)
final canManageDataProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentAppUserProvider);
  return currentUser.maybeWhen(
    data: (user) => user != null && 
                    (user.rolle == UserRole.admin || 
                     user.rolle == UserRole.lehrer ||
                     user.rolle == UserRole.ausbilder),
    orElse: () => false,
  );
});

/// **Leistungsnachweis bearbeiten** (Issue #39)
///
/// Admin: Alle Leistungsnachweise
/// Lehrer/Ausbilder: Nur eigene (createdBy == current user)
final canEditLeistungsnachweisProvider = Provider.family<bool, Leistungsnachweis>(
  (ref, leistungsnachweis) {
    final currentUser = ref.watch(currentAppUserProvider);
    return currentUser.maybeWhen(
      data: (user) {
        if (user == null) return false;
        
        // Admin kann alles
        if (user.rolle == UserRole.admin) return true;
        
        // Lehrer/Ausbilder: Nur eigene
        if (user.rolle == UserRole.lehrer || user.rolle == UserRole.ausbilder) {
          return leistungsnachweis.createdBy == user.id;
        }
        
        return false;
      },
      orElse: () => false,
    );
  },
);

/// **Leistungsnachweis erstellen** (Issue #39)
///
/// Admin, Lehrer, Ausbilder: Ja
final canCreateLeistungsnachweisProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentAppUserProvider);
  return currentUser.maybeWhen(
    data: (user) => user != null && 
                    (user.rolle == UserRole.admin || 
                     user.rolle == UserRole.lehrer ||
                     user.rolle == UserRole.ausbilder),
    orElse: () => false,
  );
});

/// **CSV Import** (Issue #39)
///
/// Admin: Ja
/// Andere: Nein
final canImportCSVProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentAppUserProvider);
  return currentUser.maybeWhen(
    data: (user) => user?.rolle == UserRole.admin,
    orElse: () => false,
  );
});

/// **Stammdaten erstellen** (Issue #39)
///
/// Nur Admin darf neue Klassen, Fächer, Schüler erstellen
/// Lehrer/Ausbilder können nur bestehende Daten bearbeiten
final canCreateDataProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentAppUserProvider);
  return currentUser.maybeWhen(
    data: (user) => user?.rolle == UserRole.admin,
    orElse: () => false,
  );
});
