import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/core/widgets/rbs_components.dart';
import 'package:induscore/models/leistungsnachweis.dart';
import 'package:induscore/models/subject.dart';
import 'package:induscore/models/student.dart';
import 'package:induscore/models/grade.dart';
import 'package:induscore/models/klasse.dart';
import 'package:induscore/models/beruf.dart';
import 'package:induscore/providers/app_providers.dart';
import 'package:induscore/widgets/rbs_drawer.dart';

/// Fächer-Detail Screen mit Klassen-Übersicht
/// 
/// Zeigt alle Klassen, die dieses Fach belegen.
/// 
/// Features:
/// - Liste der Klassen mit Statistiken:
///   - Anzahl Schüler
///   - Anzahl offene Nachschreiber
///   - Anzahl Noten in diesem Fach
///   - Durchschnittsnote (alle LNs dieses Fachs)
/// - Filter nach Beruf (übernommen + änderbar)
/// - Bei Klick auf Klasse → Klassendetailansicht
/// 
/// UI Guidelines: <400 Zeilen
class FaecherDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;

  const FaecherDetailScreen({
    required this.subjectId, super.key,
  });

  @override
  ConsumerState<FaecherDetailScreen> createState() => _FaecherDetailScreenState();
}

class _FaecherDetailScreenState extends ConsumerState<FaecherDetailScreen> {
  // ignore: prefer_final_fields
  Set<Beruf> _selectedBerufe = {};

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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/faecher');
            }
          },
        ),
        title: subjectAsync.when(
          data: (subject) => Text('Fach: ${subject.shortName ?? subject.name}'),
          loading: () => const Text('Laden...'),
          error: (_, _) => const Text('Fach'),
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
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/faecher');
                  }
                },
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
    // Filter nach Zeitgruppe
    final zgFilteredKlassen = ref.watch(filteredKlassenProvider);
    
    // Nur Klassen, die dieses Fach belegen (LNs vorhanden)
    final lnsForSubject = allLN.where((ln) => ln.subjectId == widget.subjectId).toList();
    final klasseIdsWithLN = lnsForSubject.map((ln) => ln.klasseId).toSet();
    var filteredKlassen = zgFilteredKlassen
        .where((k) => klasseIdsWithLN.contains(k.id))
        .toList();

    // Beruf-Filter anwenden
    if (_selectedBerufe.isNotEmpty) {
      filteredKlassen = filteredKlassen.where((k) => _selectedBerufe.contains(k.beruf)).toList();
    }

    // Nach Name sortieren
    filteredKlassen.sort((a, b) => a.name.compareTo(b.name));

    // Verfügbare Berufe für Filter
    final availableBerufe = filteredKlassen.map((k) => k.beruf).toSet().toList();

    if (filteredKlassen.isEmpty) {
      return Column(
        children: [
          _buildFilterBar(availableBerufe),
          Expanded(
            child: _buildEmptyState(
              icon: Icons.school_outlined,
              title: 'Keine Klassen',
              subtitle: _selectedBerufe.isNotEmpty
                  ? 'Keine Klassen mit den gewählten Berufen belegen dieses Fach'
                  : 'Noch keine Klassen belegen dieses Fach',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Beruf-Filter Bar
        _buildFilterBar(availableBerufe),
        
        // Klassen-Liste
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(RBSSpacing.md),
            itemCount: filteredKlassen.length,
            itemBuilder: (context, index) {
              final klasse = filteredKlassen[index];
              return _buildKlasseCard(
                klasse: klasse,
                subject: subject,
                students: allStudents,
                lns: lnsForSubject,
                grades: grades,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(List<Beruf> availableBerufe) {
    final zeitgruppen = ref.watch(zeitgruppenFilterProvider);

    return Container(
      padding: const EdgeInsets.all(RBSSpacing.md),
      decoration: BoxDecoration(
        color: RBSColors.paper,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Wrap(
        spacing: RBSSpacing.sm,
        runSpacing: RBSSpacing.sm,
        children: [
          // Zeitgruppen-Filter (ZG1, ZG2, ZG3)
          RBSFilterChip(
            label: 'ZG1',
            selected: zeitgruppen.contains(1),
            color: RBSColors.courtGreen,
            onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(1),
          ),
          RBSFilterChip(
            label: 'ZG2',
            selected: zeitgruppen.contains(2),
            color: RBSColors.courtGreen,
            onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(2),
          ),
          RBSFilterChip(
            label: 'ZG3',
            selected: zeitgruppen.contains(3),
            color: RBSColors.courtGreen,
            onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(3),
          ),
          
          const SizedBox(width: RBSSpacing.md), // Spacer
          
          // Beruf-Filter (IE, EAT, EBT, EGS)
          ...Beruf.values.map(
            (beruf) => RBSFilterChip(
              label: beruf.code,
              selected: _selectedBerufe.contains(beruf),
              color: _getBerufColor(beruf),
              onSelected: availableBerufe.contains(beruf)
                  ? (_) {
                      setState(() {
                        if (_selectedBerufe.contains(beruf)) {
                          _selectedBerufe.remove(beruf);
                        } else {
                          _selectedBerufe.add(beruf);
                        }
                      });
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKlasseCard({
    required Klasse klasse,
    required Subject subject,
    required List<Student> students,
    required List<Leistungsnachweis> lns,
    required List<Grade> grades,
  }) {
    // Statistiken für diese Klasse
    final klasseStudents = students.where((s) => s.klasseId == klasse.id && s.isAktiv).toList();
    final klasseLNs = lns.where((ln) => ln.klasseId == klasse.id).toList();
    final klasseLNIds = klasseLNs.map((ln) => ln.id).toSet();
    final klasseGrades = grades.where((g) => klasseLNIds.contains(g.leistungsnachweisId)).toList();

    // Offene Nachschreiber berechnen
    // Ein Schüler ist Nachschreiber wenn er KEINE Note für einen LN hat, aber andere haben
    int nachschreiberCount = 0;
    for (final ln in klasseLNs) {
      final gradesForLN = klasseGrades.where((g) => g.leistungsnachweisId == ln.id).toList();
      if (gradesForLN.isNotEmpty) {
        // Es gibt bereits Noten für diesen LN
        final studentIdsWithGrade = gradesForLN.map((g) => g.studentId).toSet();
        nachschreiberCount += klasseStudents.where((s) => !studentIdsWithGrade.contains(s.id)).length;
      }
    }

    // Durchschnittsnote berechnen
    final notenValues = klasseGrades.map((g) => g.note).toList();
    final durchschnitt = notenValues.isEmpty
        ? null
        : notenValues.reduce((a, b) => a + b) / notenValues.length;

    return Card(
      margin: const EdgeInsets.only(bottom: RBSSpacing.md),
      child: InkWell(
        onTap: () => context.push('/klassen/${klasse.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(RBSSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Klassenname + Beruf-Badge
              Row(
                children: [
                  Text(
                    klasse.name,
                    style: RBSTypography.h3,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBerufColor(klasse.beruf).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getBerufColor(klasse.beruf)),
                    ),
                    child: Text(
                      klasse.beruf.code,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getBerufColor(klasse.beruf),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: RBSSpacing.md),
              
              // Statistiken in Grid
              Wrap(
                spacing: RBSSpacing.lg,
                runSpacing: RBSSpacing.sm,
                children: [
                  _buildStatItem(
                    icon: Icons.people,
                    label: 'Schüler',
                    value: '${klasseStudents.length}',
                    color: RBSColors.courtGreen,
                  ),
                  _buildStatItem(
                    icon: Icons.assignment_late,
                    label: 'Nachschreiber',
                    value: '$nachschreiberCount',
                    color: nachschreiberCount > 0 ? Colors.orange : Colors.grey,
                  ),
                  _buildStatItem(
                    icon: Icons.grade,
                    label: 'Noten',
                    value: '${klasseGrades.length}',
                    color: RBSColors.growingElder,
                  ),
                  _buildStatItem(
                    icon: Icons.trending_up,
                    label: 'Ø',
                    value: durchschnitt != null ? durchschnitt.toStringAsFixed(2) : '-',
                    color: durchschnitt != null
                        ? (durchschnitt <= 2.5
                            ? RBSColors.courtGreen
                            : durchschnitt <= 3.5
                                ? Colors.orange
                                : Colors.red)
                        : Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getBerufColor(Beruf beruf) {
    switch (beruf) {
      case Beruf.ie:
        return RBSColors.dynamicRed;
      case Beruf.eat:
        return RBSColors.courtGreen;
      case Beruf.ebt:
        return RBSColors.growingElder;
      case Beruf.egs:
        return const Color(0xFF2E7BB5); // Blue
    }
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
