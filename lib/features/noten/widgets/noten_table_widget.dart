import 'package:flutter/material.dart';
import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/features/noten/noten_layout_constants.dart';
import 'package:induscore/features/noten/widgets/note_input_widgets.dart';
import 'package:induscore/models/leistungsnachweis.dart';
import 'package:induscore/models/noten_eingabe.dart';
import 'package:induscore/models/noten_statistik.dart';
import 'package:induscore/models/student.dart';
import 'package:induscore/models/tendenz.dart';

/// Widget für die Noten-Tabelle mit Statistiken
class NotenTableWidget extends StatelessWidget {
  final List<Student> students;
  final List<Leistungsnachweis> leistungsnachweise;
  final Map<String, NotenEingabe> noten;
  final OnNoteChanged onNoteChanged;
  final OnTendenzChanged onTendenzChanged;
  final Color Function(int) getNoteColor;
  final double Function(int, Tendenz) getNoteWithTendenz;

  const NotenTableWidget({
    required this.students, required this.leistungsnachweise, required this.noten, required this.onNoteChanged, required this.onTendenzChanged, required this.getNoteColor, required this.getNoteWithTendenz, super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Keine Schüler'),
      );
    }

    // Berechne Mindestbreite für horizontales Scrollen
    final tableWidth = NotenTableDimensions.nameColumnWidth + 
        (leistungsnachweise.length * NotenTableDimensions.lnColumnWidth * 2);

    // Berechne Statistiken pro LN
    final lnStats = _calculateLNStats();

    // Berechne Schüler-Durchschnitte
    final studentStats = _calculateStudentStats();

    // Verwende Expanded in der vertikalen Achse, damit Scrolling funktioniert
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (fixiert)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: tableWidth),
            child: DataTable(
              columnSpacing: NotenTableDimensions.columnSpacing,
              headingRowHeight: NotenTableDimensions.headerHeight,
              dataRowMinHeight: 0,
              dataRowMaxHeight: 0,
              columns: _buildColumns(),
              rows: const [], // Keine Rows im Header
            ),
          ),
        ),

        // Body (scrollbar vertikal und horizontal)
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: tableWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nur die Daten-Rows
                    DataTable(
                      columnSpacing: NotenTableDimensions.columnSpacing,
                      headingRowHeight: 0,
                      dataRowMinHeight: NotenTableDimensions.rowHeightMin,
                      dataRowMaxHeight: NotenTableDimensions.rowHeightMax,
                      columns: _buildColumns()
                          .map(
                            (col) => const DataColumn(label: SizedBox.shrink()),
                          )
                          .toList(),
                      rows: _buildRows(studentStats),
                    ),

                    // Statistik-Footer
                    _buildStatistikFooter(lnStats, studentStats),

                    // Notenverteilung
                    _buildVerteilungFooter(lnStats),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, NotenStatistik> _calculateLNStats() {
    final lnStats = <String, NotenStatistik>{};

    for (final ln in leistungsnachweise) {
      final noten = <double>[];
      int count = 0;
      final verteilung = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

      for (final student in students) {
        final key = '${student.id}_${ln.id}';
        final eingabe = this.noten[key];
        if (eingabe?.note != null) {
          final noteValue = getNoteWithTendenz(eingabe!.note!, eingabe.tendenz);
          noten.add(noteValue);
          count++;
          verteilung[eingabe.note!] = (verteilung[eingabe.note!] ?? 0) + 1;
        }
      }

      final durchschnitt = noten.isEmpty
          ? null
          : noten.reduce((a, b) => a + b) / noten.length;

      lnStats[ln.id] = NotenStatistik(
        durchschnitt: durchschnitt,
        anzahl: count,
        gesamt: students.length,
        verteilung: verteilung,
      );
    }

    return lnStats;
  }

  Map<String, double?> _calculateStudentStats() {
    final studentStats = <String, double?>{};

    for (final student in students) {
      final noten = <double>[];
      double gewichtungsSumme = 0;

      for (final ln in leistungsnachweise) {
        final key = '${student.id}_${ln.id}';
        final eingabe = this.noten[key];
        if (eingabe?.note != null) {
          final noteValue = getNoteWithTendenz(eingabe!.note!, eingabe.tendenz);
          noten.add(noteValue * ln.gewichtung);
          gewichtungsSumme += ln.gewichtung;
        }
      }

      studentStats[student.id] = gewichtungsSumme > 0
          ? noten.reduce((a, b) => a + b) / gewichtungsSumme
          : null;
    }

    return studentStats;
  }

  List<DataColumn> _buildColumns() {
    return [
      const DataColumn(
        label: SizedBox(
          width: NotenTableDimensions.nameColumnWidth,
          child: Text(
            'Schüler',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: NotenFontSizes.header,
            ),
          ),
        ),
      ),
      ...leistungsnachweise.map(
        (ln) => DataColumn(
          label: SizedBox(
            width: NotenTableDimensions.lnColumnWidth * 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ln.bezeichnung,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: NotenFontSizes.header,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                Text(
                  '${ln.typ.label} ${ln.gewichtung}x',
                  style: TextStyle(
                    fontSize: NotenFontSizes.kuerzel + 2,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Spalte für Schüler-Durchschnitt
      const DataColumn(
        label: SizedBox(
          width: NotenTableDimensions.avgColumnWidth,
          child: Text(
            '⌀',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: NotenFontSizes.average + 2,
            ),
          ),
        ),
      ),
    ];
  }

  List<DataRow> _buildRows(Map<String, double?> studentStats) {
    return students.map((student) {
      return DataRow(
        cells: [
          DataCell(
            SizedBox(
              width: NotenTableDimensions.nameColumnWidth,
              child: Text(
                student.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: NotenFontSizes.studentName),
              ),
            ),
          ),
          ...leistungsnachweise.map((ln) {
            final key = '${student.id}_${ln.id}';
            final eingabe = noten[key];
            if (eingabe == null) {
              return const DataCell(Text('-'));
            }

            return DataCell(
              SizedBox(
                width: NotenTableDimensions.lnColumnWidth * 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CompactNoteDropdown(
                      inputKey: key,
                      eingabe: eingabe,
                      studentId: student.id,
                      lnId: ln.id,
                      onNoteChanged: onNoteChanged,
                      getNoteColor: getNoteColor,
                    ),
                    // v0.33.0: Tendenz-Buttons aus UI entfernt (F-004)
                    // const SizedBox(width: NotenSpacing.xs),
                    // CompactTendenzButtons(
                    //   inputKey: key,
                    //   eingabe: eingabe,
                    //   studentId: student.id,
                    //   lnId: ln.id,
                    //   onTendenzChanged: onTendenzChanged,
                    // ),
                  ],
                ),
              ),
            );
          }),
          // Schüler-Durchschnitt
          DataCell(
            SizedBox(
              width: NotenTableDimensions.avgColumnWidth,
              child: studentStats[student.id] != null
                  ? Text(
                      studentStats[student.id]!.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: NotenFontSizes.average,
                        color: getNoteColor(studentStats[student.id]!.round()),
                      ),
                    )
                  : const Text('-', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildStatistikFooter(
    Map<String, NotenStatistik> lnStats,
    Map<String, double?> studentStats,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: RBSColors.paper,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Schüler-Spalte Label
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⌀ Durchschnitt',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  'Eingetragen',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Stats pro LN
          ...leistungsnachweise.map((ln) {
            final stats = lnStats[ln.id];
            return SizedBox(
              width: 118,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats?.durchschnitt != null
                        ? stats!.durchschnitt!.toStringAsFixed(2)
                        : '-',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: stats?.durchschnitt != null
                          ? getNoteColor(stats!.durchschnitt!.round())
                          : Colors.grey,
                    ),
                  ),
                  Text(
                    '${stats?.anzahl ?? 0}/${stats?.gesamt ?? 0}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }),
          // Gesamt-Durchschnitt
          SizedBox(width: 70, child: _buildGesamtDurchschnitt(studentStats)),
        ],
      ),
    );
  }

  Widget _buildVerteilungFooter(Map<String, NotenStatistik> lnStats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 140,
            child: Text(
              'Verteilung',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          ...leistungsnachweise.map((ln) {
            final stats = lnStats[ln.id];
            return SizedBox(
              width: 118,
              child: _buildVerteilungChips(stats?.verteilung ?? {}),
            );
          }),
          const SizedBox(width: 70), // Platzhalter für Durchschnitt-Spalte
        ],
      ),
    );
  }

  Widget _buildGesamtDurchschnitt(Map<String, double?> studentStats) {
    final validStats = studentStats.values.whereType<double>().toList();
    if (validStats.isEmpty) {
      return const Text('-', style: TextStyle(color: Colors.grey));
    }
    final gesamt = validStats.reduce((a, b) => a + b) / validStats.length;
    return Text(
      gesamt.toStringAsFixed(2),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: getNoteColor(gesamt.round()),
      ),
    );
  }

  Widget _buildVerteilungChips(Map<int, int> verteilung) {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: [1, 2, 3, 4, 5, 6].where((n) => (verteilung[n] ?? 0) > 0).map((
        note,
      ) {
        final count = verteilung[note] ?? 0;
        final color = NotenColors.getColor(note);
        final isCritical = note >= 5;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            // v0.29.0: Nur kritische Noten farbig, andere dezent
            color: isCritical 
                ? color.withValues(alpha: 0.15) 
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isCritical 
                  ? color.withValues(alpha: 0.3) 
                  : NotenColors.border,
            ),
          ),
          child: Text(
            '$note:$count',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }
}
