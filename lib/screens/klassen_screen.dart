import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import '../core/theme/rbs_theme.dart';
import '../widgets/rbs_drawer.dart';
import '../core/widgets/rbs_components.dart';
import '../models/klasse.dart';
import '../providers/app_providers.dart';
import '../services/pdf_import_service.dart';
import '../providers/permissions_providers.dart';
import '../widgets/klassen/klassen_filter_section.dart';
import '../widgets/klassen/klasse_card.dart';
import '../widgets/dialogs/klasse_edit_dialog.dart';
import '../widgets/dialogs/klasse_delete_dialog.dart';

class KlassenScreen extends ConsumerStatefulWidget {
  const KlassenScreen({super.key});

  @override
  ConsumerState<KlassenScreen> createState() => _KlassenScreenState();
}

class _KlassenScreenState extends ConsumerState<KlassenScreen> {
  // ignore: prefer_final_fields
  Set<String> _selectedBerufe = {};
  String? _selectedSchuljahr;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final klassenAsync = ref.watch(klassenProvider);
    final filteredByZG = ref.watch(filteredKlassenProvider);
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
          title: const Text('Klassenverwaltung'),
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
                'Sie haben keine Berechtigung zur Klassenverwaltung.',
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
        title: const Text('Klassenverwaltung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: 'Zum Dashboard',
          ),
          // Import Button - nur für Admin
          Consumer(
            builder: (context, ref, _) {
              final canCreate = ref.watch(canCreateDataProvider);
              if (!canCreate) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(right: RBSSpacing.sm),
                child: _isImporting
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton.icon(
                        onPressed: _handlePdfImport,
                        icon: const Icon(
                          Icons.upload_file,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'PDF Import',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              );
            },
          ),
          // Neue Klasse Button - nur für Admin
          Consumer(
            builder: (context, ref, _) {
              final canCreate = ref.watch(canCreateDataProvider);
              if (!canCreate) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showKlasseDialog(context),
                tooltip: 'Neue Klasse',
              );
            },
          ),
        ],
      ),
      drawer: const RBSDrawer(),
      body: Column(
        children: [
          // Filter Section
          // Filter Section
          KlassenFilterSection(
            selectedBerufe: _selectedBerufe,
            selectedSchuljahr: _selectedSchuljahr,
            onBerufFilterChanged: (newSelection) {
              setState(() => _selectedBerufe = newSelection);
            },
            onSchuljahrFilterChanged: (newSchuljahr) {
              setState(() => _selectedSchuljahr = newSchuljahr);
            },
          ),

          // Klassen List
          Expanded(
            child: klassenAsync.when(
              data: (klassen) {
                // Start with ZG-filtered classes
                var filteredKlassen = filteredByZG;
                if (_selectedSchuljahr != null) {
                  filteredKlassen = filteredKlassen
                      .where(
                        (k) => k.schuljahr.toString() == _selectedSchuljahr,
                      )
                      .toList();
                }
                if (_selectedBerufe.isNotEmpty) {
                  filteredKlassen = filteredKlassen
                      .where((k) => _selectedBerufe.contains(k.beruf.code))
                      .toList();
                }

                if (filteredKlassen.isEmpty) {
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
                          'Keine Klassen gefunden',
                          style: RBSTypography.h4.copyWith(
                            color: RBSColors.textOnLight.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: RBSSpacing.sm),
                        Consumer(
                          builder: (context, ref, _) {
                            final canCreate = ref.watch(canCreateDataProvider);
                            if (!canCreate) return const SizedBox.shrink();
                            return RBSButton(
                              label: 'Erste Klasse erstellen',
                              icon: Icons.add,
                              onPressed: () => _showKlasseDialog(context),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(RBSSpacing.md),
                  itemCount: filteredKlassen.length,
                  itemBuilder: (context, index) {
                    final klasse = filteredKlassen[index];
                    return KlasseCard(
                      klasse: klasse,
                      onEdit: () => _showKlasseDialog(context, klasse: klasse),
                      onDelete: () => _confirmDelete(context, klasse),
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

  void _showKlasseDialog(BuildContext context, {Klasse? klasse}) {
    showDialog(
      context: context,
      builder: (context) => KlasseEditDialog(
        klasse: klasse,
        currentSchuljahr: ref.read(currentSchuljahrProvider),
        onSave: (newKlasse) async {
          final firestoreService = ref.read(firestoreServiceProvider);
          if (klasse != null) {
            await firestoreService.updateKlasse(newKlasse);
          } else {
            await firestoreService.createKlasse(newKlasse);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Klasse klasse) {
    showDialog(
      context: context,
      builder: (context) => KlasseDeleteDialog(
        klasse: klasse,
        onDelete: () async {
          final firestoreService = ref.read(firestoreServiceProvider);
          await firestoreService.deleteKlasse(klasse.id);
        },
      ),
    );
  }

  Future<void> _handlePdfImport() async {
    // final schuljahr = ref.read(currentSchuljahrProvider); // TODO: Will be used when dialog is implemented
    try {
      setState(() => _isImporting = true);
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (picked == null) return;
      final file = picked.files.single;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF konnte nicht gelesen werden.')),
          );
        }
        return;
      }

      final importService = PdfImportService();
      final preview = await importService.parseClassList(bytes);

      if (!mounted) return;
      
      // TODO: Implement ImportPreviewDialog - temporarily show simple message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${preview.students.length} Schüler gefunden. Import-Dialog wird noch implementiert.'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import fehlgeschlagen: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
}
