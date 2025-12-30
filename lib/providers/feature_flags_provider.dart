import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feature_flags.dart';
import '../models/app_user.dart';
import 'app_providers.dart';

/// Provider für Feature-Flags (Lehrer-Berechtigungen)
/// 
/// Lädt Flags aus Firestore `/settings/features` und hört auf Änderungen.
/// Admin hat immer alle Rechte, für Lehrer gelten die konfigurierten Flags.
final featureFlagsProvider = StreamProvider<FeatureFlags>((ref) {
  final firestore = FirebaseFirestore.instance;
  
  return firestore
      .collection('settings')
      .doc('features')
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) {
      return const FeatureFlags(); // Sichere Defaults
    }
    final data = snapshot.data()?['lehrer'] as Map<String, dynamic>?;
    return FeatureFlags.fromFirestore(data);
  });
});

/// Effektive Flags für aktuellen User
/// 
/// Admin bekommt alle Rechte, Lehrer die konfigurierten Flags
final effectiveFeatureFlagsProvider = Provider<FeatureFlags>((ref) {
  final userAsync = ref.watch(currentAppUserProvider);
  final flagsAsync = ref.watch(featureFlagsProvider);
  
  // Extrahiere User (null wenn loading/error)
  final AppUser? user = userAsync.when(
    data: (u) => u,
    loading: () => null,
    error: (_, _) => null,
  );
  
  // Extrahiere Flags (sichere Defaults wenn loading/error)
  final flags = flagsAsync.when(
    data: (f) => f,
    loading: () => const FeatureFlags(),
    error: (_, _) => const FeatureFlags(),
  );
  
  // Admin hat immer alle Rechte
  if (user?.rolle == UserRole.admin) {
    return const FeatureFlags.admin();
  }
  
  // Lehrer bekommen konfigurierte Flags
  return flags;
});

/// State für Feature-Flag Updates
class FeatureFlagsUpdateState {
  final bool isLoading;
  final String? error;
  
  const FeatureFlagsUpdateState({this.isLoading = false, this.error});
  
  FeatureFlagsUpdateState copyWith({bool? isLoading, String? error}) {
    return FeatureFlagsUpdateState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier für Feature-Flag Updates (nur Admin)
class FeatureFlagsNotifier extends Notifier<FeatureFlagsUpdateState> {
  @override
  FeatureFlagsUpdateState build() => const FeatureFlagsUpdateState();
  
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  /// Einzelnes Flag aktualisieren
  Future<void> updateFlag(String key, bool value) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _firestore.collection('settings').doc('features').set({
        'lehrer': {key: value},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  /// Alle Flags aktualisieren
  Future<void> updateAllFlags(FeatureFlags flags) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _firestore.collection('settings').doc('features').set({
        'lehrer': flags.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  /// Flags auf Defaults zurücksetzen
  Future<void> resetToDefaults() async {
    await updateAllFlags(const FeatureFlags());
  }
}

/// Provider für Flag-Updates
final featureFlagsNotifierProvider = 
    NotifierProvider<FeatureFlagsNotifier, FeatureFlagsUpdateState>(
  FeatureFlagsNotifier.new,
);

// ============ GRANULARE PERMISSION PROVIDERS ============
// Diese Provider werden in Screens verwendet für UI-Visibility

/// CSV Import erlaubt?
final canImportCSVProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canImportCSV;
});

/// Schüler erstellen erlaubt?
final canCreateSchuelerProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canCreateSchueler;
});

/// Schüler bearbeiten erlaubt?
final canEditSchuelerProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canEditSchueler;
});

/// Schüler löschen erlaubt?
final canDeleteSchuelerProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canDeleteSchueler;
});

/// Fächer erstellen erlaubt?
final canCreateFaecherProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canCreateFaecher;
});

/// Fächer bearbeiten erlaubt?
final canEditFaecherProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canEditFaecher;
});

/// Fächer löschen erlaubt?
final canDeleteFaecherProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canDeleteFaecher;
});

/// Klassen erstellen erlaubt?
final canCreateKlassenProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canCreateKlassen;
});

/// Klassen bearbeiten erlaubt?
final canEditKlassenProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canEditKlassen;
});

/// Klassen löschen erlaubt?
final canDeleteKlassenProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canDeleteKlassen;
});

/// Leistungsnachweise erstellen erlaubt?
final canCreateLNProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canCreateLeistungsnachweise;
});

/// Leistungsnachweise bearbeiten erlaubt?
final canEditLNProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canEditLeistungsnachweise;
});

/// Leistungsnachweise löschen erlaubt?
final canDeleteLNProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canDeleteLeistungsnachweise;
});

/// Favoriten umschalten erlaubt?
final canToggleFavoritesProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canToggleFavorites;
});

/// PDF Export erlaubt?
final canExportPDFProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canExportPDF;
});

/// Excel Export erlaubt?
final canExportExcelProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canExportExcel;
});

/// NOI Export erlaubt?
final canExportNOIProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canExportNOI;
});
