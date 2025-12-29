import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../widgets/rbs_drawer.dart';
import '../noten/widgets/noten_matrix_view.dart';

/// Leistungsnachweis-Editor Screen
/// 
/// Zeigt alle Schüler einer Klasse mit Noten für einen LN
/// - Einfache Liste: Schüler (Zeilen) × Note (Spalte)
/// - Inline-Editing
/// - Durchschnitt
/// - LN-Info Header
/// 
/// UI Guidelines: <300 Zeilen
class LNEditorScreen extends ConsumerWidget {
  final String leistungsnachweisId;

  const LNEditorScreen({
    required this.leistungsnachweisId, super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lnAsync = ref.watch(leistungsnachweisProvider(leistungsnachweisId));
    final klassenAsync = ref.watch(klassenProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final gradesAsync = ref.watch(gradesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/leistungsnachweise');
            }
          },
        ),
        title: lnAsync.when(
          data: (ln) => Text('${ln.typ.label} - ${ln.datum.day}.${ln.datum.month}.${ln.datum.year}'),
          loading: () => const Text('Leistungsnachweis'),
          error: (_, _) => const Text('Fehler'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: 'Zum Dashboard',
          ),
        ],
      ),
      drawer: const RBSDrawer(),
      body: lnAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Fehler: $e')),
        data: (ln) {
          final studentsAsync = ref.watch(studentsByKlasseProvider(ln.klasseId));
          
          return studentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Fehler: $e')),
            data: (students) => klassenAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Fehler: $e')),
              data: (klassen) => subjectsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Fehler: $e')),
                data: (subjects) => gradesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Fehler: $e')),
                  data: (grades) {
                    if (students.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Keine Schüler',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return NotenMatrixView(
                      mode: MatrixViewMode.byLN,
                      leistungsnachweisId: leistungsnachweisId,
                      students: students,
                      leistungsnachweise: [ln],
                      subjects: subjects,
                      grades: grades,
                      klassen: klassen,
                      onStudentTap: (studentId) {
                        context.push('/schueler/$studentId');
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
