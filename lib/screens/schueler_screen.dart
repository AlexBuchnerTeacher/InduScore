import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/rbs_theme.dart';
import '../core/widgets/rbs_components.dart';
import '../models/student.dart';
import '../models/beruf.dart';
import '../providers/app_providers.dart';
import '../widgets/rbs_drawer.dart';

/// Schülerverwaltung Screen
/// - Listet alle Schüler mit Filter nach Klasse
/// - CRUD Funktionalität
/// - Tooltip mit Eintrittsdatum
class SchuelerScreen extends ConsumerStatefulWidget {
  const SchuelerScreen({super.key});

  @override
  ConsumerState<SchuelerScreen> createState() => _SchuelerScreenState();
}

class _SchuelerScreenState extends ConsumerState<SchuelerScreen> {
  String? _selectedKlasseId;
  bool _showAusgetretene = false;

  @override
  Widget build(BuildContext context) {
    final klassenAsync = ref.watch(klassenProvider);
    final filteredKlassen = ref.watch(filteredKlassenProvider);
    final zeitgruppenFilter = ref.watch(zeitgruppenFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schülerverwaltung'),
        actions: [
          // Toggle für ausgetretene Schüler
          if (_selectedKlasseId != null)
            IconButton(
              icon: Icon(_showAusgetretene ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _showAusgetretene = !_showAusgetretene),
              tooltip: _showAusgetretene ? 'Ausgetretene ausblenden' : 'Ausgetretene anzeigen',
            ),
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
              data: (_) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zeitgruppen Filter Chip
                  if (zeitgruppenFilter != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: RBSSpacing.sm),
                      child: Chip(
                        label: Text('ZG$zeitgruppenFilter'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => ref.read(zeitgruppenFilterProvider.notifier).clearFilter(),
                        backgroundColor: RBSColors.courtGreen.withValues(alpha: 0.2),
                      ),
                    ),
                  Wrap(
                    spacing: RBSSpacing.sm,
                    runSpacing: RBSSpacing.sm,
                    children: filteredKlassen.map((klasse) {
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
                ],
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
        // Filtere nach Status
        final filtered = _showAusgetretene 
            ? students 
            : students.where((s) => s.isAktiv).toList();
        
        if (filtered.isEmpty) {
          return _buildEmptyState(
            students.isEmpty 
                ? 'Keine Schüler in dieser Klasse' 
                : 'Keine aktiven Schüler (${students.length} ausgetreten)',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(RBSSpacing.md),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final student = filtered[index];
            return _buildStudentCard(student);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
    );
  }

  Widget _buildStudentCard(Student student) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final isAusgetreten = !student.isAktiv;
    
    return Tooltip(
      message: 'Eintritt: ${dateFormat.format(student.eintrittsDatum)}'
          '${student.austrittsDatum != null ? '\nAustritt: ${dateFormat.format(student.austrittsDatum!)}' : ''}',
      child: Card(
        margin: const EdgeInsets.only(bottom: RBSSpacing.sm),
        color: isAusgetreten ? Colors.grey[200] : null,
        child: ListTile(
          onTap: () => context.go('/noten/schueler/${student.id}'),
          leading: CircleAvatar(
            backgroundColor: isAusgetreten ? Colors.grey : RBSColors.dynamicRed,
            child: Text(
              _getInitials(student),
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
              color: isAusgetreten ? Colors.grey : null,
              decoration: isAusgetreten ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: isAusgetreten 
              ? Text(
                  'Ausgetreten am ${dateFormat.format(student.austrittsDatum!)}',
                  style: RBSTypography.bodySmall.copyWith(color: Colors.grey),
                )
              : null,
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showStudentDialog(student: student);
                  break;
                case 'austritt':
                  _showAustrittDialog(student);
                  break;
                case 'reaktivieren':
                  _reaktiviereStudent(student);
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
              if (student.isAktiv)
                const PopupMenuItem(
                  value: 'austritt',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Als ausgetreten markieren'),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'reaktivieren',
                  child: Row(
                    children: [
                      Icon(Icons.undo, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Reaktivieren'),
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
      ),
    );
  }

  String _getInitials(Student student) {
    final first = student.firstName.isNotEmpty ? student.firstName[0] : '';
    final last = student.lastName.isNotEmpty ? student.lastName[0] : '';
    return '$first$last'.toUpperCase();
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
    final firstNameController = TextEditingController(text: student?.firstName ?? '');
    final lastNameController = TextEditingController(text: student?.lastName ?? '');
    DateTime eintrittsDatum = student?.eintrittsDatum ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Schüler bearbeiten' : 'Neuer Schüler'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Vorname',
                  hintText: 'z.B. Max',
                ),
                autofocus: true,
              ),
              const SizedBox(height: RBSSpacing.sm),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nachname',
                  hintText: 'z.B. Mustermann',
                ),
              ),
              const SizedBox(height: RBSSpacing.md),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: eintrittsDatum,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    helpText: 'Eintrittsdatum',
                  );
                  if (picked != null) {
                    setDialogState(() => eintrittsDatum = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Eintrittsdatum',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd.MM.yyyy').format(eintrittsDatum)),
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
                final firstName = firstNameController.text.trim();
                final lastName = lastNameController.text.trim();
                if (firstName.isEmpty || lastName.isEmpty) return;

                final firestoreService = ref.read(firestoreServiceProvider);

                try {
                  if (isEditing) {
                    await firestoreService.updateStudent(
                      student.copyWith(
                        firstName: firstName,
                        lastName: lastName,
                        eintrittsDatum: eintrittsDatum,
                      ),
                    );
                  } else {
                    await firestoreService.createStudent(
                      Student(
                        id: '',
                        firstName: firstName,
                        lastName: lastName,
                        klasseId: _selectedKlasseId!,
                        eintrittsDatum: eintrittsDatum,
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
      ),
    );
  }

  void _showAustrittDialog(Student student) {
    DateTime austrittsDatum = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Austritt markieren'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${student.displayName} als ausgetreten markieren?'),
              const SizedBox(height: RBSSpacing.md),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: austrittsDatum,
                    firstDate: student.eintrittsDatum,
                    lastDate: DateTime(2100),
                    helpText: 'Austrittsdatum',
                  );
                  if (picked != null) {
                    setDialogState(() => austrittsDatum = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Austrittsdatum',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd.MM.yyyy').format(austrittsDatum)),
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
                final firestoreService = ref.read(firestoreServiceProvider);
                await firestoreService.updateStudent(
                  student.markAsAusgetreten(austrittsDatum),
                );
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Austritt speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reaktiviereStudent(Student student) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    await firestoreService.updateStudent(
      student.copyWith(
        status: StudentStatus.aktiv,
        austrittsDatum: null,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.displayName} wurde reaktiviert'),
          backgroundColor: RBSColors.courtGreen,
        ),
      );
    }
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
        return RBSColors.info;
    }
  }
}
