import 'package:flutter/material.dart';
import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/features/noten/noten_layout_constants.dart';
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
/// 
/// v0.31.0: Minimalistisches Design ohne Rahmen
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
      width: NotenTableDimensions.noteDropdownWidth,
      height: NotenTableDimensions.rowHeightMin - 8,
      child: Stack(
        children: [
          // Minimalistisches Dropdown ohne Rahmen
          Container(
            decoration: BoxDecoration(
              // Nur bei kritischen Noten dezenten Hintergrund
              color: (eingabe.note != null && eingabe.note! >= 5) 
                  ? NotenColors.criticalBackground 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<int?>(
              value: eingabe.note,
              isExpanded: true,
              underline: const SizedBox(),
              padding: const EdgeInsets.symmetric(horizontal: NotenSpacing.xs),
              iconSize: 12,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400], size: 12),
              style: const TextStyle(fontSize: NotenFontSizes.noteValue),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('-', style: TextStyle(color: Colors.grey)),
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
          // Kürzel oben rechts
          if (eingabe.updatedBy != null)
            Positioned(
              right: 1,
              top: 0,
              child: Text(
                eingabe.updatedBy!,
                style: TextStyle(fontSize: NotenFontSizes.kuerzel, color: Colors.grey[400]),
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
/// 
/// v0.31.0: Vertikales Layout für kompaktere Darstellung
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
    // Vertikales Layout für kompaktere Darstellung
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CompactTendenzIcon(
          tendenz: Tendenz.plus,
          label: '+',
          isSelected: eingabe.tendenz == Tendenz.plus,
          onTap: () => onTendenzChanged(inputKey, studentId, lnId, Tendenz.plus),
        ),
        _CompactTendenzIcon(
          tendenz: Tendenz.keine,
          label: '·',
          isSelected: eingabe.tendenz == Tendenz.keine,
          onTap: () => onTendenzChanged(inputKey, studentId, lnId, Tendenz.keine),
        ),
        _CompactTendenzIcon(
          tendenz: Tendenz.minus,
          label: '-',
          isSelected: eingabe.tendenz == Tendenz.minus,
          onTap: () => onTendenzChanged(inputKey, studentId, lnId, Tendenz.minus),
        ),
      ],
    );
  }
}

/// Minimalistischer Tendenz-Icon für vertikales Layout
class _CompactTendenzIcon extends StatelessWidget {
  final Tendenz tendenz;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactTendenzIcon({
    required this.tendenz,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 16,
        height: 10,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? RBSColors.dynamicRed : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 9,
            height: 1.0,
            color: isSelected ? Colors.white : Colors.grey[400],
          ),
        ),
      ),
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
