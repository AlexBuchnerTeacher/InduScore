import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/grade.dart';
import '../models/leistungsnachweis.dart';
import '../models/student.dart';
import '../providers/app_providers.dart';
import '../core/theme/rbs_theme.dart';

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
  final Map<String, _NotenEingabe> _noten = {};
  final Set<String> _savingStudents = {}; // Schüler, die gerade gespeichert werden
  Leistungsnachweis? _leistungsnachweis;

  @override
  Widget build(BuildContext context) {
    final leistungsnachweisAsync = ref.watch(leistungsnachweisProvider(widget.leistungsnachweisId));
    final gradesAsync = ref.watch(gradesByLeistungsnachweisProvider(widget.leistungsnachweisId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/leistungsnachweise'),
          tooltip: 'Zurück',
        ),
        title: _leistungsnachweis != null
            ? Text('Noten: ${_leistungsnachweis!.bezeichnung}')
            : const Text('Noteneingabe'),
      ),
      body: leistungsnachweisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
        data: (leistungsnachweis) {
          _leistungsnachweis = leistungsnachweis;
          final studentsAsync = ref.watch(studentsByKlasseProvider(leistungsnachweis.klasseId));

          return studentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Fehler: $error')),
            data: (students) {
              if (students.isEmpty) {
                return const Center(
                  child: Text('Keine Schüler in dieser Klasse'),
                );
              }

              return gradesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Fehler: $error')),
                data: (grades) {
                  // Initialisiere Noten für alle Schüler
                  _initializeNoten(students, grades);

                  return _buildNotenTabelle(students);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _initializeNoten(List<Student> students, List<Grade> grades) {
    for (final student in students) {
      if (!_noten.containsKey(student.id)) {
        final existingGrade = grades
            .where((g) => g.studentId == student.id)
            .firstOrNull;

        _noten[student.id] = _NotenEingabe(
          note: existingGrade?.note,
          tendenz: existingGrade?.tendenz ?? Tendenz.keine,
          kommentar: existingGrade?.kommentar,
          existingGradeId: existingGrade?.id,
          updatedBy: existingGrade?.updatedBy,
        );
      }
    }
  }

  /// Generiert Kürzel aus Email (z.B. "buchner@schule.de" -> "bu")
  String _getUserKuerzel(String? email) {
    if (email == null || email.isEmpty) return '??';
    final namePart = email.split('@').first;
    // Erste 2 Buchstaben des Login-Namens
    if (namePart.length >= 2) {
      return namePart.substring(0, 2).toLowerCase();
    }
    return namePart.toLowerCase();
  }

  Widget _buildNotenTabelle(List<Student> students) {
    // Sortiere Schüler nach displayName
    final sortedStudents = List<Student>.from(students)
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return Column(
      children: [
        // Header mit Leistungsnachweis-Info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: RBSColors.dynamicRed.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(
                _getTypIcon(_leistungsnachweis!.typ),
                color: RBSColors.dynamicRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _leistungsnachweis!.bezeichnung,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_leistungsnachweis!.typ.label} • Gewichtung: ${_leistungsnachweis!.gewichtung}x • ${_formatDate(_leistungsnachweis!.datum)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tabellen-Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  'Nr.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Schüler/in',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'Note',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  'Tendenz',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'Kommentar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Schüler-Liste
        Expanded(
          child: ListView.builder(
            itemCount: sortedStudents.length,
            itemBuilder: (context, index) {
              final student = sortedStudents[index];
              return _buildStudentRow(student, index + 1);
            },
          ),
        ),

        // Footer mit Statistik
        _buildStatistikFooter(),
      ],
    );
  }

  Widget _buildStudentRow(Student student, int nummer) {
    final eingabe = _noten[student.id]!;
    final isEven = nummer % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isEven ? Colors.grey[50] : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Nummer
          SizedBox(
            width: 40,
            child: Text(
              '$nummer.',
              style: const TextStyle(color: Colors.grey),
            ),
          ),

          // Name
          Expanded(
            flex: 3,
            child: Text(
              student.displayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          // Note (1-6) mit Kürzel in Ecke
          SizedBox(
            width: 80,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<int?>(
                    value: eingabe.note,
                    isExpanded: true,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('-'),
                      ),
                      ...List.generate(6, (i) => i + 1).map(
                        (note) => DropdownMenuItem<int>(
                          value: note,
                          child: Text(
                            '$note',
                            style: TextStyle(
                              color: _getNoteColor(note),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _noten[student.id] = eingabe.copyWith(note: value);
                      });
                      _saveGradeForStudent(student.id);
                    },
                  ),
                ),
                // Kürzel in rechter oberer Ecke
                if (eingabe.updatedBy != null)
                  Positioned(
                    right: 2,
                    top: 1,
                    child: Text(
                      eingabe.updatedBy!,
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Tendenz (+, -, keine) - einfache Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTendenzButton(student.id, eingabe, Tendenz.plus, '+'),
              const SizedBox(width: 2),
              _buildTendenzButton(student.id, eingabe, Tendenz.keine, '·'),
              const SizedBox(width: 2),
              _buildTendenzButton(student.id, eingabe, Tendenz.minus, '-'),
            ],
          ),

          const SizedBox(width: 16),

          // Kommentar
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: eingabe.kommentar ?? '',
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
                hintText: 'Optional...',
              ),
              onChanged: (value) {
                _noten[student.id] = eingabe.copyWith(
                  kommentar: value.isEmpty ? null : value,
                );
                // Debounce für Kommentar - speichert nach kurzer Pause
                _saveGradeForStudentDebounced(student.id);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTendenzButton(String studentId, _NotenEingabe eingabe, Tendenz tendenz, String label) {
    final isSelected = eingabe.tendenz == tendenz;
    return InkWell(
      onTap: () {
        setState(() {
          _noten[studentId] = eingabe.copyWith(tendenz: tendenz);
        });
        _saveGradeForStudent(studentId);
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? RBSColors.dynamicRed : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistikFooter() {
    final notenMitWert = _noten.values.where((n) => n.note != null).toList();
    if (notenMitWert.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[100],
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Noch keine Noten eingetragen'),
          ],
        ),
      );
    }

    final durchschnitt = notenMitWert.map((n) => n.note!).reduce((a, b) => a + b) /
        notenMitWert.length;

    // Zähle Noten-Verteilung
    final verteilung = <int, int>{};
    for (final n in notenMitWert) {
      verteilung[n.note!] = (verteilung[n.note!] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Eingetragen',
            '${notenMitWert.length}/${_noten.length}',
            Icons.edit_note,
          ),
          _buildStatItem(
            'Durchschnitt',
            durchschnitt.toStringAsFixed(2),
            Icons.analytics,
            color: _getNoteColor(durchschnitt.round()),
          ),
          ...List.generate(6, (i) => i + 1).map(
            (note) => _buildStatItem(
              'Note $note',
              '${verteilung[note] ?? 0}',
              null,
              color: _getNoteColor(note),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData? icon, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: 16, color: color ?? Colors.grey),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Color _getNoteColor(int note) {
    switch (note) {
      case 1:
        return Colors.green[700]!;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.orange[700]!;
      case 5:
        return Colors.red;
      case 6:
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypIcon(LeistungsnachweisTyp typ) {
    switch (typ) {
      case LeistungsnachweisTyp.wochentest:
        return Icons.assignment;
      case LeistungsnachweisTyp.praktisch:
        return Icons.build;
      case LeistungsnachweisTyp.muendlich:
        return Icons.record_voice_over;
      case LeistungsnachweisTyp.mitarbeit:
        return Icons.person;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Debounce-Timer für Kommentar-Eingabe
  final Map<String, Future<void>> _debounceTimers = {};

  /// Speichert Note für einen einzelnen Schüler sofort
  Future<void> _saveGradeForStudent(String studentId) async {
    final eingabe = _noten[studentId];
    if (eingabe == null) return;

    // Wenn schon am Speichern, abbrechen
    if (_savingStudents.contains(studentId)) return;

    setState(() => _savingStudents.add(studentId));

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final user = ref.read(currentUserProvider);
      // Kürzel aus Email generieren (z.B. "alex.buchner@schule.de" -> "AB")
      final userKuerzel = _getUserKuerzel(user?.email);

      if (eingabe.note != null) {
        final grade = Grade(
          id: eingabe.existingGradeId ?? '',
          studentId: studentId,
          leistungsnachweisId: widget.leistungsnachweisId,
          note: eingabe.note!,
          tendenz: eingabe.tendenz,
          kommentar: eingabe.kommentar,
          updatedBy: userKuerzel,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (eingabe.existingGradeId != null) {
          await firestoreService.updateGrade(grade);
        } else {
          final newId = await firestoreService.createGrade(grade);
          _noten[studentId] = eingabe.copyWith(existingGradeId: newId);
        }
      } else if (eingabe.existingGradeId != null) {
        // Note wurde gelöscht - Grade löschen
        await firestoreService.deleteGrade(eingabe.existingGradeId!);
        _noten[studentId] = eingabe.copyWith(existingGradeId: null);
      }

      // Refresh grades
      ref.invalidate(gradesByLeistungsnachweisProvider(widget.leistungsnachweisId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingStudents.remove(studentId));
      }
    }
  }

  /// Speichert Note mit Verzögerung (für Kommentar-Eingabe)
  void _saveGradeForStudentDebounced(String studentId) {
    // Warte 500ms nach letzter Eingabe, dann speichern
    _debounceTimers[studentId] = Future.delayed(
      const Duration(milliseconds: 500),
      () => _saveGradeForStudent(studentId),
    );
  }
}

class _NotenEingabe {
  final int? note;
  final Tendenz tendenz;
  final String? kommentar;
  final String? existingGradeId;
  final String? updatedBy;

  _NotenEingabe({
    this.note,
    this.tendenz = Tendenz.keine,
    this.kommentar,
    this.existingGradeId,
    this.updatedBy,
  });

  _NotenEingabe copyWith({
    int? note,
    Tendenz? tendenz,
    String? kommentar,
    String? existingGradeId,
    String? updatedBy,
  }) {
    return _NotenEingabe(
      note: note ?? this.note,
      tendenz: tendenz ?? this.tendenz,
      kommentar: kommentar ?? this.kommentar,
      existingGradeId: existingGradeId ?? this.existingGradeId,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
