import 'package:flutter/material.dart';
import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/models/noten_eingabe.dart';
import 'package:induscore/models/tendenz.dart';

/// Callback-Typen für Note-Änderungen
typedef OnNoteChanged = void Function(String key, String studentId, String lnId, int? value);
typedef OnTendenzChanged = void Function(String key, String studentId, String lnId, Tendenz tendenz);

/// Widget für Note-Dropdown (normal)
class NoteDropdown extends StatelessWidget {
  final String inputKey;
  final NotenEingabe eingabe;
  final String studentId;
  final String lnId;
  final OnNoteChanged onNoteChanged;
  final Color Function(int) getNoteColor;

  const NoteDropdown({
    required this.inputKey, required this.eingabe, required this.studentId, required this.lnId, required this.onNoteChanged, required this.getNoteColor, super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<int?>(
              value: eingabe.note,
              isExpanded: true,
              underline: const SizedBox(),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('-')),
                ...List.generate(6, (i) => i + 1).map(
                  (note) => DropdownMenuItem<int>(
                    value: note,
                    child: Text(
                      '$note',
                      style: TextStyle(
                        color: getNoteColor(note),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: (value) => onNoteChanged(inputKey, studentId, lnId, value),
            ),
          ),
          if (eingabe.updatedBy != null)
            Positioned(
              right: 2,
              top: 1,
              child: Text(
                eingabe.updatedBy!,
                style: TextStyle(fontSize: 8, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget für Note-Dropdown (kompakt für Tabellen)
class CompactNoteDropdown extends StatelessWidget {
  final String inputKey;
  final NotenEingabe eingabe;
  final String studentId;
  final String lnId;
  final OnNoteChanged onNoteChanged;
  final Color Function(int) getNoteColor;

  const CompactNoteDropdown({
    required this.inputKey, required this.eingabe, required this.studentId, required this.lnId, required this.onNoteChanged, required this.getNoteColor, super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 45,
      height: 32,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<int?>(
              value: eingabe.note,
              isExpanded: true,
              underline: const SizedBox(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              iconSize: 16,
              style: const TextStyle(fontSize: 14),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('-', style: TextStyle(color: Colors.black)),
                ),
                ...List.generate(6, (i) => i + 1).map(
                  (note) => DropdownMenuItem<int>(
                    value: note,
                    child: Text(
                      '$note',
                      style: TextStyle(
                        color: getNoteColor(note),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: (value) => onNoteChanged(inputKey, studentId, lnId, value),
            ),
          ),
          if (eingabe.updatedBy != null)
            Positioned(
              right: 1,
              top: 0,
              child: Text(
                eingabe.updatedBy!,
                style: TextStyle(fontSize: 7, color: Colors.grey[400]),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget für Tendenz-Buttons (normal)
class TendenzButtons extends StatelessWidget {
  final String inputKey;
  final NotenEingabe eingabe;
  final String studentId;
  final String lnId;
  final OnTendenzChanged onTendenzChanged;

  const TendenzButtons({
    required this.inputKey, required this.eingabe, required this.studentId, required this.lnId, required this.onTendenzChanged, super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TendenzButton(
          inputKey: inputKey,
          eingabe: eingabe,
          studentId: studentId,
          lnId: lnId,
          tendenz: Tendenz.plus,
          label: '+',
          onTendenzChanged: onTendenzChanged,
          compact: false,
        ),
        const SizedBox(width: 2),
        _TendenzButton(
          inputKey: inputKey,
          eingabe: eingabe,
          studentId: studentId,
          lnId: lnId,
          tendenz: Tendenz.keine,
          label: '·',
          onTendenzChanged: onTendenzChanged,
          compact: false,
        ),
        const SizedBox(width: 2),
        _TendenzButton(
          inputKey: inputKey,
          eingabe: eingabe,
          studentId: studentId,
          lnId: lnId,
          tendenz: Tendenz.minus,
          label: '-',
          onTendenzChanged: onTendenzChanged,
          compact: false,
        ),
      ],
    );
  }
}

/// Widget für Tendenz-Buttons (kompakt für Tabellen)
class CompactTendenzButtons extends StatelessWidget {
  final String inputKey;
  final NotenEingabe eingabe;
  final String studentId;
  final String lnId;
  final OnTendenzChanged onTendenzChanged;

  const CompactTendenzButtons({
    required this.inputKey, required this.eingabe, required this.studentId, required this.lnId, required this.onTendenzChanged, super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TendenzButton(
          inputKey: inputKey,
          eingabe: eingabe,
          studentId: studentId,
          lnId: lnId,
          tendenz: Tendenz.plus,
          label: '+',
          onTendenzChanged: onTendenzChanged,
          compact: true,
        ),
        _TendenzButton(
          inputKey: inputKey,
          eingabe: eingabe,
          studentId: studentId,
          lnId: lnId,
          tendenz: Tendenz.keine,
          label: '·',
          onTendenzChanged: onTendenzChanged,
          compact: true,
        ),
        _TendenzButton(
          inputKey: inputKey,
          eingabe: eingabe,
          studentId: studentId,
          lnId: lnId,
          tendenz: Tendenz.minus,
          label: '-',
          onTendenzChanged: onTendenzChanged,
          compact: true,
        ),
      ],
    );
  }
}

/// Interner Tendenz-Button
class _TendenzButton extends StatelessWidget {
  final String inputKey;
  final NotenEingabe eingabe;
  final String studentId;
  final String lnId;
  final Tendenz tendenz;
  final String label;
  final OnTendenzChanged onTendenzChanged;
  final bool compact;

  const _TendenzButton({
    required this.inputKey,
    required this.eingabe,
    required this.studentId,
    required this.lnId,
    required this.tendenz,
    required this.label,
    required this.onTendenzChanged,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = eingabe.tendenz == tendenz;
    final size = compact ? 20.0 : 28.0;
    final fontSize = compact ? 12.0 : 16.0;
    final radius = compact ? 2.0 : 4.0;

    return InkWell(
      onTap: () => onTendenzChanged(inputKey, studentId, lnId, tendenz),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? RBSColors.dynamicRed : Colors.grey[200],
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
