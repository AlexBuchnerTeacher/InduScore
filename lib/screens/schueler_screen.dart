import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/rbs_theme.dart';
import '../core/widgets/rbs_components.dart';
import '../models/student.dart';
import '../models/beruf.dart';
import '../providers/app_providers.dart';
import '../widgets/rbs_drawer.dart';

/// Schülerverwaltung Screen
/// - Listet alle Schüler mit Filter nach Klasse
/// - DSGVO-konforme Pseudonymisierung
/// - CRUD Funktionalität
class SchuelerScreen extends ConsumerStatefulWidget {
  const SchuelerScreen({super.key});

  @override
  ConsumerState<SchuelerScreen> createState() => _SchuelerScreenState();
}

class _SchuelerScreenState extends ConsumerState<SchuelerScreen> {
  String? _selectedKlasseId;

  @override
  Widget build(BuildContext context) {
    final klassenAsync = ref.watch(klassenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schülerverwaltung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _selectedKlasseId != null
                ? () => _showStudentDialog()
                : null,
            tooltip: 'Neuer Schüler',
          ),
        ],
      ),
      drawer: const RBSDrawer(),
      body: Column(
        children: [
          // Klassen-Filter
          Container(
            padding: const EdgeInsets.all(RBSSpacing.md),
            color: RBSColors.paper,
            child: klassenAsync.when(
              data: (klassen) => Wrap(
                spacing: RBSSpacing.sm,
                runSpacing: RBSSpacing.sm,
                children: klassen.map((klasse) {
                  return RBSFilterChip(
                    label: klasse.name,
                    selected: _selectedKlasseId == klasse.id,
                    color: _getBerufColor(klasse.beruf),
                    onSelected: (selected) {
                      setState(() {
                        _selectedKlasseId = selected ? klasse.id : null;
                      });
                    },
                  );
                }).toList(),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Text('Fehler: $e'),
            ),
          ),

          // Schüler-Liste
          Expanded(
            child: _selectedKlasseId == null
                ? _buildEmptyState('Wähle eine Klasse aus')
                : _buildStudentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    final studentsAsync = ref.watch(
      studentsByKlasseProvider(_selectedKlasseId!),
    );

    return studentsAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return _buildEmptyState('Keine Schüler in dieser Klasse');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(RBSSpacing.md),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return _buildStudentCard(student);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
    );
  }

  Widget _buildStudentCard(Student student) {
    return Card(
      margin: const EdgeInsets.only(bottom: RBSSpacing.sm),
      child: ListTile(
        onTap: () => context.go('/noten/schueler/${student.id}'),
        leading: CircleAvatar(
          backgroundColor: RBSColors.dynamicRed,
          child: Text(
            student.pseudonym.substring(0, 2),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.displayName,
          style: RBSTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Pseudonym: ${student.pseudonym}',
          style: RBSTypography.bodySmall,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showStudentDialog(student: student);
                break;
              case 'delete':
                _confirmDelete(student);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 8),
                  Text('Bearbeiten'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Löschen', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: RBSSpacing.md),
          Text(
            message,
            style: RBSTypography.h3.copyWith(color: Colors.grey[600]),
          ),
          if (_selectedKlasseId != null) ...[
            const SizedBox(height: RBSSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _showStudentDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Ersten Schüler hinzufügen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: RBSColors.dynamicRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showStudentDialog({Student? student}) {
    final isEditing = student != null;
    final pseudonymController = TextEditingController(
      text: student?.pseudonym ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Schüler bearbeiten' : 'Neuer Schüler'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pseudonymController,
              decoration: const InputDecoration(
                labelText: 'Pseudonym',
                hintText: 'z.B. S001',
                helperText: 'DSGVO-konform, kein echter Name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: RBSSpacing.md),
            Container(
              padding: const EdgeInsets.all(RBSSpacing.sm),
              decoration: BoxDecoration(
                color: RBSColors.offwhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                  const SizedBox(width: RBSSpacing.sm),
                  Expanded(
                    child: Text(
                      'Echte Namen werden nicht gespeichert (DSGVO)',
                      style: RBSTypography.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pseudonym = pseudonymController.text.trim();
              if (pseudonym.isEmpty) return;

              final firestoreService = ref.read(firestoreServiceProvider);

              try {
                if (isEditing) {
                  await firestoreService.updateStudent(
                    student.copyWith(pseudonym: pseudonym),
                  );
                } else {
                  await firestoreService.createStudent(
                    Student(
                      id: '',
                      pseudonym: pseudonym,
                      klasseId: _selectedKlasseId!,
                      createdAt: DateTime.now(),
                    ),
                  );
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RBSColors.dynamicRed,
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Speichern' : 'Hinzufügen'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schüler löschen?'),
        content: Text(
          'Möchtest du "${student.displayName}" wirklich löschen?\n\n'
          'Alle Noten dieses Schülers werden ebenfalls gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final firestoreService = ref.read(firestoreServiceProvider);
              await firestoreService.deleteStudent(student.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Color _getBerufColor(Beruf? beruf) {
    if (beruf == null) return RBSColors.dynamicRed;
    switch (beruf) {
      case Beruf.ie:
        return RBSColors.dynamicRed;
      case Beruf.eat:
        return RBSColors.courtGreen;
      case Beruf.ebt:
        return RBSColors.growingElder;
      case Beruf.egs:
        return RBSColors.info; // Blau
    }
  }
}
