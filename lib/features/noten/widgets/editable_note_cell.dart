import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/tendenz.dart';
import '../noten_layout_constants.dart';

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

class _EditableNoteCellState extends ConsumerState<EditableNoteCell>
    with SingleTickerProviderStateMixin {
  // v0.33.0: Animation bei Notenänderung
  late AnimationController _animationController;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _highlightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(EditableNoteCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger Animation wenn Note sich ändert
    if (oldWidget.note != widget.note) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        // Highlight-Farbe basierend auf Animation
        final highlightOpacity = (1 - _highlightAnimation.value) * 0.4;
        final highlightColor = widget.note != null && widget.note! <= 3
            ? Colors.green.withValues(alpha: highlightOpacity)
            : widget.note != null && widget.note! >= 5
                ? Colors.red.withValues(alpha: highlightOpacity)
                : Colors.blue.withValues(alpha: highlightOpacity);
        
        return Container(
          decoration: BoxDecoration(
            color: highlightOpacity > 0.01 ? highlightColor : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: child,
        );
      },
      child: Tooltip(
        message: _buildTooltipMessage(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNoteDropdown(),
            // v0.33.0: Tendenz-Buttons aus UI entfernt (F-004)
            // DB-Feld bleibt erhalten, UI wird versteckt
            // if (widget.note != null && !widget.compact) ...[
            //   const SizedBox(width: 4),
            //   _buildTendenzButtons(),
            // ],
          ],
        ),
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
    // v0.30.1: Kompakteres Design ohne Rahmen
    final size = widget.compact ? NotenTableDimensions.noteDropdownWidth : 50.0;
    final iconSize = widget.compact ? 12.0 : 16.0;
    final fontSize = widget.compact ? NotenFontSizes.noteValue : 14.0;
    final kuerzelFontSize = widget.compact ? NotenFontSizes.kuerzel : 8.0;

    return SizedBox(
      width: size,
      height: widget.compact ? NotenTableDimensions.rowHeightMin - 8 : null,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              // v0.30.1: Kein Rahmen mehr, nur bei kritischen Noten Hintergrund
              color: (widget.note != null && widget.note! >= 5)
                  ? NotenColors.criticalBackground
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<int?>(
              value: widget.note,
              isExpanded: true,
              underline: const SizedBox(),
              padding: EdgeInsets.symmetric(horizontal: widget.compact ? NotenSpacing.xs : 6),
              iconSize: iconSize,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400], size: iconSize),
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
              right: 1,
              top: 0,
              child: Text(
                widget.updatedBy!,
                style: TextStyle(
                  fontSize: kuerzelFontSize,
                  color: Colors.grey[400],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // v0.33.0: _buildTendenzButtons und Hilfsmethoden entfernt (F-004)
  // Tendenz-Buttons sind nicht mehr in der UI sichtbar

  /// Gibt die Farbe für eine Note zurück (verwendet zentrale Konstanten)
  Color _getNoteColor(int note) {
    return NotenColors.getColor(note);
  }
}
