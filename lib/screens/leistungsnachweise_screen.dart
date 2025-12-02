import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/rbs_theme.dart';
import '../widgets/rbs_drawer.dart';
import '../core/widgets/rbs_components.dart';
import '../models/leistungsnachweis.dart';
import '../models/klasse.dart';
import '../models/beruf.dart';
import '../models/subject.dart';
import '../providers/app_providers.dart';

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
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leistungsnachweise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showLeistungsnachweisDialog(context),
            tooltip: 'Neuer Leistungsnachweis',
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
                // Klassen-Filter
                klassenAsync.when(
                  data: (klassen) => Wrap(
                    spacing: RBSSpacing.sm,
                    runSpacing: RBSSpacing.sm,
                    children: [
                      RBSFilterChip(
                        label: 'Alle Klassen',
                        selected: _selectedKlasseId == null,
                        onSelected: (_) =>
                            setState(() => _selectedKlasseId = null),
                      ),
                      ...klassen.map(
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
                      klassenAsync.value ?? [],
                      subjectsAsync.value ?? [],
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
    List<Klasse> klassen,
    List<Subject> subjects,
  ) {
    final klasse = klassen.where((k) => k.id == ln.klasseId).firstOrNull;
    final subject = subjects.where((s) => s.id == ln.subjectId).firstOrNull;
    final dateFormat = DateFormat('dd.MM.yyyy');

    return RBSCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypColor(ln.typ),
          child: Icon(
            _getTypIcon(ln.typ),
            color: RBSColors.white,
            size: 20,
          ),
        ),
        title: Text(ln.bezeichnung, style: RBSTypography.h4),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ln.typ.name} • ${dateFormat.format(ln.datum)}',
              style: RBSTypography.bodySmall,
            ),
            Row(
              children: [
                if (klasse != null)
                  Chip(
                    label: Text(klasse.name),
                    backgroundColor:
                        _getBerufColor(klasse.beruf).withValues(alpha: 0.2),
                    labelStyle: RBSTypography.bodySmall,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                const SizedBox(width: RBSSpacing.xs),
                if (subject != null)
                  Chip(
                    label: Text(subject.shortName ?? subject.name),
                    backgroundColor:
                        RBSColors.courtGreen.withValues(alpha: 0.2),
                    labelStyle: RBSTypography.bodySmall,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Noten eingeben Button
            IconButton(
              icon: const Icon(Icons.edit_note),
              onPressed: () => context.go('/noten/${ln.id}'),
              tooltip: 'Noten eingeben',
              color: RBSColors.dynamicRed,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  _showLeistungsnachweisDialog(context, leistungsnachweis: ln),
              tooltip: 'Bearbeiten',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ln),
              tooltip: 'Löschen',
            ),
          ],
        ),
        isThreeLine: true,
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
      case LeistungsnachweisTyp.schulaufgabe:
        return RBSColors.dynamicRed;
      case LeistungsnachweisTyp.stegreifaufgabe:
        return RBSColors.growingElder;
      case LeistungsnachweisTyp.muendlich:
        return RBSColors.courtGreen;
      case LeistungsnachweisTyp.praktisch:
        return const Color(0xFF2E7BB5);
      case LeistungsnachweisTyp.projekt:
        return const Color(0xFF9C27B0);
      case LeistungsnachweisTyp.sonstiges:
        return RBSColors.textOnLight.withValues(alpha: 0.5);
    }
  }

  IconData _getTypIcon(LeistungsnachweisTyp typ) {
    switch (typ) {
      case LeistungsnachweisTyp.schulaufgabe:
        return Icons.description;
      case LeistungsnachweisTyp.stegreifaufgabe:
        return Icons.flash_on;
      case LeistungsnachweisTyp.muendlich:
        return Icons.record_voice_over;
      case LeistungsnachweisTyp.praktisch:
        return Icons.build;
      case LeistungsnachweisTyp.projekt:
        return Icons.folder_special;
      case LeistungsnachweisTyp.sonstiges:
        return Icons.more_horiz;
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
    final maxPunkteController = TextEditingController(
      text: leistungsnachweis?.maxPunkte.toString() ?? '100',
    );
    final beschreibungController = TextEditingController(
      text: leistungsnachweis?.beschreibung ?? '',
    );
    final formKey = GlobalKey<FormState>();

    String? selectedKlasseId = leistungsnachweis?.klasseId;
    String? selectedSubjectId = leistungsnachweis?.subjectId;
    LeistungsnachweisTyp selectedTyp =
        leistungsnachweis?.typ ?? LeistungsnachweisTyp.stegreifaufgabe;
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
                    Text('Klasse *', style: RBSTypography.label),
                    const SizedBox(height: RBSSpacing.xs),
                    klassenAsync.when(
                      data: (klassen) => DropdownButtonFormField<String>(
                        value: selectedKlasseId,
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
                      error: (_, _s) => const Text('Fehler beim Laden'),
                    ),
                    const SizedBox(height: RBSSpacing.md),

                    // Fach auswählen
                    Text('Fach *', style: RBSTypography.label),
                    const SizedBox(height: RBSSpacing.xs),
                    subjectsAsync.when(
                      data: (subjects) => DropdownButtonFormField<String>(
                        value: selectedSubjectId,
                        decoration: const InputDecoration(
                          hintText: 'Fach wählen',
                          border: OutlineInputBorder(),
                        ),
                        items: subjects
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child:
                                    Text(s.shortName ?? s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedSubjectId = value);
                        },
                        validator: (value) =>
                            value == null ? 'Bitte Fach wählen' : null,
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, _s) => const Text('Fehler beim Laden'),
                    ),
                    const SizedBox(height: RBSSpacing.md),

                    // Typ auswählen
                    Text('Typ *', style: RBSTypography.label),
                    const SizedBox(height: RBSSpacing.xs),
                    DropdownButtonFormField<LeistungsnachweisTyp>(
                      value: selectedTyp,
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
                                  Text(t.name),
                                  const SizedBox(width: RBSSpacing.sm),
                                  Text(
                                    '(Gewichtung ${t.gewichtung}x)',
                                    style: RBSTypography.bodySmall.copyWith(
                                      color: RBSColors.textOnLight
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
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
                    Text('Datum *', style: RBSTypography.label),
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

                    // Max Punkte
                    RBSInput(
                      label: 'Maximale Punktzahl',
                      hint: '100',
                      controller: maxPunkteController,
                      keyboardType: TextInputType.number,
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
                    final maxPunkte =
                        double.tryParse(maxPunkteController.text) ?? 100.0;

                    final newLn = Leistungsnachweis(
                      id: leistungsnachweis?.id ?? '',
                      klasseId: selectedKlasseId!,
                      subjectId: selectedSubjectId!,
                      typ: selectedTyp,
                      bezeichnung: bezeichnungController.text.trim(),
                      datum: selectedDatum,
                      maxPunkte: maxPunkte,
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
                    SnackBar(
                      content: const Text('Leistungsnachweis gelöscht'),
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
