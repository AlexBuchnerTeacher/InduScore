import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/rbs_theme.dart';
import '../../core/widgets/rbs_components.dart';
import '../../models/leistungsnachweis.dart';
import '../../models/subject.dart';
import '../../models/student.dart';
import '../../models/grade.dart';
import '../../models/klasse.dart';
import '../../providers/app_providers.dart';
import '../noten/widgets/noten_matrix_view.dart';
import '../../widgets/rbs_drawer.dart';

/// Klassen-Detail Screen mit Matrix-Ansicht
/// 
/// Zeigt alle Schüler einer Klasse mit ihren Noten in allen Fächern.
/// Nutzt NotenMatrixView im byKlasse-Modus.
/// 
/// Features:
/// - Horizontal scrollbare Fächer-Spalten
/// - Filter nach Fach und LN-Typ
/// - Inline-Editing der Noten
/// - Fach- und Klassen-Durchschnitte
/// - Cross-Links zu Schüler/Fach/LN
/// 
/// UI Guidelines: <300 Zeilen
class KlassenDetailScreen extends ConsumerStatefulWidget {
  final String klasseId;

  const KlassenDetailScreen({
    required this.klasseId, super.key,
  });

  @override
  ConsumerState<KlassenDetailScreen> createState() => _KlassenDetailScreenState();
}

class _KlassenDetailScreenState extends ConsumerState<KlassenDetailScreen> {
  String? _selectedSubjectId;
  LeistungsnachweisTyp? _selectedTyp;

  @override
  Widget build(BuildContext context) {
    final klasseAsync = ref.watch(klasseProvider(widget.klasseId));
    final studentsAsync = ref.watch(studentsByKlasseProvider(widget.klasseId));
    final subjectsAsync = ref.watch(subjectsProvider);
    final leistungsnachweiseAsync = ref.watch(leistungsnachweiseProvider);
    final gradesAsync = ref.watch(gradesProvider);
    final klassenListAsync = ref.watch(klassenProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/klassen');
            }
          },
        ),
        title: klasseAsync.when(
          data: (klasse) => Text('Klasse ${klasse.name}'),
          loading: () => const Text('Laden...'),
          error: (_, _) => const Text('Klasse'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: 'Zum Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(studentsByKlasseProvider(widget.klasseId));
              ref.invalidate(leistungsnachweiseProvider);
              ref.invalidate(gradesProvider);
            },
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      drawer: const RBSDrawer(),
      body: klasseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Fehler beim Laden: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/klassen');
                  }
                },
                child: const Text('Zurück zur Übersicht'),
              ),
            ],
          ),
        ),
        data: (klasse) => studentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Fehler: $e')),
          data: (students) => subjectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Fehler: $e')),
            data: (subjects) => leistungsnachweiseAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Fehler: $e')),
              data: (allLN) => gradesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Fehler: $e')),
                data: (grades) => klassenListAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Fehler: $e')),
                  data: (klassenList) => _buildContent(
                    klasse: klasse,
                    students: students,
                    subjects: subjects,
                    allLN: allLN,
                    grades: grades,
                    klassenList: klassenList,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required Klasse klasse,
    required List<Student> students,
    required List<Subject> subjects,
    required List<Leistungsnachweis> allLN,
    required List<Grade> grades,
    required List<Klasse> klassenList,
  }) {
    // Filter LNs für diese Klasse (schon durch ZG-Filter vorher gefiltert)
    final filteredLN = ref.watch(filteredLeistungsnachweiseProvider);
    var klasseLN = filteredLN.where((ln) => ln.klasseId == widget.klasseId).toList();

    // Anwenden zusätzlicher Filter
    if (_selectedSubjectId != null) {
      klasseLN = klasseLN.where((ln) => ln.subjectId == _selectedSubjectId).toList();
    }
    if (_selectedTyp != null) {
      klasseLN = klasseLN.where((ln) => ln.typ == _selectedTyp).toList();
    }

    // Verfügbare Fächer und Typen für Filter
    final availableSubjectIds = <String>[
      ...klasseLN.map((ln) => ln.subjectId).toSet()
    ];
    final availableTypen = <LeistungsnachweisTyp>[
      ...klasseLN.map((ln) => ln.typ).toSet()
    ];

    if (students.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'Keine Schüler',
        subtitle: 'Diese Klasse hat noch keine Schüler',
      );
    }

    if (klasseLN.isEmpty) {
      return Column(
        children: [
          _buildFilterBar(subjects, availableSubjectIds, availableTypen),
          Expanded(
            child: _buildEmptyState(
              icon: Icons.assignment_outlined,
              title: 'Keine Leistungsnachweise',
              subtitle: _selectedSubjectId != null || _selectedTyp != null
                  ? 'Keine LNs mit den gewählten Filtern'
                  : 'Noch keine Leistungsnachweise angelegt',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Filter Bar
        _buildFilterBar(subjects, availableSubjectIds, availableTypen),
        
        // Matrix View
        Expanded(
          child: NotenMatrixView(
            mode: MatrixViewMode.byKlasse,
            klasseId: widget.klasseId,
            students: students,
            leistungsnachweise: klasseLN,
            subjects: subjects,
            grades: grades,
            klassen: klassenList,
            onStudentTap: (studentId) {
              context.go('/schueler/$studentId');
            },
            onSubjectTap: (subjectId) {
              context.go('/faecher/$subjectId');
            },
            onLNTap: (lnId) {
              context.go('/noten/$lnId');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
    List<Subject> subjects,
    List<String> availableSubjectIds,
    List<LeistungsnachweisTyp> availableTypen,
  ) {
    final hasActiveFilter = _selectedSubjectId != null || _selectedTyp != null;

    return Container(
      padding: const EdgeInsets.all(RBSSpacing.md),
      decoration: BoxDecoration(
        color: RBSColors.paper,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
              // Typ-Filter
              ...availableTypen.map(
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
            if (availableTypen.isNotEmpty && availableSubjectIds.length > 1)
              Container(
                height: 24,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey[400],
              ),

            // Fach-Filter
            ...subjects
                .where((s) => availableSubjectIds.contains(s.id))
                .map(
                  (subject) => Padding(
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
                  ),
                ),

            // Reset-Button
            if (hasActiveFilter)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTyp = null;
                      _selectedSubjectId = null;
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
