import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/widgets/rbs_drawer.dart';
import 'package:induscore/core/widgets/rbs_components.dart';
import 'package:induscore/models/leistungsnachweis.dart';
import 'package:induscore/models/klasse.dart';
import 'package:induscore/models/beruf.dart';
import 'package:induscore/models/subject.dart';
import 'package:induscore/providers/app_providers.dart';
import 'package:induscore/providers/permissions_providers.dart';

class LeistungsnachweiseScreen extends ConsumerStatefulWidget {
  const LeistungsnachweiseScreen({super.key});

  @override
  ConsumerState<LeistungsnachweiseScreen> createState() =>
      _LeistungsnachweiseScreenState();
}

class _LeistungsnachweiseScreenState
    extends ConsumerState<LeistungsnachweiseScreen> {
  String? _selectedKlasseId;
  String? _selectedSubjectId;
  LeistungsnachweisTyp? _selectedTyp;

  @override
  Widget build(BuildContext context) {
    final leistungsnachweiseAsync = ref.watch(leistungsnachweiseProvider);
    final klassenAsync = ref.watch(klassenProvider);
    final filteredKlassen = ref.watch(filteredKlassenProvider);
    final zeitgruppenFilter = ref.watch(zeitgruppenFilterProvider);
    // Note: subjectsMapProvider is used directly in _buildLeistungsnachweisCard

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menü',
          ),
        ),
        title: const Text('Leistungsnachweise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: 'Zum Dashboard',
          ),
          // Nur anzeigen wenn Berechtigung zum Erstellen
          Consumer(
            builder: (context, ref, _) {
              final canCreate = ref.watch(canCreateLeistungsnachweisProvider);
              if (!canCreate) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showLeistungsnachweisDialog(context),
                tooltip: 'Neuer Leistungsnachweis',
              );
            },
          ),
        ],
      ),
      drawer: const RBSDrawer(),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(RBSSpacing.md),
            color: RBSColors.paper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Zeitgruppen-Filter
                Padding(
                  padding: const EdgeInsets.only(bottom: RBSSpacing.sm),
                  child: Wrap(
                    spacing: 4,
                    children: [
                      RBSFilterChip(
                        label: 'ZG1',
                        selected: zeitgruppenFilter.contains(1),
                        color: RBSColors.courtGreen,
                        onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(1),
                      ),
                      RBSFilterChip(
                        label: 'ZG2',
                        selected: zeitgruppenFilter.contains(2),
                        color: RBSColors.courtGreen,
                        onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(2),
                      ),
                      RBSFilterChip(
                        label: 'ZG3',
                        selected: zeitgruppenFilter.contains(3),
                        color: RBSColors.courtGreen,
                        onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(3),
                      ),
                    ],
                  ),
                ),
                // Klassen-Filter
                klassenAsync.when(
                  data: (_) => Wrap(
                    spacing: RBSSpacing.sm,
                    runSpacing: RBSSpacing.sm,
                    children: [
                      RBSFilterChip(
                        label: 'Alle Klassen',
                        selected: _selectedKlasseId == null,
                        onSelected: (_) =>
                            setState(() => _selectedKlasseId = null),
                      ),
                      ...filteredKlassen.map(
                        (klasse) => RBSFilterChip(
                          label: klasse.name,
                          selected: _selectedKlasseId == klasse.id,
                          color: _getBerufColor(klasse.beruf),
                          onSelected: (selected) {
                            setState(() {
                              _selectedKlasseId = selected ? klasse.id : null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),
                const SizedBox(height: RBSSpacing.sm),
                // Typ-Filter
                Wrap(
                  spacing: RBSSpacing.sm,
                  runSpacing: RBSSpacing.sm,
                  children: [
                    RBSFilterChip(
                      label: 'Alle Typen',
                      selected: _selectedTyp == null,
                      onSelected: (_) => setState(() => _selectedTyp = null),
                    ),
                    ...LeistungsnachweisTyp.values.map(
                      (typ) => RBSFilterChip(
                        label: typ.name,
                        selected: _selectedTyp == typ,
                        color: _getTypColor(typ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedTyp = selected ? typ : null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Leistungsnachweise List
          Expanded(
            child: leistungsnachweiseAsync.when(
              data: (leistungsnachweise) {
                // Apply filters
                var filtered = leistungsnachweise;
                if (_selectedKlasseId != null) {
                  filtered = filtered
                      .where((ln) => ln.klasseId == _selectedKlasseId)
                      .toList();
                }
                if (_selectedSubjectId != null) {
                  filtered = filtered
                      .where((ln) => ln.subjectId == _selectedSubjectId)
                      .toList();
                }
                if (_selectedTyp != null) {
                  filtered =
                      filtered.where((ln) => ln.typ == _selectedTyp).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: RBSColors.textOnLight.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: RBSSpacing.md),
                        Text(
                          'Keine Leistungsnachweise gefunden',
                          style: RBSTypography.h4.copyWith(
                            color: RBSColors.textOnLight.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: RBSSpacing.sm),
                        RBSButton(
                          label: 'Ersten Leistungsnachweis erstellen',
                          icon: Icons.add,
                          onPressed: () =>
                              _showLeistungsnachweisDialog(context),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(RBSSpacing.md),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ln = filtered[index];
                    return _buildLeistungsnachweisCard(
                      context,
                      ln,
                      ref.watch(klassenMapProvider),
                      ref.watch(subjectsMapProvider),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Fehler: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeistungsnachweisCard(
    BuildContext context,
    Leistungsnachweis ln,
    Map<String, Klasse> klassenMap,
    Map<String, Subject> subjectsMap,
  ) {
    // O(1) lookup instead of .where().firstOrNull
    final klasse = klassenMap[ln.klasseId];
    final subject = subjectsMap[ln.subjectId];
    final dateFormat = DateFormat('dd.MM.yyyy');
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return RBSCard(
      child: InkWell(
        onTap: () => context.go('/leistungsnachweis/${ln.id}/edit'),
        borderRadius: BorderRadius.circular(RBSSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(RBSSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Title + Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: _getTypColor(ln.typ),
                    radius: 20,
                    child: Icon(
                      _getTypIcon(ln.typ),
                      color: RBSColors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: RBSSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ln.bezeichnung, style: RBSTypography.h4),
                        const SizedBox(height: 2),
                        Text(
                          '${ln.typ.label} • ${ln.gewichtung}x • ${dateFormat.format(ln.datum)}',
                          style: RBSTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Actions - nur Icons auf kleinen Screens (mit Permission Check)
                  Consumer(
                    builder: (context, ref, _) {
                      final canEdit = ref.watch(canEditLeistungsnachweisProvider(ln));
                      if (!canEdit) return const SizedBox.shrink();
                      
                      if (!isSmallScreen) {
                        return Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _showLeistungsnachweisDialog(context, leistungsnachweis: ln),
                              tooltip: 'Bearbeiten',
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _confirmDelete(context, ln),
                              tooltip: 'Löschen',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        );
                      } else {
                        return PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showLeistungsnachweisDialog(context, leistungsnachweis: ln);
                            } else if (value == 'delete') {
                              _confirmDelete(context, ln);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Bearbeiten'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Löschen', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: RBSSpacing.sm),
              // Tags Row
              Wrap(
                spacing: RBSSpacing.xs,
                runSpacing: RBSSpacing.xs,
                children: [
                  if (klasse != null)
                    RBSTag(
                      label: klasse.name,
                      color: _getBerufColor(klasse.beruf),
                    ),
                  if (subject != null)
                    RBSTag(
                      label: subject.shortName ?? subject.name,
                      color: RBSColors.fromHex(subject.color) ?? RBSColors.courtGreen,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        return const Color(0xFF2E7BB5);
    }
  }

  Color _getTypColor(LeistungsnachweisTyp typ) {
    switch (typ) {
      case LeistungsnachweisTyp.wochentest:
        return RBSColors.dynamicRed;
      case LeistungsnachweisTyp.praktisch:
        return const Color(0xFF2E7BB5);
      case LeistungsnachweisTyp.muendlich:
        return RBSColors.courtGreen;
      case LeistungsnachweisTyp.mitarbeit:
        return RBSColors.growingElder;
    }
  }

  IconData _getTypIcon(LeistungsnachweisTyp typ) {
    switch (typ) {
      case LeistungsnachweisTyp.wochentest:
        return Icons.assignment;
      case LeistungsnachweisTyp.praktisch:
        return Icons.build;
      case LeistungsnachweisTyp.muendlich:
        return Icons.record_voice_over;
      case LeistungsnachweisTyp.mitarbeit:
        return Icons.person;
    }
  }

  void _showLeistungsnachweisDialog(
    BuildContext context, {
    Leistungsnachweis? leistungsnachweis,
  }) {
    final isEdit = leistungsnachweis != null;
    final bezeichnungController = TextEditingController(
      text: leistungsnachweis?.bezeichnung ?? '',
    );
    final beschreibungController = TextEditingController(
      text: leistungsnachweis?.beschreibung ?? '',
    );
    final formKey = GlobalKey<FormState>();

    String? selectedKlasseId = leistungsnachweis?.klasseId;
    String? selectedSubjectId = leistungsnachweis?.subjectId;
    LeistungsnachweisTyp selectedTyp =
        leistungsnachweis?.typ ?? LeistungsnachweisTyp.wochentest;
    double selectedGewichtung = leistungsnachweis?.gewichtung ?? 1.0;
    DateTime selectedDatum = leistungsnachweis?.datum ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final klassenAsync = ref.watch(klassenProvider);
          final subjectsAsync = ref.watch(subjectsProvider);

          return RBSDialog(
            title: isEdit
                ? 'Leistungsnachweis bearbeiten'
                : 'Neuer Leistungsnachweis',
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Klasse auswählen
                    const Text('Klasse *', style: RBSTypography.label),
                    const SizedBox(height: RBSSpacing.xs),
                    klassenAsync.when(
                      data: (klassen) => DropdownButtonFormField<String>(
                        initialValue: selectedKlasseId,
                        decoration: const InputDecoration(
                          hintText: 'Klasse wählen',
                          border: OutlineInputBorder(),
                        ),
                        items: klassen
                            .map(
                              (k) => DropdownMenuItem(
                                value: k.id,
                                child: Text(k.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedKlasseId = value);
                        },
                        validator: (value) =>
                            value == null ? 'Bitte Klasse wählen' : null,
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => const Text('Fehler beim Laden'),
                    ),
                    const SizedBox(height: RBSSpacing.md),

                    // Fach auswählen (nur Fächer die zum Beruf der Klasse passen)
                    const Text('Fach *', style: RBSTypography.label),
                    const SizedBox(height: RBSSpacing.xs),
                    subjectsAsync.when(
                      data: (subjects) {
                        // O(1) lookup using Map provider
                        final klassenMap = ref.watch(klassenMapProvider);
                        final selectedKlasse = klassenMap[selectedKlasseId];
                        
                        // Filtere Fächer nach Beruf der Klasse
                        final filteredSubjects = selectedKlasse != null
                            ? subjects.where((s) => s.berufe.contains(selectedKlasse.beruf)).toList()
                            : subjects;
                        
                        // Wenn aktuelles Fach nicht mehr passt, zurücksetzen
                        if (selectedSubjectId != null && 
                            !filteredSubjects.any((s) => s.id == selectedSubjectId)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setDialogState(() => selectedSubjectId = null);
                          });
                        }
                        
                        return DropdownButtonFormField<String>(
                          initialValue: filteredSubjects.any((s) => s.id == selectedSubjectId) 
                              ? selectedSubjectId 
                              : null,
                          decoration: InputDecoration(
                            hintText: selectedKlasseId == null 
                                ? 'Erst Klasse wählen' 
                                : 'Fach wählen',
                            border: const OutlineInputBorder(),
                          ),
                          items: filteredSubjects
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.shortName ?? s.name),
                                ),
                              )
                              .toList(),
                          onChanged: selectedKlasseId == null 
                              ? null 
                              : (value) {
                                  setDialogState(() => selectedSubjectId = value);
                                },
                          validator: (value) =>
                              value == null ? 'Bitte Fach wählen' : null,
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => const Text('Fehler beim Laden'),
                    ),
                    const SizedBox(height: RBSSpacing.md),

                    // Typ auswählen
                    const Text('Typ *', style: RBSTypography.label),
                    const SizedBox(height: RBSSpacing.xs),
                    DropdownButtonFormField<LeistungsnachweisTyp>(
                      initialValue: selectedTyp,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: LeistungsnachweisTyp.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Row(
                                children: [
                                  Icon(_getTypIcon(t),
                                      color: _getTypColor(t), size: 18),
                                  const SizedBox(width: RBSSpacing.sm),
                                  Text(t.label),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedTyp = value);
                        }
                      },
                    ),
                    const SizedBox(height: RBSSpacing.md),

                    // Gewichtung auswählen
                    const Text('Gewichtung *', style: RBSTypography.label),
                    const SizedBox(height: RBSSpacing.xs),
                    DropdownButtonFormField<double>(
                      initialValue: selectedGewichtung,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1.0, child: Text('1x (einfach)')),
                        DropdownMenuItem(value: 1.5, child: Text('1,5x')),
                        DropdownMenuItem(value: 2.0, child: Text('2x (doppelt)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedGewichtung = value);
                        }
                      },
                    ),
                    const SizedBox(height: RBSSpacing.md),

                    // Bezeichnung
                    RBSInput(
                      label: 'Bezeichnung *',
                      hint: 'z.B. 1. Schulaufgabe',
                      controller: bezeichnungController,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Bitte Bezeichnung eingeben' : null,
                    ),
                    const SizedBox(height: RBSSpacing.md),

                    // Datum
                    const Text('Datum *', style: RBSTypography.label),
                    const SizedBox(height: RBSSpacing.xs),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDatum,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDatum = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd.MM.yyyy').format(selectedDatum),
                        ),
                      ),
                    ),
                    const SizedBox(height: RBSSpacing.md),

                    // Beschreibung
                    RBSInput(
                      label: 'Beschreibung (optional)',
                      hint: 'Zusätzliche Informationen...',
                      controller: beschreibungController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              RBSButton(
                label: isEdit ? 'Speichern' : 'Erstellen',
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (selectedKlasseId == null || selectedSubjectId == null) {
                    return;
                  }

                  try {
                    final firestoreService = ref.read(firestoreServiceProvider);
                    final now = DateTime.now();

                    final newLn = Leistungsnachweis(
                      id: leistungsnachweis?.id ?? '',
                      klasseId: selectedKlasseId!,
                      subjectId: selectedSubjectId!,
                      typ: selectedTyp,
                      bezeichnung: bezeichnungController.text.trim(),
                      datum: selectedDatum,
                      gewichtung: selectedGewichtung,
                      beschreibung: beschreibungController.text.trim().isEmpty
                          ? null
                          : beschreibungController.text.trim(),
                      createdAt: leistungsnachweis?.createdAt ?? now,
                      updatedAt: now,
                    );

                    if (isEdit) {
                      await firestoreService.updateLeistungsnachweis(newLn);
                    } else {
                      await firestoreService.createLeistungsnachweis(newLn);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? 'Leistungsnachweis aktualisiert'
                                : 'Leistungsnachweis erstellt',
                          ),
                          backgroundColor: RBSColors.courtGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Fehler: $e'),
                          backgroundColor: RBSColors.dynamicRed,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Leistungsnachweis ln) {
    showDialog(
      context: context,
      builder: (context) => RBSDialog(
        title: 'Leistungsnachweis löschen?',
        content: Text(
          'Möchten Sie "${ln.bezeichnung}" wirklich löschen?\n\n'
          'Alle zugehörigen Noten werden ebenfalls gelöscht!',
          style: RBSTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          RBSButton(
            label: 'Löschen',
            onPressed: () async {
              try {
                final firestoreService = ref.read(firestoreServiceProvider);
                await firestoreService.deleteLeistungsnachweis(ln.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Leistungsnachweis gelöscht'),
                      backgroundColor: RBSColors.courtGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler: $e'),
                      backgroundColor: RBSColors.dynamicRed,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
