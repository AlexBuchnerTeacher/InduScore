import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/noten/widgets/noten_matrix_view.dart';
import '../providers/app_providers.dart';

/// Test-Screen für NotenMatrixView
/// 
/// Zeigt die neue Matrix-Komponente im byKlasse-Modus
/// Aufruf via: /test-matrix?klasseId=XXX
class TestMatrixScreen extends ConsumerWidget {
  final String? klasseId;

  const TestMatrixScreen({super.key, this.klasseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (klasseId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Matrix Test')),
        body: const Center(
          child: Text('Bitte klasseId als Query-Parameter übergeben'),
        ),
      );
    }

    final klassenAsync = ref.watch(klassenProvider);
    final studentsAsync = ref.watch(studentsByKlasseProvider(klasseId!));
    final subjectsAsync = ref.watch(subjectsProvider);
    final leistungsnachweiseAsync = ref.watch(leistungsnachweiseProvider);
    final gradesAsync = ref.watch(gradesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrix Test - byKlasse Modus'),
        backgroundColor: Colors.purple,
      ),
      body: klassenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Fehler: $e')),
        data: (klassen) => studentsAsync.when(
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
                data: (grades) {
                  // Filter LNs für diese Klasse
                  final klassenLN = allLN
                      .where((ln) => ln.klasseId == klasseId)
                      .toList();

                  if (students.isEmpty) {
                    return const Center(
                      child: Text('Keine Schüler in dieser Klasse'),
                    );
                  }

                  return NotenMatrixView(
                    mode: MatrixViewMode.byKlasse,
                    klasseId: klasseId,
                    students: students,
                    leistungsnachweise: klassenLN,
                    subjects: subjects,
                    grades: grades,
                    klassen: klassen,
                    onStudentTap: (studentId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Schüler geklickt: $studentId'),
                        ),
                      );
                    },
                    onSubjectTap: (subjectId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Fach geklickt: $subjectId'),
                        ),
                      );
                    },
                    onLNTap: (lnId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('LN geklickt: $lnId')),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
