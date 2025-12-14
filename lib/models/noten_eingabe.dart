import 'package:induscore/models/tendenz.dart';

/// Eingabe-Daten für eine Note (temporär während Bearbeitung)
class NotenEingabe {
  final int? note;
  final Tendenz tendenz;
  final String? kommentar;
  final String? existingGradeId;
  final String? updatedBy;

  NotenEingabe({
    this.note,
    this.tendenz = Tendenz.keine,
    this.kommentar,
    this.existingGradeId,
    this.updatedBy,
  });

  NotenEingabe copyWith({
    int? note,
    Tendenz? tendenz,
    String? kommentar,
    String? existingGradeId,
    String? updatedBy,
  }) {
    return NotenEingabe(
      note: note ?? this.note,
      tendenz: tendenz ?? this.tendenz,
      kommentar: kommentar ?? this.kommentar,
      existingGradeId: existingGradeId ?? this.existingGradeId,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
