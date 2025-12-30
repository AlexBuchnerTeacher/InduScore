import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/core/widgets/rbs_components.dart';
import 'package:induscore/models/student.dart';
import 'package:induscore/models/klasse.dart';
import 'package:induscore/models/beruf.dart';
import 'package:induscore/providers/app_providers.dart';
import 'package:induscore/shared/widgets/app_snack_bars.dart';
import 'package:induscore/shared/widgets/feature_guard.dart';
import 'package:induscore/widgets/rbs_drawer.dart';
import 'package:induscore/providers/permissions_providers.dart';
import 'package:induscore/widgets/dialogs/common_dialogs.dart';

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
  // ignore: prefer_final_fields
  Set<Beruf> _selectedBerufe = {};
  // ignore: prefer_final_fields
  Set<String> _selectedKlassenIds = {};
  bool _showAusgetretene = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final klassenAsync = ref.watch(klassenProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final zeitgruppenFilter = ref.watch(zeitgruppenFilterProvider);
    final canManageData = ref.watch(canManageDataProvider);
    
    // Feature-Flag für Create Button in AppBar
    final canCreate = ref.watch(canCreateSchuelerProvider);

    // Permission Check
    if (!canManageData) {
      return Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menü',
            ),
          ),
          title: const Text('Schülerverwaltung'),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => context.go('/'),
              tooltip: 'Zum Dashboard',
            ),
          ],
        ),
        drawer: const RBSDrawer(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Zugriff verweigert', style: RBSTypography.h3),
              const SizedBox(height: 8),
              const Text(
                'Sie haben keine Berechtigung zur Schülerverwaltung.',
                style: RBSTypography.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menü',
          ),
        ),
        title: const Text('Schülerverwaltung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: 'Zum Dashboard',
          ),
          // Toggle für ausgetretene Schüler
          IconButton(
            icon: Icon(
              _showAusgetretene ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () =>
                setState(() => _showAusgetretene = !_showAusgetretene),
            tooltip: _showAusgetretene
                ? 'Ausgetretene ausblenden'
                : 'Ausgetretene anzeigen',
          ),
          // Neuer Schüler Button - per Feature-Flag gesteuert
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showStudentDialog,
              tooltip: 'Neuer Schüler',
            ),
        ],
      ),
      drawer: const RBSDrawer(),
      body: Column(
        children: [
          // Filter Section - nur wenn canUseFilter aktiv
          if (ref.watch(canUseFilterProvider))
            Container(
              padding: const EdgeInsets.all(RBSSpacing.md),
              color: RBSColors.paper,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Beruf-Filter
                  Row(
                    children: [
                      Text(
                        'Beruf:',
                        style: RBSTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(width: RBSSpacing.sm),
                    Expanded(
                      child: Wrap(
                        spacing: RBSSpacing.xs,
                        runSpacing: RBSSpacing.xs,
                        children: Beruf.values.map((beruf) {
                          return RBSFilterChip(
                            label: beruf.code,
                            selected: _selectedBerufe.contains(beruf),
                            color: _getBerufColor(beruf),
                            onSelected: (_) {
                              setState(() {
                                if (_selectedBerufe.contains(beruf)) {
                                  _selectedBerufe.remove(beruf);
                                } else {
                                  _selectedBerufe.add(beruf);
                                }
                                // Reset Klassen-Auswahl wenn Beruf ändert
                                _selectedKlassenIds.clear();
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RBSSpacing.sm),

                // 2. Zeitgruppen-Filter
                Row(
                  children: [
                    Text(
                      'Zeitgruppe:',
                      style: RBSTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: RBSSpacing.sm),
                    RBSFilterChip(
                      label: 'ZG1',
                      selected: zeitgruppenFilter.contains(1),
                      color: RBSColors.courtGreen,
                      onSelected: (_) {
                        ref.read(zeitgruppenFilterProvider.notifier).toggle(1);
                        setState(() => _selectedKlassenIds.clear());
                      },
                    ),
                    const SizedBox(width: RBSSpacing.xs),
                    RBSFilterChip(
                      label: 'ZG2',
                      selected: zeitgruppenFilter.contains(2),
                      color: RBSColors.courtGreen,
                      onSelected: (_) {
                        ref.read(zeitgruppenFilterProvider.notifier).toggle(2);
                        setState(() => _selectedKlassenIds.clear());
                      },
                    ),
                    const SizedBox(width: RBSSpacing.xs),
                    RBSFilterChip(
                      label: 'ZG3',
                      selected: zeitgruppenFilter.contains(3),
                      color: RBSColors.courtGreen,
                      onSelected: (_) {
                        ref.read(zeitgruppenFilterProvider.notifier).toggle(3);
                        setState(() => _selectedKlassenIds.clear());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: RBSSpacing.sm),

                // 3. Klassen-Filter
                klassenAsync.when(
                  data: (allKlassen) {
                    // Filtere Klassen nach Beruf und Zeitgruppe
                    var filteredKlassen = allKlassen;
                    if (_selectedBerufe.isNotEmpty) {
                      filteredKlassen = filteredKlassen
                          .where((k) => _selectedBerufe.contains(k.beruf))
                          .toList();
                    }
                    if (zeitgruppenFilter.isNotEmpty) {
                      filteredKlassen = filteredKlassen
                          .where(
                            (k) =>
                                zeitgruppenFilter.contains(k.zeitgruppe.nummer),
                          )
                          .toList();
                    }

                    if (filteredKlassen.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Klasse:',
                          style: RBSTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: RBSSpacing.xs),
                        Wrap(
                          spacing: RBSSpacing.xs,
                          runSpacing: RBSSpacing.xs,
                          children: filteredKlassen.map((klasse) {
                            return RBSFilterChip(
                              label: klasse.name,
                              selected: _selectedKlassenIds.contains(klasse.id),
                              color: _getBerufColor(klasse.beruf),
                              onSelected: (_) {
                                setState(() {
                                  if (_selectedKlassenIds.contains(klasse.id)) {
                                    _selectedKlassenIds.remove(klasse.id);
                                  } else {
                                    _selectedKlassenIds.add(klasse.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text(
                    'Fehler: $e',
                    style: const TextStyle(color: RBSColors.error),
                  ),
                ),
                const SizedBox(height: RBSSpacing.sm),

                // 4. Suchfeld
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Schüler suchen (Vor- oder Nachname)...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: RBSSpacing.md,
                      vertical: RBSSpacing.sm,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ],
            ),
          ),

          // Schüler-Liste
          Expanded(
            child: studentsAsync.when(
              data: (allStudents) =>
                  _buildStudentList(allStudents, klassenAsync),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<Student> allStudents, AsyncValue klassenAsync) {
    // 1. Filtere nach Aktiv/Inaktiv
    var filtered = _showAusgetretene
        ? allStudents
        : allStudents.where((s) => s.isAktiv).toList();

    final zeitgruppenFilter = ref.watch(zeitgruppenFilterProvider);

    // 2. Filtere nach ausgewählten Klassen (wenn welche gewählt)
    if (_selectedKlassenIds.isNotEmpty) {
      filtered = filtered
          .where((s) => _selectedKlassenIds.contains(s.klasseId))
          .toList();
    }
    // Wenn keine Klassen gewählt, aber Beruf/ZG-Filter aktiv → filtere nach Klassen-Beruf/ZG
    else if (_selectedBerufe.isNotEmpty || zeitgruppenFilter.isNotEmpty) {
      return klassenAsync.when(
        data: (klassen) {
          final validKlassenIds = (klassen as List<Klasse>)
              .where(
                (Klasse k) =>
                    (_selectedBerufe.isEmpty ||
                        _selectedBerufe.contains(k.beruf)) &&
                    (zeitgruppenFilter.isEmpty ||
                        zeitgruppenFilter.contains(k.zeitgruppe.index)),
              )
              .map<String>((Klasse k) => k.id)
              .toSet();

          filtered = filtered
              .where((Student s) => validKlassenIds.contains(s.klasseId))
              .toList();

          return _buildFilteredList(filtered, allStudents);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      );
    }

    // 3. Filtere nach Suchbegriff (Vor- oder Nachname)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) {
        final fullName = '${s.firstName} ${s.lastName}'.toLowerCase();
        return fullName.contains(_searchQuery);
      }).toList();
    }

    return _buildFilteredList(filtered, allStudents);
  }

  Widget _buildFilteredList(List<Student> filtered, List<Student> allStudents) {
    final zeitgruppenFilter = ref.watch(zeitgruppenFilterProvider);

    if (filtered.isEmpty) {
      String message = 'Keine Schüler gefunden';
      if (_searchQuery.isNotEmpty) {
        message = 'Keine Schüler mit "$_searchQuery" gefunden';
      } else if (_selectedKlassenIds.isEmpty &&
          _selectedBerufe.isEmpty &&
          zeitgruppenFilter.isEmpty) {
        message = 'Wähle Filter oder suche nach Schülern';
      }
      return _buildEmptyState(message);
    }

    // Sortiere nach Nachname, dann Vorname
    filtered.sort((a, b) {
      final lastNameComp = a.lastName.compareTo(b.lastName);
      return lastNameComp != 0
          ? lastNameComp
          : a.firstName.compareTo(b.firstName);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(RBSSpacing.md),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final student = filtered[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(Student student) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final isAusgetreten = !student.isAktiv;
    
    // Feature-Flags für Aktionen
    final canEdit = ref.watch(canEditSchuelerProvider);
    final canDelete = ref.watch(canDeleteSchuelerProvider);

    return Tooltip(
      message:
          'Eintritt: ${dateFormat.format(student.eintrittsDatum)}'
          '${student.austrittsDatum != null ? '\nAustritt: ${dateFormat.format(student.austrittsDatum!)}' : ''}',
      child: Card(
        margin: const EdgeInsets.only(bottom: RBSSpacing.sm),
        color: isAusgetreten ? Colors.grey[200] : null,
        child: ListTile(
          onTap: () => context.go('/schueler/${student.id}'),
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
              if (canEdit)
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
              if (canEdit && student.isAktiv)
                const PopupMenuItem(
                  value: 'austritt',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Als ausgetreten markieren'),
                    ],
                  ),
                ),
              if (canEdit && !student.isAktiv)
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
              if (canDelete)
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
    final canCreate = ref.watch(canCreateSchuelerProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: RBSSpacing.md),
          Text(
            message,
            style: RBSTypography.h3.copyWith(color: Colors.grey[600]),
          ),
          if (canCreate) ...[
            const SizedBox(height: RBSSpacing.lg),
            ElevatedButton.icon(
              onPressed: _showStudentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Neuen Schüler anlegen'),
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
    final firstNameController = TextEditingController(
      text: student?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: student?.lastName ?? '',
    );
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
                    // Wird später erweitert mit Klassen-Auswahl
                    AppSnackBars.showInfo(
                      context,
                      'Bitte erweitere den Dialog um Klassenauswahl',
                    );
                    return;
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    AppSnackBars.showError(context, 'Fehler', error: e);
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
      student.copyWith(status: StudentStatus.aktiv, austrittsDatum: null),
    );
    if (mounted) {
      AppSnackBars.showSuccess(
        context,
        '${student.displayName} wurde reaktiviert',
      );
    }
  }

  void _confirmDelete(Student student) {
    CommonDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Schüler löschen?',
      itemName: student.displayName,
      additionalWarning:
          'Alle Noten dieses Schülers werden ebenfalls gelöscht.',
      onDelete: () async {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.deleteStudent(student.id);
      },
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
