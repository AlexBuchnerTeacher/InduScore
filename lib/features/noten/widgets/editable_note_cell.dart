import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/rbs_theme.dart';
import '../../../models/tendenz.dart';

/// Editierbare Noten-Zelle mit Inline-Editing
/// 
/// Features:
/// - Dropdown für Note (1-6 oder -)
/// - Tendenz-Buttons (+, ·, -)
/// - Anzeige von updatedBy (Kürzel)
/// - Tooltip mit Metadata (updatedBy, updatedAt)
/// - Farbcodierung nach Note
/// 
/// Max 150 Zeilen (Widget Guideline)
class EditableNoteCell extends ConsumerStatefulWidget {
  final String studentId;
  final String leistungsnachweisId;
  final int? note;
  final Tendenz tendenz;
  final String? updatedBy;
  final DateTime? updatedAt;
  final Function(int? note) onNoteChanged;
  final Function(Tendenz tendenz) onTendenzChanged;
  final bool compact;

  const EditableNoteCell({
    required this.studentId, required this.leistungsnachweisId, required this.note, required this.tendenz, required this.onNoteChanged, required this.onTendenzChanged, super.key,
    this.updatedBy,
    this.updatedAt,
    this.compact = false,
  });

  @override
  ConsumerState<EditableNoteCell> createState() => _EditableNoteCellState();
}

class _EditableNoteCellState extends ConsumerState<EditableNoteCell> {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _buildTooltipMessage(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNoteDropdown(),
          if (widget.note != null && !widget.compact) ...[
            const SizedBox(width: 4),
            _buildTendenzButtons(),
          ],
        ],
      ),
    );
  }

  String _buildTooltipMessage() {
    if (widget.updatedBy == null && widget.updatedAt == null) {
      return 'Noch keine Note';
    }
    
    final lines = <String>[];
    if (widget.note != null) {
      lines.add('Note: ${widget.note}${widget.tendenz.symbol}');
    }
    if (widget.updatedBy != null) {
      lines.add('Geändert von: ${widget.updatedBy}');
    }
    if (widget.updatedAt != null) {
      lines.add('Am: ${_formatDateTime(widget.updatedAt!)}');
    }
    
    return lines.join('\n');
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildNoteDropdown() {
    final size = widget.compact ? 45.0 : 60.0;
    final iconSize = widget.compact ? 16.0 : 20.0;
    final fontSize = widget.compact ? 14.0 : 16.0;
    final kuerzelFontSize = widget.compact ? 7.0 : 8.0;

    return SizedBox(
      width: size,
      height: widget.compact ? 32 : null,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.compact ? Colors.grey[300]! : Colors.grey[400]!,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<int?>(
              value: widget.note,
              isExpanded: true,
              underline: const SizedBox(),
              padding: EdgeInsets.symmetric(horizontal: widget.compact ? 4 : 6),
              iconSize: iconSize,
              style: TextStyle(fontSize: fontSize),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: fontSize,
                    ),
                  ),
                ),
                ...List.generate(6, (i) => i + 1).map(
                  (note) => DropdownMenuItem<int>(
                    value: note,
                    child: Text(
                      '$note',
                      style: TextStyle(
                        color: _getNoteColor(note),
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: widget.onNoteChanged,
            ),
          ),
          if (widget.updatedBy != null)
            Positioned(
              right: widget.compact ? 1 : 2,
              top: widget.compact ? 0 : 1,
              child: Text(
                widget.updatedBy!,
                style: TextStyle(
                  fontSize: kuerzelFontSize,
                  color: widget.compact ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTendenzButtons() {
    final buttonSize = widget.compact ? 18.0 : 28.0;
    final spacing = widget.compact ? 1.0 : 2.0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTendenzButton(Tendenz.plus, '+', buttonSize),
        SizedBox(width: spacing),
        _buildTendenzButton(Tendenz.keine, '·', buttonSize),
        SizedBox(width: spacing),
        _buildTendenzButton(Tendenz.minus, '-', buttonSize),
      ],
    );
  }

  Widget _buildTendenzButton(Tendenz tendenz, String label, double size) {
    final isSelected = widget.tendenz == tendenz;
    return InkWell(
      onTap: () => widget.onTendenzChanged(tendenz),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? RBSColors.dynamicRed : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Color _getNoteColor(int note) {
    switch (note) {
      case 1:
        return Colors.green[700]!;
      case 2:
        return Colors.green[600]!;
      case 3:
        return Colors.orange[700]!;
      case 4:
        return Colors.orange[800]!;
      case 5:
        return Colors.red[700]!;
      case 6:
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }
}
