import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../core/theme/rbs_theme.dart';
import '../../core/widgets/rbs_components.dart';

/// Favoriten-Klassen Manager für Profil
class FavoritesManager extends ConsumerStatefulWidget {
  final String userId;
  final List<String> currentFavorites;

  const FavoritesManager({
    super.key,
    required this.userId,
    required this.currentFavorites,
  });

  @override
  ConsumerState<FavoritesManager> createState() => _FavoritesManagerState();
}

class _FavoritesManagerState extends ConsumerState<FavoritesManager> {
  late Set<String> _selectedKlassen;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedKlassen = Set.from(widget.currentFavorites);
  }

  void _toggleKlasse(String klasseId) {
    setState(() {
      if (_selectedKlassen.contains(klasseId)) {
        _selectedKlassen.remove(klasseId);
      } else {
        _selectedKlassen.add(klasseId);
      }
      _hasChanges = true;
    });
  }

  Future<void> _saveFavorites() async {
    setState(() => _isLoading = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateFavoriteKlassen(
        widget.userId,
        _selectedKlassen.toList(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favoriten erfolgreich gespeichert'),
          backgroundColor: RBSColors.success,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          backgroundColor: RBSColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final klassenStream = ref.watch(klassenProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info Card
        RBSCard(
          backgroundColor: RBSColors.greenLight,
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: RBSColors.courtGreen),
              const SizedBox(width: RBSSpacing.sm),
              Expanded(
                child: Text(
                  'Favoriten werden auf dem Dashboard angezeigt und ermöglichen schnellen Zugriff.',
                  style: RBSTypography.bodySmall.copyWith(
                    color: RBSColors.textOnLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: RBSSpacing.lg),

        // Klassen-Liste
        const RBSHeadline(
          text: 'Klassen auswählen',
          level: RBSHeadlineLevel.h3,
        ),
        const SizedBox(height: RBSSpacing.md),

        Expanded(
          child: klassenStream.when(
            data: (klassen) {
              if (klassen.isEmpty) {
                return const Center(
                  child: Text(
                    'Keine Klassen verfügbar',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: klassen.length,
                itemBuilder: (context, index) {
                  final klasse = klassen[index];
                  final isSelected = _selectedKlassen.contains(klasse.id);

                  return RBSCard(
                    padding: EdgeInsets.zero,
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => _toggleKlasse(klasse.id),
                      title: Text(
                        klasse.name,
                        style: const TextStyle(
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${klasse.beruf.name} • ${klasse.schuljahr}',
                        style: const TextStyle(
                          fontFamily: 'OpenSans',
                          fontSize: 13,
                        ),
                      ),
                      activeColor: RBSColors.dynamicRed,
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Fehler beim Laden: $error',
                style: const TextStyle(color: RBSColors.error),
              ),
            ),
          ),
        ),

        // Speichern-Button
        const SizedBox(height: RBSSpacing.md),
        Row(
          children: [
            Expanded(
              child: RBSButton(
                label: 'Favoriten speichern',
                onPressed: _hasChanges && !_isLoading ? _saveFavorites : null,
                isLoading: _isLoading,
                icon: Icons.save,
              ),
            ),
          ],
        ),
        if (_selectedKlassen.isNotEmpty) ...[
          const SizedBox(height: RBSSpacing.sm),
          Text(
            '${_selectedKlassen.length} ${_selectedKlassen.length == 1 ? "Klasse" : "Klassen"} ausgewählt',
            style: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
}
