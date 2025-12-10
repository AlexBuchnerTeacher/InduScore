import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/grade.dart';
import '../models/leistungsnachweis.dart';
import '../models/student.dart';
import '../models/klasse.dart';
import '../models/subject.dart';
import '../providers/app_providers.dart';
import '../core/theme/rbs_theme.dart';
import '../core/widgets/rbs_components.dart';
import '../widgets/rbs_drawer.dart';

/// Zentrale Notenübersicht mit flexiblen Filtern
/// 
/// Kann gefiltert werden nach:
/// - klasseId: Zeigt alle Schüler einer Klasse mit allen Fächern
/// - fachId: Zeigt alle Klassen/Schüler mit diesem Fach
/// - studentId: Zeigt alle Noten eines Schülers
class NotenUebersichtScreen extends ConsumerStatefulWidget {
  final String? klasseId;
  final String? fachId;
  final String? studentId;

  const NotenUebersichtScreen({
    super.key,
    this.klasseId,
    this.fachId,
    this.studentId,
  });

  @override
  ConsumerState<NotenUebersichtScreen> createState() => _NotenUebersichtScreenState();
}

class _NotenUebersichtScreenState extends ConsumerState<NotenUebersichtScreen> {
  final Map<String, _NotenEingabe> _noten = {};
  final Set<String> _savingGrades = {};
  
  // Filter State
  String? _selectedSubjectId;
  String? _selectedKlasseId;
  LeistungsnachweisTyp? _selectedTyp;

  @override
  Widget build(BuildContext context) {
    final klassenAsync = ref.watch(klassenProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final leistungsnachweiseAsync = ref.watch(leistungsnachweiseProvider);
    final gradesAsync = ref.watch(gradesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(_getTitle()),
      ),
      drawer: const RBSDrawer(),
      body: klassenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Fehler: $e')),
        data: (klassen) => subjectsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Fehler: $e')),
          data: (subjects) => leistungsnachweiseAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Fehler: $e')),
            data: (leistungsnachweise) => gradesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Fehler: $e')),
              data: (grades) => _buildContent(
                klassen,
                subjects,
                leistungsnachweise,
                grades,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    if (widget.studentId != null) return 'Noten - Schüler';
    if (widget.klasseId != null) return 'Noten - Klasse';
    if (widget.fachId != null) return 'Noten - Fach';
    return 'Notenübersicht';
  }

  Widget _buildContent(
    List<Klasse> klassen,
    List<Subject> subjects,
    List<Leistungsnachweis> leistungsnachweise,
    List<Grade> grades,
  ) {
    // Filter Leistungsnachweise basierend auf Kontext
    var filteredLN = leistungsnachweise;
    if (widget.klasseId != null) {
      filteredLN = filteredLN.where((ln) => ln.klasseId == widget.klasseId).toList();
    }
    if (widget.fachId != null) {
      filteredLN = filteredLN.where((ln) => ln.subjectId == widget.fachId).toList();
    }
    
    // Zusätzliche Filter anwenden
    if (_selectedSubjectId != null) {
      filteredLN = filteredLN.where((ln) => ln.subjectId == _selectedSubjectId).toList();
    }
    if (_selectedKlasseId != null) {
      filteredLN = filteredLN.where((ln) => ln.klasseId == _selectedKlasseId).toList();
    }
    if (_selectedTyp != null) {
      filteredLN = filteredLN.where((ln) => ln.typ == _selectedTyp).toList();
    }

    // Sortiere nach Datum
    filteredLN.sort((a, b) => b.datum.compareTo(a.datum));

    // Hole relevante Schüler
    List<Student> students = [];
    if (widget.studentId != null) {
      // Einzelner Schüler - lade über Provider
      final studentAsync = ref.watch(studentsByKlasseProvider(
        filteredLN.isNotEmpty ? filteredLN.first.klasseId : '',
      ));
      students = studentAsync.value ?? [];
      students = students.where((s) => s.id == widget.studentId).toList();
    } else if (widget.klasseId != null) {
      final studentAsync = ref.watch(studentsByKlasseProvider(widget.klasseId!));
      students = studentAsync.value ?? [];
    } else {
      // Alle Schüler aus allen relevanten Klassen
      final klasseIds = filteredLN.map((ln) => ln.klasseId).toSet();
      for (final klasseId in klasseIds) {
        final studentAsync = ref.watch(studentsByKlasseProvider(klasseId));
        students.addAll(studentAsync.value ?? []);
      }
    }

    // Sortiere Schüler nach Nachname
    students.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    // Initialisiere Noten-Map
    _initializeNoten(students, filteredLN, grades);

    return Column(
      children: [
        // Filter-Chips
        _buildFilterChips(leistungsnachweise, subjects, klassen),
        
        // Content
        Expanded(
          child: _buildFilteredContent(students, filteredLN, subjects, klassen, grades),
        ),
      ],
    );
  }

  Widget _buildFilterChips(
    List<Leistungsnachweis> leistungsnachweise,
    List<Subject> subjects,
    List<Klasse> klassen,
  ) {
    // Sammle verfügbare Filter-Optionen
    final availableSubjectIds = leistungsnachweise.map((ln) => ln.subjectId).toSet();
    final availableKlasseIds = leistungsnachweise.map((ln) => ln.klasseId).toSet();
    final availableTypen = leistungsnachweise.map((ln) => ln.typ).toSet();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RBSSpacing.sm),
      decoration: BoxDecoration(
        color: RBSColors.paper,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Typ-Filter
            ...LeistungsnachweisTyp.values
                .where((t) => availableTypen.contains(t))
                .map((typ) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: RBSFilterChip(
                        label: typ.label,
                        selected: _selectedTyp == typ,
                        color: RBSColors.dynamicRed,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTyp = selected ? typ : null;
                          });
                        },
                      ),
                    )),
            
            // Trennstrich
            if (availableTypen.isNotEmpty && (widget.klasseId != null && availableSubjectIds.length > 1))
              Container(
                height: 24,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey[400],
              ),
            
            // Fach-Filter (nur wenn Klassen-Ansicht)
            if (widget.klasseId != null)
              ...subjects
                  .where((s) => availableSubjectIds.contains(s.id))
                  .map((subject) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: RBSFilterChip(
                          label: subject.shortName ?? subject.name,
                          selected: _selectedSubjectId == subject.id,
                          color: RBSColors.fromHex(subject.color) ?? RBSColors.courtGreen,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSubjectId = selected ? subject.id : null;
                            });
                          },
                        ),
                      )),
            
            // Klassen-Filter (nur wenn Fach-Ansicht)
            if (widget.fachId != null)
              ...klassen
                  .where((k) => availableKlasseIds.contains(k.id))
                  .map((klasse) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: RBSFilterChip(
                          label: klasse.name,
                          selected: _selectedKlasseId == klasse.id,
                          color: RBSColors.dynamicRed,
                          onSelected: (selected) {
                            setState(() {
                              _selectedKlasseId = selected ? klasse.id : null;
                            });
                          },
                        ),
                      )),
            
            // Reset-Button wenn Filter aktiv
            if (_selectedTyp != null || _selectedSubjectId != null || _selectedKlasseId != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTyp = null;
                      _selectedSubjectId = null;
                      _selectedKlasseId = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(RBSBorderRadius.small),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RBSSpacing.sm,
                      vertical: RBSSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(RBSBorderRadius.small),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('Alle', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredContent(
    List<Student> students,
    List<Leistungsnachweis> filteredLN,
    List<Subject> subjects,
    List<Klasse> klassen,
    List<Grade> grades,
  ) {
    if (filteredLN.isEmpty) {
      return const Center(
        child: Text('Keine Leistungsnachweise gefunden'),
      );
    }

    // Gruppiere nach Fach wenn Klasse-Ansicht, nach Klasse wenn Fach-Ansicht
    if (widget.klasseId != null) {
      return _buildBySubject(students, filteredLN, subjects, grades);
    } else if (widget.fachId != null) {
      return _buildByKlasse(students, filteredLN, klassen, grades);
    } else if (widget.studentId != null) {
      return _buildForStudent(students.firstOrNull, filteredLN, subjects, grades);
    }

    return const Center(child: Text('Bitte Filter auswählen'));
  }

  void _initializeNoten(
    List<Student> students,
    List<Leistungsnachweis> leistungsnachweise,
    List<Grade> grades,
  ) {
    for (final student in students) {
      for (final ln in leistungsnachweise) {
        final key = '${student.id}_${ln.id}';
        if (!_noten.containsKey(key)) {
          final existingGrade = grades
              .where((g) => g.studentId == student.id && g.leistungsnachweisId == ln.id)
              .firstOrNull;

          _noten[key] = _NotenEingabe(
            note: existingGrade?.note,
            tendenz: existingGrade?.tendenz ?? Tendenz.keine,
            kommentar: existingGrade?.kommentar,
            existingGradeId: existingGrade?.id,
            updatedBy: existingGrade?.updatedBy,
          );
        }
      }
    }
  }

  /// Ansicht gruppiert nach Fach (für Klassen-Kontext)
  /// Matrix: Schüler in Zeilen, Fächer in Spalten
  Widget _buildBySubject(
    List<Student> students,
    List<Leistungsnachweis> leistungsnachweise,
    List<Subject> subjects,
    List<Grade> grades,
  ) {
    // Gruppiere LN nach Fach
    final lnBySubject = <String, List<Leistungsnachweis>>{};
    for (final ln in leistungsnachweise) {
      lnBySubject.putIfAbsent(ln.subjectId, () => []).add(ln);
    }
    
    // Sortiere Fächer
    final sortedSubjectIds = lnBySubject.keys.toList();
    sortedSubjectIds.sort((a, b) {
      final subjectA = subjects.where((s) => s.id == a).firstOrNull;
      final subjectB = subjects.where((s) => s.id == b).firstOrNull;
      return (subjectA?.name ?? '').compareTo(subjectB?.name ?? '');
    });

    // Berechne Durchschnitte pro Schüler pro Fach
    final studentFachSchnitte = <String, Map<String, double?>>{};
    for (final student in students) {
      studentFachSchnitte[student.id] = {};
      for (final subjectId in sortedSubjectIds) {
        final fachLNs = lnBySubject[subjectId]!;
        double summe = 0;
        double gewichtung = 0;
        for (final ln in fachLNs) {
          final key = '${student.id}_${ln.id}';
          final eingabe = _noten[key];
          if (eingabe?.note != null) {
            final noteValue = _getNoteWithTendenz(eingabe!.note!, eingabe.tendenz);
            summe += noteValue * ln.gewichtung;
            gewichtung += ln.gewichtung;
          }
        }
        studentFachSchnitte[student.id]![subjectId] = gewichtung > 0 ? summe / gewichtung : null;
      }
    }
    
    // Berechne Gesamt-Durchschnitt pro Schüler
    final studentGesamtSchnitte = <String, double?>{};
    for (final student in students) {
      final fachSchnitte = studentFachSchnitte[student.id]!;
      final validSchnitte = fachSchnitte.values.where((s) => s != null).cast<double>().toList();
      studentGesamtSchnitte[student.id] = validSchnitte.isNotEmpty 
          ? validSchnitte.reduce((a, b) => a + b) / validSchnitte.length 
          : null;
    }

    return _buildFaecherMatrix(
      students: students,
      sortedSubjectIds: sortedSubjectIds,
      lnBySubject: lnBySubject,
      subjects: subjects,
      studentFachSchnitte: studentFachSchnitte,
      studentGesamtSchnitte: studentGesamtSchnitte,
    );
  }
  
  /// Matrix-Ansicht: Schüler in Zeilen, Fächer-Durchschnitte in Spalten
  Widget _buildFaecherMatrix({
    required List<Student> students,
    required List<String> sortedSubjectIds,
    required Map<String, List<Leistungsnachweis>> lnBySubject,
    required List<Subject> subjects,
    required Map<String, Map<String, double?>> studentFachSchnitte,
    required Map<String, double?> studentGesamtSchnitte,
  }) {
    // Berechne Spaltenbreite
    final fachSpaltenBreite = 85.0;
    final tableWidth = 180.0 + (sortedSubjectIds.length * fachSpaltenBreite) + 80;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: tableWidth),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header-Zeile
                  Container(
                    decoration: BoxDecoration(
                      color: RBSColors.paper,
                      border: Border(bottom: BorderSide(color: Colors.grey[400]!, width: 2)),
                    ),
                    child: Row(
                      children: [
                        // Schüler-Spalte
                        Container(
                          width: 170,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: const Text(
                            'Schüler',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        // Fach-Spalten
                        ...sortedSubjectIds.map((subjectId) {
                          final subject = subjects.where((s) => s.id == subjectId).firstOrNull;
                          final fachColor = RBSColors.fromHex(subject?.color) ?? RBSColors.courtGreen;
                          final lnCount = lnBySubject[subjectId]?.length ?? 0;
                          
                          return InkWell(
                            onTap: () => _showFachDetailDialog(
                              subject,
                              lnBySubject[subjectId] ?? [],
                              students,
                            ),
                            child: Container(
                              width: fachSpaltenBreite,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                color: fachColor.withValues(alpha: 0.1),
                                border: Border(left: BorderSide(color: fachColor, width: 3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    subject?.shortName ?? subject?.name ?? '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: fachColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$lnCount LN',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        // Gesamt-Spalte
                        Container(
                          width: 70,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: RBSColors.dynamicRed.withValues(alpha: 0.1),
                          ),
                          child: const Column(
                            children: [
                              Text('⌀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Gesamt', style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Schüler-Zeilen
                  ...students.asMap().entries.map((entry) {
                    final index = entry.key;
                    final student = entry.value;
                    final isEven = index % 2 == 0;
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : Colors.grey[50],
                        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: Row(
                        children: [
                          // Schüler-Name
                          Container(
                            width: 170,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            child: Row(
                              children: [
                                Text(
                                  '${index + 1}.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${student.lastName}, ${student.firstName}',
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Befreiungs-Indikatoren
                                      if (student.befreiungDeutsch || student.befreiungPuG) ...[
                                        const SizedBox(width: 4),
                                        Tooltip(
                                          message: [
                                            if (student.befreiungDeutsch) 'Befreiung Deutsch',
                                            if (student.befreiungPuG) 'Befreiung PuG',
                                          ].join(', '),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'B',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange[800],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Fach-Durchschnitte
                          ...sortedSubjectIds.map((subjectId) {
                            final schnitt = studentFachSchnitte[student.id]?[subjectId];
                            final subject = subjects.where((s) => s.id == subjectId).firstOrNull;
                            
                            return InkWell(
                              onTap: () => _showFachDetailDialog(
                                subject,
                                lnBySubject[subjectId] ?? [],
                                students,
                                highlightStudentId: student.id,
                              ),
                              child: Container(
                                width: fachSpaltenBreite,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                alignment: Alignment.center,
                                child: schnitt != null
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getNoteColor(schnitt.round()).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _getNoteColor(schnitt.round()).withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Text(
                                          schnitt.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: _getNoteColor(schnitt.round()),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        '-',
                                        style: TextStyle(color: Colors.grey[400]),
                                      ),
                              ),
                            );
                          }),
                          // Gesamt-Durchschnitt
                          Container(
                            width: 70,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            alignment: Alignment.center,
                            child: studentGesamtSchnitte[student.id] != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getNoteColor(studentGesamtSchnitte[student.id]!.round())
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getNoteColor(studentGesamtSchnitte[student.id]!.round()),
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      studentGesamtSchnitte[student.id]!.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: _getNoteColor(studentGesamtSchnitte[student.id]!.round()),
                                      ),
                                    ),
                                  )
                                : Text('-', style: TextStyle(color: Colors.grey[400])),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  // Footer mit Klassen-Durchschnitten
                  Container(
                    decoration: BoxDecoration(
                      color: RBSColors.paper,
                      border: Border(top: BorderSide(color: Colors.grey[400]!, width: 2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 170,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: const Text(
                            '⌀ Klasse',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        ...sortedSubjectIds.map((subjectId) {
                          final schnitte = students
                              .map((s) => studentFachSchnitte[s.id]?[subjectId])
                              .where((s) => s != null)
                              .cast<double>()
                              .toList();
                          final klassenSchnitt = schnitte.isNotEmpty
                              ? schnitte.reduce((a, b) => a + b) / schnitte.length
                              : null;
                          
                          return Container(
                            width: fachSpaltenBreite,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            alignment: Alignment.center,
                            child: klassenSchnitt != null
                                ? Text(
                                    klassenSchnitt.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getNoteColor(klassenSchnitt.round()),
                                    ),
                                  )
                                : Text('-', style: TextStyle(color: Colors.grey[400])),
                          );
                        }),
                        Container(
                          width: 70,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          alignment: Alignment.center,
                          child: () {
                            final alleSchnitte = studentGesamtSchnitte.values
                                .where((s) => s != null)
                                .cast<double>()
                                .toList();
                            final gesamtSchnitt = alleSchnitte.isNotEmpty
                                ? alleSchnitte.reduce((a, b) => a + b) / alleSchnitte.length
                                : null;
                            return gesamtSchnitt != null
                                ? Text(
                                    gesamtSchnitt.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getNoteColor(gesamtSchnitt.round()),
                                    ),
                                  )
                                : Text('-', style: TextStyle(color: Colors.grey[400]));
                          }(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Dialog mit Detail-Ansicht eines Fachs (alle LNs)
  void _showFachDetailDialog(
    Subject? subject,
    List<Leistungsnachweis> leistungsnachweise,
    List<Student> students, {
    String? highlightStudentId,
  }) {
    final fachColor = RBSColors.fromHex(subject?.color) ?? RBSColors.courtGreen;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: fachColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.book, color: fachColor),
                    const SizedBox(width: 12),
                    Text(
                      subject?.name ?? 'Fach',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: fachColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Noten-Tabelle
              Expanded(
                child: _buildNotenTable(students, leistungsnachweise),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ansicht gruppiert nach Klasse (für Fach-Kontext)
  Widget _buildByKlasse(
    List<Student> students,
    List<Leistungsnachweis> leistungsnachweise,
    List<Klasse> klassen,
    List<Grade> grades,
  ) {
    // Gruppiere LN nach Klasse
    final lnByKlasse = <String, List<Leistungsnachweis>>{};
    for (final ln in leistungsnachweise) {
      lnByKlasse.putIfAbsent(ln.klasseId, () => []).add(ln);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lnByKlasse.length,
      itemBuilder: (context, index) {
        final klasseId = lnByKlasse.keys.elementAt(index);
        final klasse = klassen.where((k) => k.id == klasseId).firstOrNull;
        final klasseLN = lnByKlasse[klasseId]!;
        
        // Schüler dieser Klasse
        final klasseStudents = students.where((s) => s.klasseId == klasseId).toList();

        return _buildKlasseSection(klasse, klasseLN, klasseStudents);
      },
    );
  }

  Widget _buildKlasseSection(
    Klasse? klasse,
    List<Leistungsnachweis> leistungsnachweise,
    List<Student> students,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Klassen-Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RBSColors.dynamicRed.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              klasse?.name ?? 'Unbekannte Klasse',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          // Noten-Tabelle
          _buildNotenTable(students, leistungsnachweise),
        ],
      ),
    );
  }

  /// Ansicht für einzelnen Schüler
  Widget _buildForStudent(
    Student? student,
    List<Leistungsnachweis> leistungsnachweise,
    List<Subject> subjects,
    List<Grade> grades,
  ) {
    if (student == null) {
      return const Center(child: Text('Schüler nicht gefunden'));
    }

    // Gruppiere LN nach Fach
    final lnBySubject = <String, List<Leistungsnachweis>>{};
    for (final ln in leistungsnachweise) {
      lnBySubject.putIfAbsent(ln.subjectId, () => []).add(ln);
    }
    
    // Berechne Gesamt-Statistik
    double gesamtSumme = 0;
    double gesamtGewichtung = 0;
    int gesamtAnzahl = 0;
    
    for (final ln in leistungsnachweise) {
      final key = '${student.id}_${ln.id}';
      final eingabe = _noten[key];
      if (eingabe?.note != null) {
        final noteValue = _getNoteWithTendenz(eingabe!.note!, eingabe.tendenz);
        gesamtSumme += noteValue * ln.gewichtung;
        gesamtGewichtung += ln.gewichtung;
        gesamtAnzahl++;
      }
    }
    
    final gesamtDurchschnitt = gesamtGewichtung > 0 ? gesamtSumme / gesamtGewichtung : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Schüler-Info Header mit Gesamt-Durchschnitt
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: RBSColors.dynamicRed,
                      child: Text(
                        student.displayName.isNotEmpty 
                            ? student.displayName[0].toUpperCase() 
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '$gesamtAnzahl von ${leistungsnachweise.length} Noten',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    // Gesamt-Durchschnitt
                    if (gesamtDurchschnitt != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getNoteColor(gesamtDurchschnitt.round()).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _getNoteColor(gesamtDurchschnitt.round()), width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '⌀ ${gesamtDurchschnitt.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _getNoteColor(gesamtDurchschnitt.round()),
                              ),
                            ),
                            Text(
                              'Gesamt',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                // Zusätzliche Schüler-Informationen
                if (student.geschlecht != null || student.religion != null || 
                    student.befreiungDeutsch || student.befreiungPuG ||
                    student.ausbildungsbetrieb != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (student.geschlecht != null && student.geschlecht!.isNotEmpty)
                        _buildInfoChip(Icons.person, student.geschlecht == 'M' ? 'Männlich' : 'Weiblich'),
                      if (student.religion != null && student.religion!.isNotEmpty)
                        _buildInfoChip(Icons.church, student.religion!),
                      if (student.befreiungDeutsch)
                        _buildInfoChip(Icons.block, 'Befreiung Deutsch', color: Colors.orange),
                      if (student.befreiungPuG)
                        _buildInfoChip(Icons.block, 'Befreiung PuG', color: Colors.orange),
                      if (student.ausbildungsbetrieb != null && student.ausbildungsbetrieb!.isNotEmpty)
                        _buildInfoChip(Icons.business, student.ausbildungsbetrieb!),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Fächer mit Noten
        ...lnBySubject.entries.map((entry) {
          final subject = subjects.where((s) => s.id == entry.key).firstOrNull;
          return _buildStudentSubjectCard(student, subject, entry.value);
        }),
      ],
    );
  }

  Widget _buildStudentSubjectCard(
    Student student,
    Subject? subject,
    List<Leistungsnachweis> leistungsnachweise,
  ) {
    // Berechne Durchschnitt für dieses Fach
    double summe = 0;
    double gewichtungsSumme = 0;
    int anzahl = 0;
    
    for (final ln in leistungsnachweise) {
      final key = '${student.id}_${ln.id}';
      final eingabe = _noten[key];
      if (eingabe?.note != null) {
        final noteValue = _getNoteWithTendenz(eingabe!.note!, eingabe.tendenz);
        summe += noteValue * ln.gewichtung;
        gewichtungsSumme += ln.gewichtung;
        anzahl++;
      }
    }
    
    final durchschnitt = gewichtungsSumme > 0 ? summe / gewichtungsSumme : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RBSColors.courtGreen.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    subject?.name ?? 'Unbekanntes Fach',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Durchschnitt Badge
                if (durchschnitt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getNoteColor(durchschnitt.round()).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getNoteColor(durchschnitt.round())),
                    ),
                    child: Text(
                      '⌀ ${durchschnitt.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _getNoteColor(durchschnitt.round()),
                      ),
                    ),
                  ),
                if (durchschnitt == null)
                  Text(
                    '$anzahl/${leistungsnachweise.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          // Einzelne Leistungsnachweise
          ...leistungsnachweise.map((ln) => _buildStudentLNRow(student, ln)),
          // Footer mit Anzahl
          if (anzahl > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '$anzahl von ${leistungsnachweise.length} Noten eingetragen',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentLNRow(Student student, Leistungsnachweis ln) {
    final key = '${student.id}_${ln.id}';
    final eingabe = _noten[key];
    if (eingabe == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // LN-Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ln.bezeichnung,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${ln.typ.label} • ${ln.gewichtung}x • ${_formatDate(ln.datum)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Note
          _buildNoteDropdown(key, eingabe, student.id, ln.id),
          const SizedBox(width: 8),
          // Tendenz
          _buildTendenzButtons(key, eingabe, student.id, ln.id),
        ],
      ),
    );
  }

  /// Noten-Tabelle mit Schülern als Zeilen und LN als Spalten
  Widget _buildNotenTable(
    List<Student> students,
    List<Leistungsnachweis> leistungsnachweise,
  ) {
    if (students.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Keine Schüler'),
      );
    }

    // Berechne Mindestbreite für horizontales Scrollen
    final tableWidth = 160.0 + (leistungsnachweise.length * 120.0);

    // Berechne Statistiken pro LN
    final lnStats = <String, _LNStatistik>{};
    for (final ln in leistungsnachweise) {
      final noten = <double>[];
      int count = 0;
      final verteilung = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
      
      for (final student in students) {
        final key = '${student.id}_${ln.id}';
        final eingabe = _noten[key];
        if (eingabe?.note != null) {
          final noteValue = _getNoteWithTendenz(eingabe!.note!, eingabe.tendenz);
          noten.add(noteValue);
          count++;
          verteilung[eingabe.note!] = (verteilung[eingabe.note!] ?? 0) + 1;
        }
      }
      
      final durchschnitt = noten.isEmpty ? null : noten.reduce((a, b) => a + b) / noten.length;
      lnStats[ln.id] = _LNStatistik(
        durchschnitt: durchschnitt,
        anzahl: count,
        gesamt: students.length,
        verteilung: verteilung,
      );
    }
    
    // Berechne Schüler-Durchschnitte
    final studentStats = <String, double?>{};
    for (final student in students) {
      final noten = <double>[];
      double gewichtungsSumme = 0;
      
      for (final ln in leistungsnachweise) {
        final key = '${student.id}_${ln.id}';
        final eingabe = _noten[key];
        if (eingabe?.note != null) {
          final noteValue = _getNoteWithTendenz(eingabe!.note!, eingabe.tendenz);
          noten.add(noteValue * ln.gewichtung);
          gewichtungsSumme += ln.gewichtung;
        }
      }
      
      studentStats[student.id] = gewichtungsSumme > 0 
          ? noten.reduce((a, b) => a + b) / gewichtungsSumme 
          : null;
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: tableWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Haupt-Tabelle
              DataTable(
                columnSpacing: 8,
                headingRowHeight: 64,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 52,
                columns: [
                  const DataColumn(
                    label: SizedBox(
                      width: 140,
                      child: Text('Schüler', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  ...leistungsnachweise.map((ln) => DataColumn(
                    label: SizedBox(
                      width: 110,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ln.bezeichnung,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          Text(
                            '${ln.typ.label} ${ln.gewichtung}x',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )),
                  // Spalte für Schüler-Durchschnitt
                  const DataColumn(
                    label: SizedBox(
                      width: 70,
                      child: Text('⌀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
                rows: students.map((student) => DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: Text(
                          student.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    ...leistungsnachweise.map((ln) {
                      final key = '${student.id}_${ln.id}';
                      final eingabe = _noten[key];
                      if (eingabe == null) return const DataCell(Text('-'));

                      return DataCell(
                        SizedBox(
                          width: 110,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCompactNoteDropdown(key, eingabe, student.id, ln.id),
                              const SizedBox(width: 4),
                              _buildCompactTendenzButtons(key, eingabe, student.id, ln.id),
                            ],
                          ),
                        ),
                      );
                    }),
                    // Schüler-Durchschnitt
                    DataCell(
                      SizedBox(
                        width: 70,
                        child: studentStats[student.id] != null
                            ? Text(
                                studentStats[student.id]!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getNoteColor(studentStats[student.id]!.round()),
                                ),
                              )
                            : const Text('-', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ],
                )).toList(),
              ),
              
              // Statistik-Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: RBSColors.paper,
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    // Schüler-Spalte Label
                    SizedBox(
                      width: 140,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⌀ Durchschnitt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Eingetragen', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Stats pro LN
                    ...leistungsnachweise.map((ln) {
                      final stats = lnStats[ln.id];
                      return SizedBox(
                        width: 118,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stats?.durchschnitt != null 
                                  ? stats!.durchschnitt!.toStringAsFixed(2)
                                  : '-',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: stats?.durchschnitt != null 
                                    ? _getNoteColor(stats!.durchschnitt!.round())
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              '${stats?.anzahl ?? 0}/${stats?.gesamt ?? 0}',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }),
                    // Gesamt-Durchschnitt
                    SizedBox(
                      width: 70,
                      child: _buildGesamtDurchschnitt(studentStats),
                    ),
                  ],
                ),
              ),
              
              // Notenverteilung
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 140,
                      child: Text('Verteilung', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    ...leistungsnachweise.map((ln) {
                      final stats = lnStats[ln.id];
                      return SizedBox(
                        width: 118,
                        child: _buildVerteilungChips(stats?.verteilung ?? {}),
                      );
                    }),
                    const SizedBox(width: 70), // Platzhalter für Durchschnitt-Spalte
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGesamtDurchschnitt(Map<String, double?> studentStats) {
    final validStats = studentStats.values.whereType<double>().toList();
    if (validStats.isEmpty) {
      return const Text('-', style: TextStyle(color: Colors.grey));
    }
    final gesamt = validStats.reduce((a, b) => a + b) / validStats.length;
    return Text(
      gesamt.toStringAsFixed(2),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: _getNoteColor(gesamt.round()),
      ),
    );
  }

  Widget _buildVerteilungChips(Map<int, int> verteilung) {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: [1, 2, 3, 4, 5, 6].where((n) => (verteilung[n] ?? 0) > 0).map((note) {
        final count = verteilung[note] ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: _getNoteColor(note).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _getNoteColor(note).withValues(alpha: 0.3)),
          ),
          child: Text(
            '$note:$count',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: _getNoteColor(note),
            ),
          ),
        );
      }).toList(),
    );
  }

  double _getNoteWithTendenz(int note, Tendenz tendenz) {
    switch (tendenz) {
      case Tendenz.plus:
        return note - 0.3; // 2+ = 1.7
      case Tendenz.minus:
        return note + 0.3; // 2- = 2.3
      case Tendenz.keine:
        return note.toDouble();
    }
  }

  Widget _buildNoteDropdown(String key, _NotenEingabe eingabe, String studentId, String lnId) {
    return SizedBox(
      width: 60,
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
              padding: const EdgeInsets.symmetric(horizontal: 6),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('-')),
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
              onChanged: (value) => _updateNote(key, studentId, lnId, value),
            ),
          ),
          if (eingabe.updatedBy != null)
            Positioned(
              right: 2,
              top: 1,
              child: Text(
                eingabe.updatedBy!,
                style: TextStyle(fontSize: 8, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactNoteDropdown(String key, _NotenEingabe eingabe, String studentId, String lnId) {
    return SizedBox(
      width: 45,
      height: 32,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<int?>(
              value: eingabe.note,
              isExpanded: true,
              underline: const SizedBox(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              iconSize: 16,
              style: const TextStyle(fontSize: 14),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('-', style: TextStyle(color: Colors.black))),
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
              onChanged: (value) => _updateNote(key, studentId, lnId, value),
            ),
          ),
          if (eingabe.updatedBy != null)
            Positioned(
              right: 1,
              top: 0,
              child: Text(
                eingabe.updatedBy!,
                style: TextStyle(fontSize: 7, color: Colors.grey[400]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTendenzButtons(String key, _NotenEingabe eingabe, String studentId, String lnId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTendenzButton(key, eingabe, studentId, lnId, Tendenz.plus, '+'),
        const SizedBox(width: 2),
        _buildTendenzButton(key, eingabe, studentId, lnId, Tendenz.keine, '·'),
        const SizedBox(width: 2),
        _buildTendenzButton(key, eingabe, studentId, lnId, Tendenz.minus, '-'),
      ],
    );
  }

  Widget _buildCompactTendenzButtons(String key, _NotenEingabe eingabe, String studentId, String lnId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactTendenzButton(key, eingabe, studentId, lnId, Tendenz.plus, '+'),
        _buildCompactTendenzButton(key, eingabe, studentId, lnId, Tendenz.keine, '·'),
        _buildCompactTendenzButton(key, eingabe, studentId, lnId, Tendenz.minus, '-'),
      ],
    );
  }

  Widget _buildTendenzButton(String key, _NotenEingabe eingabe, String studentId, String lnId, Tendenz tendenz, String label) {
    final isSelected = eingabe.tendenz == tendenz;
    return InkWell(
      onTap: () => _updateTendenz(key, studentId, lnId, tendenz),
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

  Widget _buildCompactTendenzButton(String key, _NotenEingabe eingabe, String studentId, String lnId, Tendenz tendenz, String label) {
    final isSelected = eingabe.tendenz == tendenz;
    return InkWell(
      onTap: () => _updateTendenz(key, studentId, lnId, tendenz),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isSelected ? RBSColors.dynamicRed : Colors.grey[200],
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void _updateNote(String key, String studentId, String lnId, int? value) {
    setState(() {
      _noten[key] = _noten[key]!.copyWith(note: value);
    });
    _saveGrade(key, studentId, lnId);
  }

  void _updateTendenz(String key, String studentId, String lnId, Tendenz tendenz) {
    setState(() {
      _noten[key] = _noten[key]!.copyWith(tendenz: tendenz);
    });
    _saveGrade(key, studentId, lnId);
  }

  Future<void> _saveGrade(String key, String studentId, String lnId) async {
    final eingabe = _noten[key];
    if (eingabe == null) return;
    if (_savingGrades.contains(key)) return;

    _savingGrades.add(key);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final user = ref.read(currentUserProvider);
      final userKuerzel = _getUserKuerzel(user?.email);

      if (eingabe.note != null) {
        final grade = Grade(
          id: eingabe.existingGradeId ?? '',
          studentId: studentId,
          leistungsnachweisId: lnId,
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
          _noten[key] = eingabe.copyWith(existingGradeId: newId, updatedBy: userKuerzel);
        }
        
        // Update local state with new kuerzel
        setState(() {
          _noten[key] = _noten[key]!.copyWith(updatedBy: userKuerzel);
        });
      } else if (eingabe.existingGradeId != null) {
        await firestoreService.deleteGrade(eingabe.existingGradeId!);
        _noten[key] = eingabe.copyWith(existingGradeId: null, updatedBy: null);
      }

      ref.invalidate(gradesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _savingGrades.remove(key);
    }
  }

  String _getUserKuerzel(String? email) {
    if (email == null || email.isEmpty) return '??';
    final namePart = email.split('@').first;
    if (namePart.length >= 2) {
      return namePart.substring(0, 2).toLowerCase();
    }
    return namePart.toLowerCase();
  }

  Color _getNoteColor(int note) {
    switch (note) {
      case 1: return Colors.green[700]!;
      case 2: return Colors.green;
      case 3: return Colors.orange;
      case 4: return Colors.orange[700]!;
      case 5: return Colors.red;
      case 6: return Colors.red[900]!;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Statistik für einen Leistungsnachweis
class _LNStatistik {
  final double? durchschnitt;
  final int anzahl;
  final int gesamt;
  final Map<int, int> verteilung;

  _LNStatistik({
    this.durchschnitt,
    required this.anzahl,
    required this.gesamt,
    required this.verteilung,
  });
}

/// Helper Widget für Info-Chips
Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: (color ?? Colors.grey).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: (color ?? Colors.grey).withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color ?? Colors.grey[700],
          ),
        ),
      ],
    ),
  );
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
