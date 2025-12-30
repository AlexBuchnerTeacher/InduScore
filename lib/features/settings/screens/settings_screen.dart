import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:induscore/models/beruf.dart';
import 'package:induscore/models/subject.dart';
import 'package:induscore/providers/app_providers.dart';
import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/shared/widgets/app_snack_bars.dart';
import 'package:induscore/widgets/dialogs/common_dialogs.dart';

/// Settings-Screen für globale Verwaltung von Berufen und Fächern
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RBSColors.paper,
      appBar: AppBar(
        backgroundColor: RBSColors.dynamicRed,
        foregroundColor: RBSColors.white,
        title: const Text(
          'Admin Einstellungen',
          style: TextStyle(
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: RBSColors.white,
          unselectedLabelColor: RBSColors.white.withValues(alpha: 0.7),
          indicatorColor: RBSColors.white,
          tabs: const [
            Tab(text: 'Berufe'),
            Tab(text: 'Fächer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_BerufeTab(), _FaecherTab()],
      ),
    );
  }
}

/// Tab für Berufe-Verwaltung
class _BerufeTab extends ConsumerWidget {
  const _BerufeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(RBSSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Card(
            elevation: 1.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RBSBorderRadius.medium),
            ),
            child: const Padding(
              padding: EdgeInsets.all(RBSSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: RBSColors.dynamicRed),
                  SizedBox(width: RBSSpacing.sm),
                  Expanded(
                    child: Text(
                      'Berufe sind aktuell fest im System hinterlegt. '
                      'Neue Berufe können in zukünftigen Versionen hinzugefügt werden.',
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 14,
                        color: RBSColors.textOnLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: RBSSpacing.lg),

          // Berufe Liste
          const Text(
            'Verfügbare Berufe',
            style: TextStyle(
              fontFamily: 'RobotoCondensed',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: RBSColors.textOnLight,
            ),
          ),
          const SizedBox(height: RBSSpacing.md),

          Expanded(
            child: ListView.builder(
              itemCount: Beruf.values.length,
              itemBuilder: (context, index) {
                final beruf = Beruf.values[index];
                return Card(
                  elevation: 1.0,
                  margin: const EdgeInsets.only(bottom: RBSSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RBSBorderRadius.medium),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: RBSColors.dynamicRed.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        beruf.code,
                        style: const TextStyle(
                          fontFamily: 'RobotoCondensed',
                          fontWeight: FontWeight.bold,
                          color: RBSColors.dynamicRed,
                        ),
                      ),
                    ),
                    title: Text(
                      beruf.name,
                      style: const TextStyle(
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Code: ${beruf.code}',
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 12,
                        color: RBSColors.textOnLight.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab für Fächer-Verwaltung
class _FaecherTab extends ConsumerWidget {
  const _FaecherTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = ref.watch(firestoreServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(RBSSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Add-Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Globale Fächerliste',
                style: TextStyle(
                  fontFamily: 'RobotoCondensed',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: RBSColors.textOnLight,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddFachDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Fach hinzufügen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RBSColors.dynamicRed,
                  foregroundColor: RBSColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RBSBorderRadius.small),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RBSSpacing.md),

          // Fächer Liste
          Expanded(
            child: StreamBuilder<List<Subject>>(
              stream: firestoreService.getSubjects(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Fehler beim Laden: ${snapshot.error}',
                      style: const TextStyle(fontFamily: 'OpenSans'),
                    ),
                  );
                }

                final subjects = snapshot.data ?? [];

                if (subjects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: RBSColors.textOnLight.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: RBSSpacing.md),
                        Text(
                          'Noch keine Fächer angelegt',
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 16,
                            color: RBSColors.textOnLight.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return Card(
                      elevation: 1.0,
                      margin: const EdgeInsets.only(bottom: RBSSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          RBSBorderRadius.medium,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: subject.color != null
                              ? Color(int.parse('0xFF${subject.color!.replaceAll('#', '')}'))
                              : RBSColors.courtGreen.withValues(alpha: 0.2),
                          child: Text(
                            subject.shortName ?? subject.name[0],
                            style: const TextStyle(
                              fontFamily: 'RobotoCondensed',
                              fontWeight: FontWeight.bold,
                              color: RBSColors.textOnLight,
                            ),
                          ),
                        ),
                        title: Text(
                          subject.name,
                          style: const TextStyle(
                            fontFamily: 'OpenSans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.typ.name,
                              style: TextStyle(
                                fontFamily: 'OpenSans',
                                fontSize: 12,
                                color: RBSColors.textOnLight.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            if (subject.berufe.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                children: subject.berufe
                                    .map(
                                      (beruf) => Chip(
                                        label: Text(
                                          beruf.code,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: RBSColors.dynamicRed
                                            .withValues(alpha: 0.1),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _showEditFachDialog(context, ref, subject),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: RBSColors.error,
                              onPressed: () =>
                                  _deleteFach(context, ref, subject),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFachDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _FachDialog(ref: ref),
    );
  }

  void _showEditFachDialog(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
  ) {
    showDialog(
      context: context,
      builder: (context) => _FachDialog(ref: ref, subject: subject),
    );
  }

  void _deleteFach(BuildContext context, WidgetRef ref, Subject subject) {
    CommonDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Fach löschen?',
      itemName: subject.name,
      onDelete: () async {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.deleteSubject(subject.id);
        if (context.mounted) {
          AppSnackBars.showSuccess(context, '${subject.name} wurde gelöscht');
        }
      },
    );
  }
}

/// Dialog zum Erstellen/Bearbeiten eines Fachs
class _FachDialog extends StatefulWidget {
  final WidgetRef ref;
  final Subject? subject;

  const _FachDialog({required this.ref, this.subject});

  @override
  State<_FachDialog> createState() => _FachDialogState();
}

class _FachDialogState extends State<_FachDialog> {
  late TextEditingController _nameController;
  late TextEditingController _shortNameController;
  late TextEditingController _wochenstundenController;
  late TextEditingController _creditsController;

  FachTyp _selectedTyp = FachTyp.beruflich;
  Set<Beruf> _selectedBerufe = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _shortNameController = TextEditingController(
      text: widget.subject?.shortName ?? '',
    );
    _wochenstundenController = TextEditingController(
      text: widget.subject?.wochenstunden.toString() ?? '2',
    );
    _creditsController = TextEditingController(
      text: widget.subject?.credits.toString() ?? '3.0',
    );

    if (widget.subject != null) {
      _selectedTyp = widget.subject!.typ;
      _selectedBerufe = widget.subject!.berufe.toSet();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _wochenstundenController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.subject != null;

    return AlertDialog(
      title: Text(isEdit ? 'Fach bearbeiten' : 'Neues Fach'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Fachname',
                hintText: 'z.B. Grundlagen der Elektrotechnik',
              ),
            ),
            const SizedBox(height: RBSSpacing.sm),
            TextField(
              controller: _shortNameController,
              decoration: const InputDecoration(
                labelText: 'Kürzel (optional)',
                hintText: 'z.B. GET',
              ),
            ),
            const SizedBox(height: RBSSpacing.md),
            DropdownButtonFormField<FachTyp>(
              initialValue: _selectedTyp,
              decoration: const InputDecoration(labelText: 'Fachtyp'),
              items: FachTyp.values
                  .map(
                    (typ) =>
                        DropdownMenuItem(value: typ, child: Text(typ.name)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTyp = value);
                }
              },
            ),
            const SizedBox(height: RBSSpacing.md),
            TextField(
              controller: _wochenstundenController,
              decoration: const InputDecoration(labelText: 'Wochenstunden'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: RBSSpacing.sm),
            TextField(
              controller: _creditsController,
              decoration: const InputDecoration(labelText: 'Credits'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: RBSSpacing.md),
            const Text(
              'Zugeordnete Berufe:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: RBSSpacing.sm),
            ...Beruf.values.map(
              (beruf) => CheckboxListTile(
                title: Text('${beruf.code} - ${beruf.name}'),
                value: _selectedBerufe.contains(beruf),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedBerufe.add(beruf);
                    } else {
                      _selectedBerufe.remove(beruf);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveFach,
          style: ElevatedButton.styleFrom(
            backgroundColor: RBSColors.dynamicRed,
            foregroundColor: RBSColors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }

  Future<void> _saveFach() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackBars.showError(context, 'Fachname darf nicht leer sein');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestoreService = widget.ref.read(firestoreServiceProvider);

      final subject = Subject(
        id: widget.subject?.id ?? '',
        name: name,
        shortName: _shortNameController.text.trim().isEmpty
            ? null
            : _shortNameController.text.trim(),
        typ: _selectedTyp,
        berufe: _selectedBerufe.toList(),
        wochenstunden: int.tryParse(_wochenstundenController.text) ?? 2,
        credits: double.tryParse(_creditsController.text) ?? 3.0,
        createdAt: widget.subject?.createdAt ?? DateTime.now(),
      );

      if (widget.subject == null) {
        await firestoreService.createSubject(subject);
      } else {
        await firestoreService.updateSubject(subject);
      }

      if (mounted) {
        Navigator.pop(context);
        AppSnackBars.showSuccess(
          context,
          widget.subject == null
              ? 'Fach wurde hinzugefügt'
              : 'Fach wurde aktualisiert',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBars.showError(context, 'Fehler', error: e);
      }
    }
  }
}
