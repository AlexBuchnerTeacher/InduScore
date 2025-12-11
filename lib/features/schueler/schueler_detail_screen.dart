import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/rbs_theme.dart';
import '../../core/widgets/rbs_components.dart';
import '../../models/leistungsnachweis.dart';
import '../../providers/app_providers.dart';
import '../../widgets/rbs_drawer.dart';
import '../noten/widgets/noten_matrix_view.dart';

/// Schüler-Detail Screen mit NotenMatrixView
/// 
/// Zeigt alle Leistungsnachweise eines Schülers gruppiert nach Fach
/// - Horizontal scrollbare Fächer
/// - Inline-Editing
/// - Durchschnitte pro Fach und Gesamt
/// - Filter nach Fach und LN-Typ
/// 
/// UI Guidelines: <300 Zeilen
class SchuelerDetailScreen extends ConsumerStatefulWidget {
  final String schuelerId;

  const SchuelerDetailScreen({
    super.key,
    required this.schuelerId,
  });

  @override
  ConsumerState<SchuelerDetailScreen> createState() =>
      _SchuelerDetailScreenState();
}

class _SchuelerDetailScreenState extends ConsumerState<SchuelerDetailScreen> {
  String? _selectedSubjectId;
  LeistungsnachweisTyp? _selectedTyp;

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentProvider(widget.schuelerId));
    final klassenAsync = ref.watch(klassenProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final leistungsnachweiseAsync = ref.watch(leistungsnachweiseProvider);
    final gradesAsync = ref.watch(gradesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/schueler'),
        ),
        title: studentAsync.when(
          data: (student) => Text('${student.lastName}, ${student.firstName}'),
          loading: () => const Text('Schüler-Detail'),
          error: (_, __) => const Text('Fehler'),
        ),
      ),
      drawer: const RBSDrawer(),
      body: studentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Fehler: $e')),
        data: (student) => klassenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Fehler: $e')),
          data: (klassen) => subjectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Fehler: $e')),
            data: (subjects) => leistungsnachweiseAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Fehler: $e')),
              data: (allLN) => gradesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Fehler: $e')),
                data: (grades) => _buildContent(
                  student: student,
                  klassen: klassen,
                  subjects: subjects,
                  allLN: allLN,
                  grades: grades,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required student,
    required klassen,
    required subjects,
    required allLN,
    required grades,
  }) {
    // Filter LNs: Nur LNs der Klasse des Schülers
    var filteredLN = allLN
        .where((ln) => ln.klasseId == student.klasseId)
        .toList();

    // Zusätzliche Filter anwenden
    if (_selectedSubjectId != null) {
      filteredLN = filteredLN
          .where((ln) => ln.subjectId == _selectedSubjectId)
          .toList();
    }
    if (_selectedTyp != null) {
      filteredLN = filteredLN.where((ln) => ln.typ == _selectedTyp).toList();
    }

    // Verfügbare Fächer und Typen für Filter
    final availableSubjectIds = filteredLN
        .map((ln) => ln.subjectId)
        .toSet()
        .toList()
        .cast<String>();
    final availableTypen = filteredLN
        .map((ln) => ln.typ)
        .toSet()
        .toList()
        .cast<LeistungsnachweisTyp>();

    if (filteredLN.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Keine Leistungsnachweise',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Für diesen Schüler sind noch keine LNs erfasst',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filter Bar
        _buildFilterBar(subjects, availableSubjectIds, availableTypen),

        // Matrix View
        Expanded(
          child: NotenMatrixView(
            mode: MatrixViewMode.bySchueler,
            schuelerId: widget.schuelerId,
            students: [student],
            leistungsnachweise: filteredLN,
            subjects: subjects,
            grades: grades,
            klassen: klassen,
            onSubjectTap: (subjectId) {
              context.push('/faecher/$subjectId');
            },
            onLNTap: (lnId) {
              context.push('/leistungsnachweis/$lnId/edit');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
    List subjects,
    List<String> availableSubjectIds,
    List<LeistungsnachweisTyp> availableTypen,
  ) {
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
            ...availableTypen.map((typ) {
              return Padding(
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
              );
            }),

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
                .map((subject) {
              return Padding(
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
              );
            }),

            // Reset-Button wenn Filter aktiv
            if (_selectedTyp != null || _selectedSubjectId != null)
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
}
