import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/rbs_theme.dart';
import '../../../core/widgets/rbs_components.dart';
import '../../../models/feature_flags.dart';
import '../../../providers/feature_flags_provider.dart';
import '../../../widgets/rbs_drawer.dart';
import '../../../shared/widgets/app_snack_bars.dart';

/// Admin-Screen für Feature-Flag-Verwaltung
/// 
/// Ermöglicht Admins, granulare Berechtigungen für Lehrer zu konfigurieren.
class FeatureFlagsScreen extends ConsumerWidget {
  const FeatureFlagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(featureFlagsProvider);
    final notifierState = ref.watch(featureFlagsNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature-Flags'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menü',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _showResetDialog(context, ref),
            tooltip: 'Auf Defaults zurücksetzen',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: 'Zum Dashboard',
          ),
        ],
      ),
      drawer: const RBSDrawer(),
      body: flagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: RBSColors.dynamicRed),
              const SizedBox(height: RBSSpacing.md),
              Text('Fehler: $e', style: RBSTypography.bodyMedium),
              const SizedBox(height: RBSSpacing.md),
              RBSButton(
                label: 'Erneut versuchen',
                onPressed: () => ref.invalidate(featureFlagsProvider),
              ),
            ],
          ),
        ),
        data: (flags) => _buildFlagsList(context, ref, flags, notifierState),
      ),
    );
  }

  Widget _buildFlagsList(
    BuildContext context,
    WidgetRef ref,
    FeatureFlags flags,
    FeatureFlagsUpdateState notifierState,
  ) {
    final flagsByCategory = FeatureFlagInfo.byCategory;
    final sortedCategories = [
      'Schüler',
      'Klassen',
      'Fächer',
      'Leistungsnachweise',
      'Import/Export',
      'Sonstige',
    ];

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(RBSSpacing.md),
          itemCount: sortedCategories.length,
          itemBuilder: (context, index) {
            final category = sortedCategories[index];
            final categoryFlags = flagsByCategory[category] ?? [];
            if (categoryFlags.isEmpty) return const SizedBox.shrink();
            
            return _buildCategorySection(
              context,
              ref,
              category,
              categoryFlags,
              flags,
            );
          },
        ),
        // Loading-Overlay
        if (notifierState.isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    WidgetRef ref,
    String category,
    List<FeatureFlagInfo> categoryFlags,
    FeatureFlags currentFlags,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: RBSSpacing.sm),
          child: Row(
            children: [
              Icon(_getCategoryIcon(category), size: 20, color: RBSColors.courtGreen),
              const SizedBox(width: RBSSpacing.xs),
              Text(category, style: RBSTypography.h4),
            ],
          ),
        ),
        RBSCard(
          child: Column(
            children: categoryFlags.map((flagInfo) {
              final currentValue = _getFlagValue(currentFlags, flagInfo.key);
              return _buildFlagTile(context, ref, flagInfo, currentValue);
            }).toList(),
          ),
        ),
        const SizedBox(height: RBSSpacing.md),
      ],
    );
  }

  Widget _buildFlagTile(
    BuildContext context,
    WidgetRef ref,
    FeatureFlagInfo flagInfo,
    bool currentValue,
  ) {
    return SwitchListTile(
      title: Text(flagInfo.label, style: RBSTypography.bodyMedium),
      subtitle: Text(
        flagInfo.description,
        style: RBSTypography.bodySmall.copyWith(color: RBSColors.textOnLight.withValues(alpha: 0.7)),
      ),
      value: currentValue,
      activeTrackColor: RBSColors.courtGreen.withValues(alpha: 0.5),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return RBSColors.courtGreen;
        }
        return null;
      }),
      onChanged: (newValue) {
        ref.read(featureFlagsNotifierProvider.notifier).updateFlag(
          flagInfo.key,
          newValue,
        );
      },
      secondary: Icon(
        currentValue ? Icons.check_circle : Icons.cancel,
        color: currentValue ? RBSColors.courtGreen : RBSColors.textOnLight.withValues(alpha: 0.3),
      ),
    );
  }

  bool _getFlagValue(FeatureFlags flags, String key) {
    switch (key) {
      case 'canImportCSV': return flags.canImportCSV;
      case 'canCreateSchueler': return flags.canCreateSchueler;
      case 'canEditSchueler': return flags.canEditSchueler;
      case 'canDeleteSchueler': return flags.canDeleteSchueler;
      case 'canCreateFaecher': return flags.canCreateFaecher;
      case 'canEditFaecher': return flags.canEditFaecher;
      case 'canDeleteFaecher': return flags.canDeleteFaecher;
      case 'canCreateKlassen': return flags.canCreateKlassen;
      case 'canEditKlassen': return flags.canEditKlassen;
      case 'canDeleteKlassen': return flags.canDeleteKlassen;
      case 'canCreateLeistungsnachweise': return flags.canCreateLeistungsnachweise;
      case 'canEditLeistungsnachweise': return flags.canEditLeistungsnachweise;
      case 'canDeleteLeistungsnachweise': return flags.canDeleteLeistungsnachweise;
      case 'canToggleFavorites': return flags.canToggleFavorites;
      case 'canExportPDF': return flags.canExportPDF;
      case 'canExportExcel': return flags.canExportExcel;
      case 'canExportNOI': return flags.canExportNOI;
      default: return false;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Schüler': return Icons.people;
      case 'Klassen': return Icons.class_;
      case 'Fächer': return Icons.book;
      case 'Leistungsnachweise': return Icons.assignment;
      case 'Import/Export': return Icons.import_export;
      case 'Sonstige': return Icons.settings;
      default: return Icons.flag;
    }
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auf Defaults zurücksetzen?'),
        content: const Text(
          'Alle Feature-Flags werden auf die Standard-Werte zurückgesetzt. '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(featureFlagsNotifierProvider.notifier).resetToDefaults();
              Navigator.of(context).pop();
              AppSnackBars.showInfo(context, 'Feature-Flags zurückgesetzt');
            },
            style: ElevatedButton.styleFrom(backgroundColor: RBSColors.dynamicRed),
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
  }
}
