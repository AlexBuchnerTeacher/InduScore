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

    // Sortiere Schüler
    students.sort((a, b) => a.displayName.compareTo(b.displayName));

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
                      child: FilterChip(
                        label: Text(typ.label),
                        selected: _selectedTyp == typ,
                        selectedColor: RBSColors.dynamicRed.withValues(alpha: 0.2),
                        checkmarkColor: RBSColors.dynamicRed,
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
                        child: FilterChip(
                          label: Text(subject.shortName ?? subject.name),
                          selected: _selectedSubjectId == subject.id,
                          selectedColor: RBSColors.courtGreen.withValues(alpha: 0.2),
                          checkmarkColor: RBSColors.courtGreen,
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
                        child: FilterChip(
                          label: Text(klasse.name),
                          selected: _selectedKlasseId == klasse.id,
                          selectedColor: RBSColors.dynamicRed.withValues(alpha: 0.2),
                          checkmarkColor: RBSColors.dynamicRed,
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
                child: ActionChip(
                  avatar: const Icon(Icons.clear, size: 16),
                  label: const Text('Alle'),
                  onPressed: () {
                    setState(() {
                      _selectedTyp = null;
                      _selectedSubjectId = null;
                      _selectedKlasseId = null;
                    });
                  },
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lnBySubject.length,
      itemBuilder: (context, index) {
        final subjectId = lnBySubject.keys.elementAt(index);
        final subject = subjects.where((s) => s.id == subjectId).firstOrNull;
        final subjectLN = lnBySubject[subjectId]!;

        return _buildSubjectSection(subject, subjectLN, students);
      },
    );
  }

  Widget _buildSubjectSection(
    Subject? subject,
    List<Leistungsnachweis> leistungsnachweise,
    List<Student> students,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fach-Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RBSColors.courtGreen.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              subject?.name ?? 'Unbekanntes Fach',
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Schüler-Info Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                Text(
                  student.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
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
            child: Text(
              subject?.name ?? 'Unbekanntes Fach',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // Einzelne Leistungsnachweise
          ...leistungsnachweise.map((ln) => _buildStudentLNRow(student, ln)),
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

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: tableWidth),
          child: DataTable(
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
              ],
            )).toList(),
          ),
        ),
      ),
    );
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
