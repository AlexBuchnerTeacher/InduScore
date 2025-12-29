import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/rbs_theme.dart';
import '../core/widgets/rbs_components.dart';
import '../models/subject.dart';
import '../models/beruf.dart';
import '../providers/app_providers.dart';
import '../widgets/dialogs/common_dialogs.dart';
import '../widgets/rbs_drawer.dart';
import '../providers/permissions_providers.dart';

/// Fächerverwaltung Screen
/// - Listet alle Fächer (Subjects) mit Filter nach Beruf
/// - Ermöglicht CRUD (Create, Read, Update, Delete) für Fächer
/// - Nutzt RBS Styleguide 1.2 (Farben, Typografie, Layout)
/// - Riverpod für State Management
/// - Firestore als Backend
class FaecherScreen extends ConsumerStatefulWidget {
  const FaecherScreen({super.key});

  @override
  ConsumerState<FaecherScreen> createState() => _FaecherScreenState();
}

class _FaecherScreenState extends ConsumerState<FaecherScreen> {
  // Aktuell ausgewählte Berufe für Multi-Select Filter
  // ignore: prefer_final_fields
  Set<Beruf> _selectedBerufe = {};

  @override
  Widget build(BuildContext context) {
    // Holt alle Fächer aus Firestore via Riverpod
    final subjectsAsync = ref.watch(subjectsProvider);
    final canManageData = ref.watch(canManageDataProvider);

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
          title: const Text('Fächerverwaltung'),
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
                'Sie haben keine Berechtigung zur Fächerverwaltung.',
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
        title: const Text('Fächerverwaltung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: 'Zum Dashboard',
          ),
          // Neues Fach Button - nur für Admin
          Consumer(
            builder: (context, ref, _) {
              final canCreate = ref.watch(canCreateDataProvider);
              if (!canCreate) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showSubjectDialog,
                tooltip: 'Neues Fach',
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
            child: Wrap(
              spacing: RBSSpacing.sm,
              runSpacing: RBSSpacing.sm,
              children: [
                // Beruf Filter (IE, EAT, EBT, EGS)
                ...Beruf.values.map(
                  (beruf) => RBSFilterChip(
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
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Fächer-Liste (gefiltert)
          Expanded(
            child: subjectsAsync.when(
              data: (subjects) {
                // Filter anwenden
                var filtered = subjects;
                if (_selectedBerufe.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (s) => s.berufe.any((b) => _selectedBerufe.contains(b)),
                      )
                      .toList();
                }

                // Empty State: Keine Fächer vorhanden
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Keine Fächer gefunden',
                          style: RBSTypography.h3.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Füge dein erstes Fach hinzu',
                          style: RBSTypography.bodyMedium.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showSubjectDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Erstes Fach erstellen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RBSColors.dynamicRed,
                            foregroundColor: RBSColors.textOnRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Fächer-Liste mit Cards
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final subject = filtered[index];
                    return _SubjectCard(
                      subject: subject,
                      onEdit: () => _showSubjectDialog(subject: subject),
                      onDelete: () => _deleteSubject(subject),
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

  void _showSubjectDialog({Subject? subject}) {
    showDialog(
      context: context,
      builder: (context) => _SubjectDialog(subject: subject),
    );
  }

  void _deleteSubject(Subject subject) async {
    if (!mounted) return;

    await CommonDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Fach löschen?',
      itemName: subject.name,
      additionalWarning:
          'Alle Noten und Leistungsnachweise für dieses Fach werden ebenfalls gelöscht!',
      onDelete: () async {
        await ref.read(firestoreServiceProvider).deleteSubject(subject.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${subject.name} wurde gelöscht'),
              backgroundColor: RBSColors.success,
            ),
          );
        }
      },
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
        return Colors.blue;
    }
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.subject,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subjectColor =
        RBSColors.fromHex(subject.color) ?? RBSColors.dynamicRed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/faecher/${subject.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Fach Icon mit Fachfarbe
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: subjectColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconForTyp(subject.typ),
                      color: subjectColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Fachname
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subject.name, style: RBSTypography.h4),
                        if (subject.shortName != null)
                          Text(
                            subject.shortName!,
                            style: RBSTypography.bodySmall.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Farbindikator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: subjectColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Actions
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Bearbeiten'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Löschen',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Berufe Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: subject.berufe
                    .map(
                      (beruf) => Chip(
                        label: Text(
                          beruf.code,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: _getBerufColor(
                          beruf,
                        ).withValues(alpha: 0.2),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForTyp(FachTyp typ) {
    switch (typ) {
      case FachTyp.allgemein:
        return Icons.menu_book;
      case FachTyp.beruflich:
        return Icons.work;
      case FachTyp.lernfeld:
        return Icons.school;
    }
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
        return Colors.blue;
    }
  }
}

class _SubjectDialog extends ConsumerStatefulWidget {
  final Subject? subject;

  const _SubjectDialog({this.subject});

  @override
  ConsumerState<_SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends ConsumerState<_SubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _shortNameController;
  late TextEditingController _hexColorController;
  late Set<Beruf> _selectedBerufe;
  Color? _selectedColor;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name);
    _shortNameController = TextEditingController(
      text: widget.subject?.shortName,
    );
    _selectedBerufe = widget.subject?.berufe.toSet() ?? {};
    _selectedColor = widget.subject?.color != null
        ? RBSColors.fromHex(widget.subject!.color)
        : RBSColors.subjectColors.first;
    _hexColorController = TextEditingController(
      text: _selectedColor != null ? RBSColors.toHex(_selectedColor!) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _hexColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.subject == null ? 'Neues Fach' : 'Fach bearbeiten',
        style: GoogleFonts.roboto(),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Fachname *',
                    hintText: 'z.B. Mathematik',
                    border: const OutlineInputBorder(),
                    labelStyle: GoogleFonts.roboto(),
                    hintStyle: GoogleFonts.roboto(),
                  ),
                  style: GoogleFonts.roboto(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte Fachnamen eingeben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Short Name
                TextFormField(
                  controller: _shortNameController,
                  decoration: InputDecoration(
                    labelText: 'Kürzel',
                    hintText: 'z.B. MA',
                    border: const OutlineInputBorder(),
                    labelStyle: GoogleFonts.roboto(),
                    hintStyle: GoogleFonts.roboto(),
                  ),
                  style: GoogleFonts.roboto(),
                ),
                const SizedBox(height: 16),

                // Berufe
                Text(
                  'Berufe *',
                  style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Beruf.values.map((beruf) {
                    final isSelected = _selectedBerufe.contains(beruf);
                    return FilterChip(
                      label: Text(beruf.name, style: GoogleFonts.roboto()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedBerufe.add(beruf);
                          } else {
                            _selectedBerufe.remove(beruf);
                          }
                        });
                      },
                      selectedColor: _getBerufColor(
                        beruf,
                      ).withValues(alpha: 0.2),
                      checkmarkColor: _getBerufColor(beruf),
                      side: BorderSide(color: _getBerufColor(beruf), width: 2),
                    );
                  }).toList(),
                ),
                if (_selectedBerufe.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Bitte mindestens einen Beruf auswählen',
                      style: GoogleFonts.roboto(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Farbauswahl
                Text(
                  'Farbe',
                  style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Farbpalette
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RBSColors.subjectColors.map((color) {
                    final isSelected =
                        _selectedColor?.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                          _hexColorController.text = RBSColors.toHex(color);
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Hex-Code Input
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _selectedColor ?? RBSColors.dynamicRed,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _hexColorController,
                        decoration: InputDecoration(
                          labelText: 'Hex-Code',
                          hintText: '#FF5E35',
                          border: const OutlineInputBorder(),
                          labelStyle: GoogleFonts.roboto(),
                          hintStyle: GoogleFonts.roboto(),
                          prefixIcon: const Icon(Icons.color_lens_outlined),
                        ),
                        style: GoogleFonts.roboto(),
                        onChanged: (value) {
                          final color = RBSColors.fromHex(value);
                          if (color != null) {
                            setState(() => _selectedColor = color);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveSubject,
          style: ElevatedButton.styleFrom(
            backgroundColor: RBSColors.dynamicRed,
            foregroundColor: RBSColors.textOnRed,
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }

  void _saveSubject() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBerufe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte mindestens einen Beruf auswählen'),
          backgroundColor: RBSColors.error,
        ),
      );
      return;
    }

    Subject subject = Subject(
      id: widget.subject?.id ?? '',
      name: _nameController.text.trim(),
      shortName: _shortNameController.text.trim().isEmpty
          ? null
          : _shortNameController.text.trim(),
      typ: widget.subject?.typ ?? FachTyp.beruflich,
      berufe: _selectedBerufe.toList(),
      wochenstunden: widget.subject?.wochenstunden ?? 2,
      credits: widget.subject?.credits ?? 3.0,
      color: _selectedColor != null ? RBSColors.toHex(_selectedColor!) : null,
      createdAt: widget.subject?.createdAt ?? DateTime.now(),
    );

    // Logging: Subject-Daten vor dem Speichern
    log('Subject vor Save: ${subject.toFirestore()}');
    try {
      setState(() => _isSaving = true);
      final firestoreService = ref.read(firestoreServiceProvider);
      if (widget.subject == null) {
        final newId = await firestoreService.createSubject(subject);
        if (newId.isEmpty) {
          throw Exception('Firestore hat keine ID zurückgegeben');
        }
        subject = subject.copyWith(id: newId);
        log('Neues Fach gespeichert mit ID: $newId');
      } else {
        await firestoreService.updateSubject(subject);
        log('Fach aktualisiert: ${subject.id}');
      }

      if (mounted) {
        Navigator.pop(context);
        // SnackBar nach kurzem Delay, damit das Dialog-Widget sicher disposed ist
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.subject == null
                      ? 'Fach "${subject.name}" erstellt'
                      : 'Fach "${subject.name}" aktualisiert',
                ),
                backgroundColor: RBSColors.success,
              ),
            );
          }
        });
      }
    } catch (e, stack) {
      log('Fehler beim Speichern des Fachs: $e', error: e, stackTrace: stack);
      if (mounted) {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fehler beim Speichern: $e'),
                backgroundColor: RBSColors.error,
              ),
            );
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
        return Colors.blue;
    }
  }
}
