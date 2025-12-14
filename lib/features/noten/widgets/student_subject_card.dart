import 'package:flutter/material.dart';
import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/features/noten/widgets/note_input_widgets.dart';
import 'package:induscore/models/leistungsnachweis.dart';
import 'package:induscore/models/noten_eingabe.dart';
import 'package:induscore/models/student.dart';
import 'package:induscore/models/subject.dart';
import 'package:induscore/models/tendenz.dart';

/// Widget für Schüler-Fach-Card mit allen Leistungsnachweisen
class StudentSubjectCard extends StatelessWidget {
  final Student student;
  final Subject? subject;
  final List<Leistungsnachweis> leistungsnachweise;
  final Map<String, NotenEingabe> noten;
  final OnNoteChanged onNoteChanged;
  final OnTendenzChanged onTendenzChanged;
  final Color Function(int) getNoteColor;
  final double Function(int, Tendenz) getNoteWithTendenz;
  final String Function(DateTime) formatDate;

  const StudentSubjectCard({
    super.key,
    required this.student,
    required this.subject,
    required this.leistungsnachweise,
    required this.noten,
    required this.onNoteChanged,
    required this.onTendenzChanged,
    required this.getNoteColor,
    required this.getNoteWithTendenz,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    // Berechne Durchschnitt für dieses Fach
    final stats = _calculateStats();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fach-Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RBSColors.courtGreen.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    subject?.name ?? 'Unbekanntes Fach',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Durchschnitt Badge
                if (stats.durchschnitt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: getNoteColor(stats.durchschnitt!.round())
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: getNoteColor(stats.durchschnitt!.round()),
                      ),
                    ),
                    child: Text(
                      '⌀ ${stats.durchschnitt!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: getNoteColor(stats.durchschnitt!.round()),
                      ),
                    ),
                  ),
                if (stats.durchschnitt == null)
                  Text(
                    '${stats.anzahl}/${leistungsnachweise.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          // Einzelne Leistungsnachweise
          ...leistungsnachweise.map((ln) => _buildLNRow(ln)),
          // Footer mit Anzahl
          if (stats.anzahl > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '${stats.anzahl} von ${leistungsnachweise.length} Noten eingetragen',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  ({double? durchschnitt, int anzahl}) _calculateStats() {
    double summe = 0;
    double gewichtungsSumme = 0;
    int anzahl = 0;

    for (final ln in leistungsnachweise) {
      final key = '${student.id}_${ln.id}';
      final eingabe = noten[key];
      if (eingabe?.note != null) {
        final noteValue = getNoteWithTendenz(eingabe!.note!, eingabe.tendenz);
        summe += noteValue * ln.gewichtung;
        gewichtungsSumme += ln.gewichtung;
        anzahl++;
      }
    }

    final durchschnitt =
        gewichtungsSumme > 0 ? summe / gewichtungsSumme : null;

    return (durchschnitt: durchschnitt, anzahl: anzahl);
  }

  Widget _buildLNRow(Leistungsnachweis ln) {
    final key = '${student.id}_${ln.id}';
    final eingabe = noten[key];
    if (eingabe == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // LN-Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ln.bezeichnung,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${ln.typ.label} • ${ln.gewichtung}x • ${formatDate(ln.datum)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Note
          NoteDropdown(
            inputKey: key,
            eingabe: eingabe,
            studentId: student.id,
            lnId: ln.id,
            onNoteChanged: onNoteChanged,
            getNoteColor: getNoteColor,
          ),
          const SizedBox(width: 8),
          // Tendenz
          TendenzButtons(
            inputKey: key,
            eingabe: eingabe,
            studentId: student.id,
            lnId: ln.id,
            onTendenzChanged: onTendenzChanged,
          ),
        ],
      ),
    );
  }
}
