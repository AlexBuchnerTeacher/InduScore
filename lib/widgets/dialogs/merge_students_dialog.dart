import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/rbs_colors.dart';
import '../../core/constants/rbs_spacing.dart';
import '../../core/constants/rbs_typography.dart';
import '../../models/klasse.dart';
import '../../models/schuljahr.dart';
import '../../models/student.dart';
import '../../providers/firestore_service_provider.dart';
import '../../services/pdf_import_service.dart';

/// Dialog zum Zusammenführen (Merge) von bestehenden und neuen Schülern in einer Klasse.
///
/// Zeigt drei Kategorien:
/// 1. **Erkannte Schüler**: Automatisches/manuelles Matching zwischen neu und bestand
/// 2. **Neue Schüler**: Noch nicht in der Klasse vorhanden
/// 3. **Nicht mehr im PDF**: Bestehende Schüler ohne Match → als ausgetreten markieren
///
/// Erlaubt manuelles Zuordnen von neuen zu fehlenden Schülern via Dropdown.
class MergeStudentsDialog extends ConsumerStatefulWidget {
  final Klasse existingKlasse;
  final List<Student> existingStudents;
  final List<ImportedStudent> newStudents;
  final Schuljahr schuljahr;

  const MergeStudentsDialog({
    super.key,
    required this.existingKlasse,
    required this.existingStudents,
    required this.newStudents,
    required this.schuljahr,
  });

  @override
  ConsumerState<MergeStudentsDialog> createState() =>
      _MergeStudentsDialogState();
}

class _MergeStudentsDialogState extends ConsumerState<MergeStudentsDialog> {
  bool _isSaving = false;
  DateTime _eintrittsDatum = DateTime.now();

  // Manuelles Matching: Key = "vorname nachname" (lowercase), Value = existing Student ID
  final Map<String, String> _manualMatching = {};

  // Berechnete Listen
  late List<_MatchedStudent> _matched;
  late List<ImportedStudent> _newOnly;
  late List<Student> _missing;

  @override
  void initState() {
    super.initState();
    _calculateMatches();
  }

  void _calculateMatches() {
    _matched = [];
    _newOnly = [];
    _missing = [];

    final matchedExistingIds = <String>{};

    for (final newStudent in widget.newStudents) {
      final key =
          '${newStudent.firstName.toLowerCase()} ${newStudent.lastName.toLowerCase()}';

      // Manuelles Matching?
      if (_manualMatching.containsKey(key)) {
        final existingId = _manualMatching[key]!;
        final existing = widget.existingStudents.firstWhere(
          (s) => s.id == existingId,
        );
        _matched.add(
          _MatchedStudent(
            newStudent: newStudent,
            existingStudent: existing,
            isManual: true,
          ),
        );
        matchedExistingIds.add(existingId);
        continue;
      }

      // Automatisches Matching nach Name
      final existing = widget.existingStudents
          .where(
            (e) =>
                e.firstName.toLowerCase() ==
                    newStudent.firstName.toLowerCase() &&
                e.lastName.toLowerCase() == newStudent.lastName.toLowerCase(),
          )
          .firstOrNull;

      if (existing != null) {
        _matched.add(
          _MatchedStudent(
            newStudent: newStudent,
            existingStudent: existing,
            isManual: false,
          ),
        );
        matchedExistingIds.add(existing.id);
      } else {
        _newOnly.add(newStudent);
      }
    }

    // Fehlende (existierende ohne Match)
    for (final existing in widget.existingStudents) {
      if (!matchedExistingIds.contains(existing.id)) {
        _missing.add(existing);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return AlertDialog(
      title: Text('Klasse ${widget.existingKlasse.name} existiert bereits'),
      content: SizedBox(
        width: 600,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info-Box
              Container(
                padding: const EdgeInsets.all(RBSSpacing.sm),
                decoration: BoxDecoration(
                  color: RBSColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: RBSColors.info),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: RBSColors.info),
                    const SizedBox(width: RBSSpacing.sm),
                    Expanded(
                      child: Text(
                        'Die Klasse hat bereits ${widget.existingStudents.length} Schüler. '
                        'Bestehende Schüler werden beibehalten, neue hinzugefügt.',
                        style: RBSTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RBSSpacing.md),

              // Eintrittsdatum für neue Schüler
              if (_newOnly.isNotEmpty) ...[
                Text(
                  'Eintrittsdatum für neue Schüler:',
                  style: RBSTypography.label,
                ),
                const SizedBox(height: RBSSpacing.xs),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _eintrittsDatum,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _eintrittsDatum = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(dateFormat.format(_eintrittsDatum)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: RBSSpacing.md),
              ],

              // Matched Students (grün)
              if (_matched.isNotEmpty) ...[
                _buildSectionHeader(
                  'Erkannte Schüler (${_matched.length})',
                  Icons.check_circle,
                  RBSColors.courtGreen,
                ),
                ...(_matched
                    .take(10)
                    .map(
                      (m) => ListTile(
                        dense: true,
                        leading: Icon(
                          m.isManual ? Icons.link : Icons.check,
                          color: RBSColors.courtGreen,
                          size: 20,
                        ),
                        title: Text(
                          '${m.newStudent.lastName}, ${m.newStudent.firstName}',
                        ),
                        subtitle: m.isManual
                            ? Text(
                                'Manuell: ${m.existingStudent.displayName}',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : null,
                      ),
                    )),
                if (_matched.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Text(
                      '... und ${_matched.length - 10} weitere',
                      style: RBSTypography.bodySmall,
                    ),
                  ),
                const SizedBox(height: RBSSpacing.sm),
              ],

              // New Students (blau)
              if (_newOnly.isNotEmpty) ...[
                _buildSectionHeader(
                  'Neue Schüler (${_newOnly.length})',
                  Icons.person_add,
                  RBSColors.info,
                ),
                ...(_newOnly.map(
                  (s) => ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.person_add,
                      color: RBSColors.info,
                      size: 20,
                    ),
                    title: Text('${s.lastName}, ${s.firstName}'),
                    trailing: _missing.isNotEmpty
                        ? _buildMatchDropdown(s)
                        : null,
                  ),
                )),
                const SizedBox(height: RBSSpacing.sm),
              ],

              // Missing Students (orange/rot)
              if (_missing.isNotEmpty) ...[
                _buildSectionHeader(
                  'Nicht mehr im PDF (${_missing.length})',
                  Icons.warning_amber,
                  RBSColors.warning,
                ),
                ...(_missing.map(
                  (s) => ListTile(
                    dense: true,
                    leading: Tooltip(
                      message:
                          'Eintritt: ${dateFormat.format(s.eintrittsDatum)}',
                      child: const Icon(
                        Icons.warning_amber,
                        color: RBSColors.warning,
                        size: 20,
                      ),
                    ),
                    title: Text(s.displayName),
                    subtitle: const Text('Wird als ausgetreten markiert?'),
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        if (_missing.isNotEmpty)
          TextButton(
            onPressed: _isSaving
                ? null
                : () => _performMerge(markMissingAsAusgetreten: false),
            child: const Text('Nur neue hinzufügen'),
          ),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () => _performMerge(markMissingAsAusgetreten: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: RBSColors.dynamicRed,
            foregroundColor: RBSColors.textOnRed,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _missing.isNotEmpty
                      ? 'Übernehmen & Austritte markieren'
                      : 'Übernehmen',
                ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RBSSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: RBSSpacing.xs),
          Text(title, style: RBSTypography.label.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildMatchDropdown(ImportedStudent newStudent) {
    final key =
        '${newStudent.firstName.toLowerCase()} ${newStudent.lastName.toLowerCase()}';
    final currentMatch = _manualMatching[key];

    return DropdownButton<String?>(
      value: currentMatch,
      hint: const Text('Zuordnen...', style: TextStyle(fontSize: 12)),
      underline: const SizedBox(),
      isDense: true,
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Neuer Schüler', style: TextStyle(fontSize: 12)),
        ),
        ..._missing.map(
          (existing) => DropdownMenuItem(
            value: existing.id,
            child: Text(
              existing.displayName,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          if (value == null) {
            _manualMatching.remove(key);
          } else {
            _manualMatching[key] = value;
          }
          _calculateMatches();
        });
      },
    );
  }

  Future<void> _performMerge({required bool markMissingAsAusgetreten}) async {
    try {
      setState(() => _isSaving = true);
      final firestoreService = ref.read(firestoreServiceProvider);
      final now = DateTime.now();

      // Neue Schüler erstellen
      final newStudentsToAdd = _newOnly
          .map(
            (s) => Student(
              id: '',
              firstName: s.firstName,
              lastName: s.lastName,
              klasseId: widget.existingKlasse.id,
              eintrittsDatum: _eintrittsDatum,
              createdAt: now,
            ),
          )
          .toList();

      // Merge durchführen
      final result = await firestoreService.mergeStudentsIntoKlasse(
        klasseId: widget.existingKlasse.id,
        neueSchueler: newStudentsToAdd,
        existierendeSchueler: widget.existingStudents,
        manuellesMatching: _manualMatching,
      );

      // Fehlende als ausgetreten markieren
      if (markMissingAsAusgetreten && result.unmatched.isNotEmpty) {
        await firestoreService.markStudentsAsAusgetreten(
          result.unmatched.map((s) => s.id).toList(),
          now,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);

      final message = StringBuffer('Import abgeschlossen: ');
      if (result.added.isNotEmpty) {
        message.write('${result.added.length} neue Schüler');
      }
      if (markMissingAsAusgetreten && result.unmatched.isNotEmpty) {
        if (result.added.isNotEmpty) message.write(', ');
        message.write('${result.unmatched.length} als ausgetreten markiert');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.toString()),
          backgroundColor: RBSColors.courtGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e'), backgroundColor: RBSColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _MatchedStudent {
  final ImportedStudent newStudent;
  final Student existingStudent;
  final bool isManual;

  _MatchedStudent({
    required this.newStudent,
    required this.existingStudent,
    required this.isManual,
  });
}
