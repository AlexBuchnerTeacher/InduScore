// InduScore Entwicklungsstand 0.13.4 - 14.12.2025
// Refactored: Widgets ausgelagert, Screen von 2230 auf 970 Zeilen reduziert (57% Reduktion)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/core/widgets/rbs_components.dart';
import 'package:induscore/features/noten/noten_layout_constants.dart';
import 'package:induscore/features/noten/widgets/faecher_matrix_widget.dart';
import 'package:induscore/features/noten/widgets/noten_table_widget.dart';
import 'package:induscore/features/noten/widgets/student_subject_card.dart';
import 'package:induscore/models/grade.dart';
import 'package:induscore/models/klasse.dart';
import 'package:induscore/models/leistungsnachweis.dart';
import 'package:induscore/models/noten_eingabe.dart';
import 'package:induscore/models/student.dart';
import 'package:induscore/models/subject.dart';
import 'package:induscore/models/tendenz.dart';
import 'package:induscore/providers/app_providers.dart';
import 'package:induscore/widgets/rbs_drawer.dart';
import 'package:induscore/shared/widgets/app_snack_bars.dart';

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
  ConsumerState<NotenUebersichtScreen> createState() =>
      _NotenUebersichtScreenState();
}

class _NotenUebersichtScreenState extends ConsumerState<NotenUebersichtScreen> {
  final Map<String, NotenEingabe> _noten = {};
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
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: RBSColors.dynamicRed),
            onPressed: () => context.go('/'),
            tooltip: 'Zum Dashboard',
          ),
        ],
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
              data: (grades) =>
                  _buildContent(klassen, subjects, leistungsnachweise, grades),
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
      filteredLN = filteredLN
          .where((ln) => ln.klasseId == widget.klasseId)
          .toList();
    }
    if (widget.fachId != null) {
      filteredLN = filteredLN
          .where((ln) => ln.subjectId == widget.fachId)
          .toList();
    }

    // Zusätzliche Filter anwenden
    if (_selectedSubjectId != null) {
      filteredLN = filteredLN
          .where((ln) => ln.subjectId == _selectedSubjectId)
          .toList();
    }
    if (_selectedKlasseId != null) {
      filteredLN = filteredLN
          .where((ln) => ln.klasseId == _selectedKlasseId)
          .toList();
    }
    if (_selectedTyp != null) {
      filteredLN = filteredLN.where((ln) => ln.typ == _selectedTyp).toList();
    }

    // Sortiere nach Datum
    filteredLN.sort((a, b) => b.datum.compareTo(a.datum));

    // Hole relevante Schüler
    List<Student> students = [];
    if (widget.studentId != null) {
      // Einzelner Schüler - lade direkt über studentProvider
      final studentAsync = ref.watch(studentProvider(widget.studentId!));
      if (studentAsync.hasValue) {
        final student = studentAsync.value!;
        students = [student];
        // IMMER nach Klasse des Schülers filtern, nicht nur wenn leer!
        filteredLN = filteredLN
            .where((ln) => ln.klasseId == student.klasseId)
            .toList();
        filteredLN.sort((a, b) => b.datum.compareTo(a.datum));
      }
    } else if (widget.klasseId != null) {
      final studentAsync = ref.watch(
        studentsByKlasseProvider(widget.klasseId!),
      );
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
          child: _buildFilteredContent(
            students,
            filteredLN,
            subjects,
            klassen,
            grades,
          ),
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
    final availableSubjectIds = leistungsnachweise
        .map((ln) => ln.subjectId)
        .toSet();
    final availableKlasseIds = leistungsnachweise
        .map((ln) => ln.klasseId)
        .toSet();
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
                .where(availableTypen.contains)
                .map(
                  (typ) => Padding(
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
                  ),
                ),

            // Trennstrich
            if (availableTypen.isNotEmpty &&
                (widget.klasseId != null && availableSubjectIds.length > 1))
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
                  .map(
                    (subject) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: RBSFilterChip(
                        label: subject.shortName ?? subject.name,
                        selected: _selectedSubjectId == subject.id,
                        color:
                            RBSColors.fromHex(subject.color) ??
                            RBSColors.courtGreen,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSubjectId = selected ? subject.id : null;
                          });
                        },
                      ),
                    ),
                  ),

            // Klassen-Filter (nur wenn Fach-Ansicht)
            if (widget.fachId != null)
              ...klassen
                  .where((k) => availableKlasseIds.contains(k.id))
                  .map(
                    (klasse) => Padding(
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
                    ),
                  ),

            // Reset-Button wenn Filter aktiv
            if (_selectedTyp != null ||
                _selectedSubjectId != null ||
                _selectedKlasseId != null)
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
                      borderRadius: BorderRadius.circular(
                        RBSBorderRadius.small,
                      ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.grey[400], size: 48),
            const SizedBox(height: 12),
            Text(
              'Kein Leistungsnachweis vorhanden',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Der Schüler ist trotzdem sichtbar und kann Noten erhalten.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Gruppiere nach Fach wenn Klasse-Ansicht, nach Klasse wenn Fach-Ansicht
    if (widget.klasseId != null) {
      return _buildBySubject(students, filteredLN, subjects, grades);
    } else if (widget.fachId != null) {
      return _buildByKlasse(students, filteredLN, klassen, grades);
    } else if (widget.studentId != null) {
      return _buildForStudent(
        students.firstOrNull,
        filteredLN,
        subjects,
        grades,
      );
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
              .where(
                (g) =>
                    g.studentId == student.id && g.leistungsnachweisId == ln.id,
              )
              .firstOrNull;

          _noten[key] = NotenEingabe(
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

    // Sortiere Fächer - use Map for O(1) lookup
    final sortedSubjectIds = lnBySubject.keys.toList();
    final subjectsMap = {for (final s in subjects) s.id: s};
    sortedSubjectIds.sort((a, b) {
      final subjectA = subjectsMap[a];
      final subjectB = subjectsMap[b];
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
            final noteValue = _getNoteWithTendenz(
              eingabe!.note!,
              eingabe.tendenz,
            );
            summe += noteValue * ln.gewichtung;
            gewichtung += ln.gewichtung;
          }
        }
        studentFachSchnitte[student.id]![subjectId] = gewichtung > 0
            ? summe / gewichtung
            : null;
      }
    }

    // Berechne Gesamt-Durchschnitt pro Schüler
    final studentGesamtSchnitte = <String, double?>{};
    for (final student in students) {
      final fachSchnitte = studentFachSchnitte[student.id]!;
      final validSchnitte = fachSchnitte.values
          .where((s) => s != null)
          .cast<double>()
          .toList();
      studentGesamtSchnitte[student.id] = validSchnitte.isNotEmpty
          ? validSchnitte.reduce((a, b) => a + b) / validSchnitte.length
          : null;
    }

    return FaecherMatrixWidget(
      students: students,
      sortedSubjectIds: sortedSubjectIds,
      lnBySubject: lnBySubject,
      subjects: subjects,
      studentFachSchnitte: studentFachSchnitte,
      studentGesamtSchnitte: studentGesamtSchnitte,
      onFachDetailTap: _showFachDetailDialog,
      getNoteColor: _getNoteColor,
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
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
                child: NotenTableWidget(
                  students: students,
                  leistungsnachweise: leistungsnachweise,
                  noten: _noten,
                  onNoteChanged: _updateNote,
                  onTendenzChanged: _updateTendenz,
                  getNoteColor: _getNoteColor,
                  getNoteWithTendenz: _getNoteWithTendenz,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [GELÖSCHT: _buildFaecherMatrix_OLD + _buildByKlasse - ~850 Zeilen - Nun in separate Widgets ausgelagert]

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

    // O(1) lookup map
    final klassenMap = {for (final k in klassen) k.id: k};

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lnByKlasse.length,
      itemBuilder: (context, index) {
        final klasseId = lnByKlasse.keys.elementAt(index);
        final klasse = klassenMap[klasseId];
        final klasseLN = lnByKlasse[klasseId]!;

        // Schüler dieser Klasse
        final klasseStudents = students
            .where((s) => s.klasseId == klasseId)
            .toList();

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              klasse?.name ?? 'Unbekannte Klasse',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          // Noten-Tabelle
          NotenTableWidget(
            students: students,
            leistungsnachweise: leistungsnachweise,
            noten: _noten,
            onNoteChanged: _updateNote,
            onTendenzChanged: _updateTendenz,
            getNoteColor: _getNoteColor,
            getNoteWithTendenz: _getNoteWithTendenz,
          ),
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

    // O(1) lookup map for subjects
    final subjectsMap = {for (final s in subjects) s.id: s};

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

    final gesamtDurchschnitt = gesamtGewichtung > 0
        ? gesamtSumme / gesamtGewichtung
        : null;

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
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Gesamt-Durchschnitt
                    if (gesamtDurchschnitt != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getNoteColor(
                            gesamtDurchschnitt.round(),
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getNoteColor(gesamtDurchschnitt.round()),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '⌀ ${gesamtDurchschnitt.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _getNoteColor(
                                  gesamtDurchschnitt.round(),
                                ),
                              ),
                            ),
                            Text(
                              'Gesamt',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                // Zusätzliche Schüler-Informationen
                if (student.geschlecht != null ||
                    student.religion != null ||
                    student.befreiungDeutsch ||
                    student.befreiungPuG ||
                    student.ausbildungsbetrieb != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (student.geschlecht != null &&
                          student.geschlecht!.isNotEmpty)
                        _buildInfoChip(
                          Icons.person,
                          student.geschlecht == 'M' ? 'Männlich' : 'Weiblich',
                        ),
                      if (student.religion != null &&
                          student.religion!.isNotEmpty)
                        _buildInfoChip(Icons.church, student.religion!),
                      if (student.befreiungDeutsch)
                        _buildInfoChip(
                          Icons.block,
                          'Befreiung Deutsch',
                          color: Colors.orange,
                        ),
                      if (student.befreiungPuG)
                        _buildInfoChip(
                          Icons.block,
                          'Befreiung PuG',
                          color: Colors.orange,
                        ),
                      if (student.ausbildungsbetrieb != null &&
                          student.ausbildungsbetrieb!.isNotEmpty)
                        _buildInfoChip(
                          Icons.business,
                          student.ausbildungsbetrieb!,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Fächer mit Noten - O(1) lookup
        ...lnBySubject.entries.map((entry) {
          final subject = subjectsMap[entry.key];
          return StudentSubjectCard(
            student: student,
            subject: subject,
            leistungsnachweise: entry.value,
            noten: _noten,
            onNoteChanged: _updateNote,
            onTendenzChanged: _updateTendenz,
            getNoteColor: _getNoteColor,
            getNoteWithTendenz: _getNoteWithTendenz,
            formatDate: _formatDate,
          );
        }),
      ],
    );
  }

  // [ENTFERNT & AUSGELAGERT: ~1260 Zeilen in separate Widget-Dateien]
  // - NotenTableWidget: _buildNotenTable, _buildGesamtDurchschnitt, _buildVerteilungChips (~400 Zeilen)
  // - note_input_widgets.dart: _buildNoteDropdown, _buildTendenzButtons, _buildTendenzButton (~150 Zeilen)
  // - StudentSubjectCard: _buildStudentSubjectCard, _buildStudentLNRow (~130 Zeilen)
  // - FaecherMatrixWidget: _buildFaecherMatrix (~530 Zeilen)
  // - _LNStatistik, _buildCompact* Methoden (~50 Zeilen)

  /// Gibt die Note als double zurück
  /// 
  /// HINWEIS: Tendenzen werden NICHT in die Berechnung einbezogen!
  /// Sie dienen nur als visueller Indikator.
  double _getNoteWithTendenz(int note, Tendenz tendenz) {
    // Tendenz wird ignoriert - nur Indikator, keine Berechnung
    return note.toDouble();
  }

  void _updateNote(String key, String studentId, String lnId, int? value) {
    setState(() {
      _noten[key] = _noten[key]!.copyWith(note: value);
    });
    _saveGrade(key, studentId, lnId);
  }

  void _updateTendenz(
    String key,
    String studentId,
    String lnId,
    Tendenz tendenz,
  ) {
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
      // Kürzel aus zentralem Provider
      final userKuerzel = ref.read(currentUserKuerzelProvider);

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
          _noten[key] = eingabe.copyWith(
            existingGradeId: newId,
            updatedBy: userKuerzel,
          );
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
        AppSnackBars.showError(context, 'Fehler', error: e);
      }
    } finally {
      _savingGrades.remove(key);
    }
  }

  /// Gibt die Farbe für eine Note zurück (verwendet zentrale Konstanten)
  Color _getNoteColor(int note) {
    return NotenColors.getColor(note);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Helper Widget für Info-Chips
Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: (color ?? Colors.grey).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: (color ?? Colors.grey).withValues(alpha: 0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[700]),
        const SizedBox(width: 6),
        Text(
          label.trim(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: color ?? Colors.grey[700],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ],
    ),
  );
}
