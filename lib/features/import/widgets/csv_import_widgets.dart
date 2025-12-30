import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/core/widgets/rbs_components.dart';
import 'package:induscore/providers/app_providers.dart';
import 'package:induscore/services/csv_import_service.dart';

/// Gemeinsame Widgets für CSV Import Screen
class CsvImportWidgets {
  CsvImportWidgets._();

  /// Step Card mit Indikator (1, 2, 3, 4)
  static Widget buildStepCard({
    required BuildContext context,
    required int step,
    required String title,
    required bool isActive,
    required bool isComplete,
    required Widget child,
  }) {
    return RBSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isComplete
                  ? RBSColors.courtGreen.withValues(alpha: 0.1)
                  : isActive
                  ? RBSColors.dynamicRed.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isComplete
                      ? RBSColors.courtGreen
                      : isActive
                      ? RBSColors.dynamicRed
                      : Colors.grey.shade400,
                  child: isComplete
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$step',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isComplete
                        ? RBSColors.courtGreen
                        : isActive
                        ? RBSColors.dynamicRed
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  /// Column Mapping Chip (CSV Spalte → Feld)
  static Widget buildColumnMappingChip({
    required int index,
    required String header,
    required CsvColumn? mapping,
    required VoidCallback onPressed,
  }) {
    return InputChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(header, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            mapping?.label ?? 'Ignorieren',
            style: TextStyle(
              fontSize: 12,
              color: mapping != null ? RBSColors.dynamicRed : Colors.grey,
              fontWeight: mapping != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      onPressed: onPressed,
      backgroundColor: mapping != null
          ? RBSColors.dynamicRed.withValues(alpha: 0.1)
          : Colors.grey.shade100,
    );
  }

  /// Preview Table (erste 5 Zeilen)
  static Widget buildPreviewTable({
    required CsvAnalysisResult analysisResult,
    required Map<int, CsvColumn> columnMapping,
  }) {
    final rows = analysisResult.rows.take(5).toList();
    final lastNameIdx = columnMapping.entries
        .where((e) => e.value == CsvColumn.lastName)
        .map((e) => e.key)
        .firstOrNull;
    final firstNameIdx = columnMapping.entries
        .where((e) => e.value == CsvColumn.firstName)
        .map((e) => e.key)
        .firstOrNull;
    final classIdx = columnMapping.entries
        .where((e) => e.value == CsvColumn.className)
        .map((e) => e.key)
        .firstOrNull;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
          columns: const [
            DataColumn(label: Text('Vorname')),
            DataColumn(label: Text('Nachname')),
            DataColumn(label: Text('Klasse')),
          ],
          rows: rows.map((row) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    firstNameIdx != null && firstNameIdx < row.length
                        ? row[firstNameIdx]
                        : '-',
                  ),
                ),
                DataCell(
                  Text(
                    lastNameIdx != null && lastNameIdx < row.length
                        ? row[lastNameIdx]
                        : '-',
                  ),
                ),
                DataCell(
                  Text(
                    classIdx != null && classIdx < row.length
                        ? row[classIdx]
                        : '-',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Statistics Chip
  static Widget buildStatChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

/// Klasse Dropdown Widget (mit Auto-Selection)
class KlasseDropdownWidget extends ConsumerStatefulWidget {
  final String? selectedKlasseId;
  final String? detectedClassName;
  final ValueChanged<String?> onChanged;

  const KlasseDropdownWidget({
    required this.selectedKlasseId,
    required this.onChanged,
    super.key,
    this.detectedClassName,
  });

  @override
  ConsumerState<KlasseDropdownWidget> createState() =>
      _KlasseDropdownWidgetState();
}

class _KlasseDropdownWidgetState extends ConsumerState<KlasseDropdownWidget> {
  bool _autoSelectAttempted = false;

  @override
  Widget build(BuildContext context) {
    final klassenAsync = ref.watch(klassenProvider);

    return klassenAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, _) => Text('Fehler: $err'),
      data: (klassen) {
        // Auto-Select wenn erkannter Klassenname passt (nur 1x versuchen)
        if (!_autoSelectAttempted &&
            widget.selectedKlasseId == null &&
            widget.detectedClassName != null) {
          _autoSelectAttempted = true;
          for (final klasse in klassen) {
            if (klasse.name == widget.detectedClassName) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) widget.onChanged(klasse.id);
              });
              break;
            }
          }
        }

        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Klasse auswählen',
            border: OutlineInputBorder(),
          ),
          initialValue: widget.selectedKlasseId,
          items: klassen
              .map((k) => DropdownMenuItem(value: k.id, child: Text(k.name)))
              .toList(),
          onChanged: widget.onChanged,
        );
      },
    );
  }
}
