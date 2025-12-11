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

/// Fächer-Detail Screen mit Matrix-Ansicht
/// 
/// Zeigt alle Schüler mit ihren Noten in einem Fach.
/// Nutzt NotenMatrixView im byKlasse-Modus mit Fach-Filter.
/// 
/// Features:
/// - Alle Klassen zusammen für ein Fach
/// - Horizontal scrollbare LN-Spalten
/// - Filter nach Klasse und LN-Typ
/// - Inline-Editing der Noten
/// - Fach-Durchschnitt über alle Klassen
/// - Cross-Links zu Schüler/Klasse/LN
/// 
/// UI Guidelines: <300 Zeilen
class FaecherDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;

  const FaecherDetailScreen({
    super.key,
    required this.subjectId,
  });

  @override
  ConsumerState<FaecherDetailScreen> createState() => _FaecherDetailScreenState();
}

class _FaecherDetailScreenState extends ConsumerState<FaecherDetailScreen> {
  String? _selectedKlasseId;
  LeistungsnachweisTyp? _selectedTyp;

  @override
  Widget build(BuildContext context) {
    final subjectAsync = ref.watch(subjectProvider(widget.subjectId));
    final studentsAsync = ref.watch(studentsProvider);
    final klassenAsync = ref.watch(klassenProvider);
    final leistungsnachweiseAsync = ref.watch(leistungsnachweiseProvider);
    final gradesAsync = ref.watch(gradesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/faecher'),
        ),
        title: subjectAsync.when(
          data: (subject) => Text('Fach: ${subject.shortName ?? subject.name}'),
          loading: () => const Text('Laden...'),
          error: (_, _) => const Text('Fach'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(studentsProvider);
              ref.invalidate(leistungsnachweiseProvider);
              ref.invalidate(gradesProvider);
            },
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      drawer: const RBSDrawer(),
      body: subjectAsync.when(
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
                onPressed: () => context.go('/faecher'),
                child: const Text('Zurück zur Übersicht'),
              ),
            ],
          ),
        ),
        data: (subject) => studentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Fehler: $e')),
          data: (allStudents) => klassenAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Fehler: $e')),
            data: (klassen) => leistungsnachweiseAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Fehler: $e')),
              data: (allLN) => gradesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Fehler: $e')),
                data: (grades) => _buildContent(
                  subject: subject,
                  allStudents: allStudents,
                  klassen: klassen,
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
    required Subject subject,
    required List<Student> allStudents,
    required List<Klasse> klassen,
    required List<Leistungsnachweis> allLN,
    required List<Grade> grades,
  }) {
    // Filter nach Zeitgruppe, dann nach diesem Fach
    final zgFilteredLN = ref.watch(filteredLeistungsnachweiseProvider);
    final zgFilteredKlassen = ref.watch(filteredKlassenProvider);
    var filteredLN = zgFilteredLN.where((ln) => ln.subjectId == widget.subjectId).toList();

    // Anwenden zusätzlicher Filter
    if (_selectedKlasseId != null) {
      filteredLN = filteredLN.where((ln) => ln.klasseId == _selectedKlasseId).toList();
    }
    if (_selectedTyp != null) {
      filteredLN = filteredLN.where((ln) => ln.typ == _selectedTyp).toList();
    }

    // Filter Schüler: Nur Schüler aus ZG-gefilterten Klassen mit LNs in diesem Fach
    final relevantKlasseIds = filteredLN.map((ln) => ln.klasseId).toSet();
    final filteredStudents = allStudents
        .where((s) => relevantKlasseIds.contains(s.klasseId))
        .toList();

    // Verfügbare Klassen (nur ZG-gefilterte) und Typen für Filter
    final lnKlasseIds = filteredLN.map((ln) => ln.klasseId).toSet();
    final availableKlasseIds = <String>[...lnKlasseIds];
    final availableKlassen = zgFilteredKlassen.where((k) => availableKlasseIds.contains(k.id)).toList();
    final lnTypen = filteredLN.map((ln) => ln.typ).toSet();
    final availableTypen = <LeistungsnachweisTyp>[...lnTypen];

    if (filteredStudents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'Keine Schüler',
        subtitle: 'Keine Schüler in Klassen mit diesem Fach',
      );
    }

    if (filteredLN.isEmpty) {
      return Column(
        children: [
          _buildFilterBar(availableKlassen, availableKlasseIds, availableTypen),
          Expanded(
            child: _buildEmptyState(
              icon: Icons.assignment_outlined,
              title: 'Keine Leistungsnachweise',
              subtitle: _selectedKlasseId != null || _selectedTyp != null
                  ? 'Keine LNs mit den gewählten Filtern'
                  : 'Noch keine Leistungsnachweise für dieses Fach',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Filter Bar
        _buildFilterBar(availableKlassen, availableKlasseIds, availableTypen),
        
        // Matrix View - nutze byKlasse mode mit aggregierten Daten
        Expanded(
          child: NotenMatrixView(
            mode: MatrixViewMode.byKlasse,
            klasseId: null, // null = alle Klassen
            students: filteredStudents,
            leistungsnachweise: filteredLN,
            subjects: [subject],
            grades: grades,
            klassen: klassen,
            onStudentTap: (studentId) {
              context.push('/schueler/$studentId');
            },
            onSubjectTap: null, // Kein Subject-Tap in Fach-Detail
            onLNTap: (lnId) {
              context.push('/leistungsnachweis/$lnId/edit');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
    List<Klasse> klassen,
    List<String> availableKlasseIds,
    List<LeistungsnachweisTyp> availableTypen,
  ) {
    final hasActiveFilter = _selectedKlasseId != null || _selectedTyp != null;

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
            if (availableTypen.isNotEmpty && availableKlasseIds.length > 1)
              Container(
                height: 24,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey[400],
              ),

            // Klassen-Filter
            ...klassen
                .where((k) => availableKlasseIds.contains(k.id))
                .map(
                  (klasse) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: RBSFilterChip(
                      label: klasse.name,
                      selected: _selectedKlasseId == klasse.id,
                      color: RBSColors.courtGreen,
                      onSelected: (selected) {
                        setState(() {
                          _selectedKlasseId = selected ? klasse.id : null;
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
