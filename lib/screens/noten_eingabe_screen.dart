import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/rbs_theme.dart';
import '../core/widgets/rbs_components.dart';
import '../models/grade.dart';
import '../models/leistungsnachweis.dart';
import '../models/student.dart';
import '../providers/app_providers.dart';

/// Excel-Style Noteneingabe für einen Leistungsnachweis
class NotenEingabeScreen extends ConsumerStatefulWidget {
  final String leistungsnachweisId;

  const NotenEingabeScreen({
    super.key,
    required this.leistungsnachweisId,
  });

  @override
  ConsumerState<NotenEingabeScreen> createState() => _NotenEingabeScreenState();
}

class _NotenEingabeScreenState extends ConsumerState<NotenEingabeScreen> {
  // Zustand für Noten-Eingaben: studentId -> (note, kommentar, punkte)
  final Map<String, _NotenEingabe> _eingaben = {};
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final lnAsync = ref.watch(leistungsnachweisProvider(widget.leistungsnachweisId));

    return lnAsync.when(
      data: (ln) => _buildContent(context, ln),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Noteneingabe')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Noteneingabe')),
        body: Center(child: Text('Fehler: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Leistungsnachweis ln) {
    final klasseAsync = ref.watch(klasseProvider(ln.klasseId));
    final subjectAsync = ref.watch(subjectProvider(ln.subjectId));
    final studentsAsync = ref.watch(studentsByKlasseProvider(ln.klasseId));
    final gradesAsync = ref.watch(gradesByLeistungsnachweisProvider(ln.id));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBack(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ln.bezeichnung),
            Row(
              children: [
                klasseAsync.when(
                  data: (klasse) => Text(
                    klasse.name,
                    style: RBSTypography.bodySmall.copyWith(
                      color: RBSColors.textOnLight.withValues(alpha: 0.7),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),
                const SizedBox(width: RBSSpacing.sm),
                subjectAsync.when(
                  data: (subject) => Text(
                    '• ${subject.shortName ?? subject.name}',
                    style: RBSTypography.bodySmall.copyWith(
                      color: RBSColors.textOnLight.withValues(alpha: 0.7),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),
                const SizedBox(width: RBSSpacing.sm),
                Text(
                  '• ${DateFormat('dd.MM.yyyy').format(ln.datum)}',
                  style: RBSTypography.bodySmall.copyWith(
                    color: RBSColors.textOnLight.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isSaving ? null : () => _saveGrades(ln),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Speichern'),
              style: TextButton.styleFrom(
                foregroundColor: RBSColors.dynamicRed,
              ),
            ),
        ],
      ),
      body: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: RBSColors.textOnLight.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: RBSSpacing.md),
                  Text(
                    'Keine Schüler in dieser Klasse',
                    style: RBSTypography.h4.copyWith(
                      color: RBSColors.textOnLight.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return gradesAsync.when(
            data: (existingGrades) {
              // Initialisiere Eingaben mit bestehenden Noten
              _initializeEingaben(students, existingGrades);

              return Column(
                children: [
                  // Header mit Legende
                  _buildLegend(ln),
                  const Divider(height: 1),
                  // Notenliste
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(RBSSpacing.md),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return _buildStudentRow(student, ln, index);
                      },
                    ),
                  ),
                  // Footer mit Statistik
                  _buildStatisticsFooter(students),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Fehler: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
      ),
    );
  }

  void _initializeEingaben(List<Student> students, List<Grade> existingGrades) {
    for (final student in students) {
      if (!_eingaben.containsKey(student.id)) {
        final existingGrade = existingGrades
            .where((g) => g.studentId == student.id)
            .firstOrNull;

        _eingaben[student.id] = _NotenEingabe(
          gradeId: existingGrade?.id,
          note: existingGrade?.note,
          punkte: existingGrade?.punkte,
          kommentar: existingGrade?.kommentar,
        );
      }
    }
  }

  Widget _buildLegend(Leistungsnachweis ln) {
    return Container(
      padding: const EdgeInsets.all(RBSSpacing.md),
      color: RBSColors.paper,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Schüler', style: RBSTypography.label),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'Note',
              style: RBSTypography.label,
              textAlign: TextAlign.center,
            ),
          ),
          if (ln.maxPunkte > 0)
            SizedBox(
              width: 100,
              child: Text(
                'Punkte (/${ln.maxPunkte.toInt()})',
                style: RBSTypography.label,
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            width: 180,
            child: Text('Kommentar', style: RBSTypography.label),
          ),
          const SizedBox(width: 48), // Platz für Tooltip-Icon
        ],
      ),
    );
  }

  Widget _buildStudentRow(Student student, Leistungsnachweis ln, int index) {
    final eingabe = _eingaben[student.id] ?? _NotenEingabe();
    final noteController = TextEditingController(
      text: eingabe.note?.toString() ?? '',
    );
    final punkteController = TextEditingController(
      text: eingabe.punkte?.toString() ?? '',
    );
    final kommentarController = TextEditingController(
      text: eingabe.kommentar ?? '',
    );

    // Alternate row colors
    final bgColor = index.isEven
        ? RBSColors.white
        : RBSColors.paper.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RBSSpacing.md,
        vertical: RBSSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: RBSColors.textOnLight.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Schüler-Pseudonym
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: RBSColors.dynamicRed.withValues(alpha: 0.1),
                  child: Text(
                    student.pseudonym.substring(0, 2),
                    style: RBSTypography.bodySmall.copyWith(
                      color: RBSColors.dynamicRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: RBSSpacing.sm),
                Text(student.pseudonym, style: RBSTypography.bodyMedium),
              ],
            ),
          ),

          // Note Eingabe (1-6)
          SizedBox(
            width: 80,
            child: TextField(
              controller: noteController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
                _NoteRangeFormatter(),
              ],
              decoration: InputDecoration(
                hintText: '-',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RBSSpacing.xs),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: RBSSpacing.sm,
                  vertical: RBSSpacing.xs,
                ),
                filled: true,
                fillColor: _getNoteColor(eingabe.note),
              ),
              onChanged: (value) {
                final note = int.tryParse(value);
                setState(() {
                  _eingaben[student.id] = eingabe.copyWith(
                    note: note,
                    clearNote: note == null,
                  );
                  _hasChanges = true;
                });
              },
            ),
          ),

          // Punkte Eingabe (optional)
          if (ln.maxPunkte > 0)
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.only(left: RBSSpacing.sm),
                child: TextField(
                  controller: punkteController,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '-',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RBSSpacing.xs),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: RBSSpacing.sm,
                      vertical: RBSSpacing.xs,
                    ),
                  ),
                  onChanged: (value) {
                    final punkte = double.tryParse(value);
                    // Auto-Berechnung der Note aus Punkten
                    int? autoNote;
                    if (punkte != null && ln.maxPunkte > 0) {
                      autoNote = IHKNotenschluessel.punkteZuNote(
                        punkte,
                        ln.maxPunkte,
                      );
                    }
                    setState(() {
                      _eingaben[student.id] = eingabe.copyWith(
                        punkte: punkte,
                        note: autoNote ?? eingabe.note,
                        clearPunkte: punkte == null,
                      );
                      _hasChanges = true;
                    });
                  },
                ),
              ),
            ),

          // Kommentar Eingabe
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsets.only(left: RBSSpacing.sm),
              child: TextField(
                controller: kommentarController,
                decoration: InputDecoration(
                  hintText: 'Kommentar...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RBSSpacing.xs),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: RBSSpacing.sm,
                    vertical: RBSSpacing.xs,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _eingaben[student.id] = eingabe.copyWith(
                      kommentar: value.isEmpty ? null : value,
                      clearKommentar: value.isEmpty,
                    );
                    _hasChanges = true;
                  });
                },
              ),
            ),
          ),

          // Tooltip-Icon falls Kommentar vorhanden
          SizedBox(
            width: 48,
            child: eingabe.kommentar != null && eingabe.kommentar!.isNotEmpty
                ? Tooltip(
                    message: eingabe.kommentar!,
                    child: Icon(
                      Icons.comment,
                      color: RBSColors.courtGreen,
                      size: 20,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsFooter(List<Student> students) {
    final notenMitWert = _eingaben.values
        .where((e) => e.note != null)
        .map((e) => e.note!)
        .toList();

    final anzahlMitNote = notenMitWert.length;
    final anzahlOhneNote = students.length - anzahlMitNote;
    final durchschnitt = notenMitWert.isEmpty
        ? 0.0
        : notenMitWert.reduce((a, b) => a + b) / notenMitWert.length;

    // Notenverteilung
    final verteilung = <int, int>{};
    for (final note in notenMitWert) {
      verteilung[note] = (verteilung[note] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(RBSSpacing.md),
      color: RBSColors.paper,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Statistik links
          Row(
            children: [
              _StatChip(
                label: 'Eingetragen',
                value: '$anzahlMitNote/${students.length}',
                color: RBSColors.courtGreen,
              ),
              const SizedBox(width: RBSSpacing.sm),
              if (anzahlOhneNote > 0)
                _StatChip(
                  label: 'Offen',
                  value: '$anzahlOhneNote',
                  color: RBSColors.dynamicRed,
                ),
              const SizedBox(width: RBSSpacing.md),
              if (anzahlMitNote > 0)
                _StatChip(
                  label: 'Ø',
                  value: durchschnitt.toStringAsFixed(2),
                  color: _getAverageColor(durchschnitt),
                ),
            ],
          ),

          // Notenverteilung rechts
          if (verteilung.isNotEmpty)
            Row(
              children: [
                for (int i = 1; i <= 6; i++)
                  if (verteilung[i] != null && verteilung[i]! > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: RBSSpacing.xs),
                      child: Chip(
                        label: Text('${verteilung[i]}x$i'),
                        backgroundColor: _getNoteColor(i),
                        labelStyle: RBSTypography.bodySmall,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getNoteColor(int? note) {
    if (note == null) return RBSColors.white;
    switch (note) {
      case 1:
        return const Color(0xFF4CAF50).withValues(alpha: 0.2); // Grün
      case 2:
        return const Color(0xFF8BC34A).withValues(alpha: 0.2); // Hellgrün
      case 3:
        return const Color(0xFFFFEB3B).withValues(alpha: 0.2); // Gelb
      case 4:
        return const Color(0xFFFF9800).withValues(alpha: 0.2); // Orange
      case 5:
        return const Color(0xFFFF5722).withValues(alpha: 0.2); // Dunkelorange
      case 6:
        return const Color(0xFFF44336).withValues(alpha: 0.2); // Rot
      default:
        return RBSColors.white;
    }
  }

  Color _getAverageColor(double avg) {
    if (avg <= 2.0) return RBSColors.courtGreen;
    if (avg <= 3.5) return const Color(0xFFFF9800);
    return RBSColors.dynamicRed;
  }

  void _handleBack(BuildContext context) {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (context) => RBSDialog(
          title: 'Änderungen verwerfen?',
          content: const Text(
            'Sie haben ungespeicherte Änderungen. Möchten Sie diese verwerfen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            RBSButton(
              label: 'Verwerfen',
              onPressed: () {
                Navigator.pop(context); // Dialog schließen
                context.go('/leistungsnachweise');
              },
            ),
          ],
        ),
      );
    } else {
      context.go('/leistungsnachweise');
    }
  }

  Future<void> _saveGrades(Leistungsnachweis ln) async {
    setState(() => _isSaving = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final now = DateTime.now();

      final gradesToSave = <Grade>[];
      for (final entry in _eingaben.entries) {
        final studentId = entry.key;
        final eingabe = entry.value;

        if (eingabe.note != null) {
          gradesToSave.add(Grade(
            id: eingabe.gradeId ?? '',
            studentId: studentId,
            leistungsnachweisId: ln.id,
            note: eingabe.note!,
            punkte: eingabe.punkte,
            kommentar: eingabe.kommentar,
            createdAt: eingabe.gradeId != null ? now : now, // Wird nicht geändert bei Update
            updatedAt: now,
          ));
        }
      }

      await firestoreService.saveGrades(gradesToSave);

      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${gradesToSave.length} Noten gespeichert'),
            backgroundColor: RBSColors.courtGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: RBSColors.dynamicRed,
          ),
        );
      }
    }
  }
}

/// Eingabe-Daten pro Schüler
class _NotenEingabe {
  final String? gradeId;
  final int? note;
  final double? punkte;
  final String? kommentar;

  _NotenEingabe({
    this.gradeId,
    this.note,
    this.punkte,
    this.kommentar,
  });

  _NotenEingabe copyWith({
    String? gradeId,
    int? note,
    double? punkte,
    String? kommentar,
    bool clearNote = false,
    bool clearPunkte = false,
    bool clearKommentar = false,
  }) {
    return _NotenEingabe(
      gradeId: gradeId ?? this.gradeId,
      note: clearNote ? null : (note ?? this.note),
      punkte: clearPunkte ? null : (punkte ?? this.punkte),
      kommentar: clearKommentar ? null : (kommentar ?? this.kommentar),
    );
  }
}

/// Formatter für Noten 1-6
class _NoteRangeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final value = int.tryParse(newValue.text);
    if (value == null || value < 1 || value > 6) {
      return oldValue;
    }
    return newValue;
  }
}

/// Statistik-Chip Widget
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RBSSpacing.sm,
        vertical: RBSSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(RBSSpacing.xs),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: RBSTypography.bodySmall.copyWith(color: color),
          ),
          const SizedBox(width: RBSSpacing.xs),
          Text(
            value,
            style: RBSTypography.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
