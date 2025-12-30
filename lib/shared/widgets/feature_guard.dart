import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/feature_flags.dart';
import '../../providers/feature_flags_provider.dart';
import '../../providers/app_providers.dart';

/// Widget für bedingte Sichtbarkeit basierend auf Feature-Flags
/// 
/// Zeigt [child] nur wenn [check] true zurückgibt, sonst nichts.
/// Admin-User haben immer Zugriff (alle Features sichtbar).
/// 
/// Beispiel:
/// ```dart
/// FeatureVisible(
///   check: (flags) => flags.canAccessNoten,
///   child: ListTile(title: Text('Noten')),
/// )
/// ```
class FeatureVisible extends ConsumerWidget {
  final bool Function(FeatureFlags) check;
  final Widget child;

  const FeatureVisible({
    required this.check,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(featureFlagsProvider);
    final isAdmin = ref.watch(isCurrentUserAdminProvider);
    
    // Admin hat immer Zugriff
    if (isAdmin) return child;
    
    return flagsAsync.when(
      data: (flags) => check(flags) ? child : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => child, // Fail-open bei Fehlern
    );
  }
}

/// Convenience Provider für Feature-Check in Widgets
/// 
/// Beispiel:
/// ```dart
/// final canFilter = ref.watch(canUseFeatureProvider((f) => f.canUseFilter));
/// if (canFilter) { showFilterButton(); }
/// ```
final canUseFeatureProvider = Provider.family<bool, bool Function(FeatureFlags)>((ref, check) {
  final isAdmin = ref.watch(isCurrentUserAdminProvider);
  if (isAdmin) return true;
  
  final flagsAsync = ref.watch(featureFlagsProvider);
  return flagsAsync.maybeWhen(
    data: (flags) => check(flags),
    orElse: () => true, // Fail-open bei Ladefehlern
  );
});

/// Spezifische Feature-Checks als Provider (für häufige Verwendung)

// Screen-Zugriff
final canAccessKlassenProvider = Provider<bool>((ref) {
  return ref.watch(canUseFeatureProvider((f) => f.canAccessKlassen));
});

final canAccessSchuelerProvider = Provider<bool>((ref) {
  return ref.watch(canUseFeatureProvider((f) => f.canAccessSchueler));
});

final canAccessFaecherProvider = Provider<bool>((ref) {
  return ref.watch(canUseFeatureProvider((f) => f.canAccessFaecher));
});

final canAccessNotenProvider = Provider<bool>((ref) {
  return ref.watch(canUseFeatureProvider((f) => f.canAccessNoten));
});

// Funktionen
final canUseFilterProvider = Provider<bool>((ref) {
  return ref.watch(canUseFeatureProvider((f) => f.canUseFilter));
});

final canUseNachschreiberProvider = Provider<bool>((ref) {
  return ref.watch(canUseFeatureProvider((f) => f.canUseNachschreiber));
});
