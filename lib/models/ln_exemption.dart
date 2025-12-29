import 'package:cloud_firestore/cloud_firestore.dart';

/// LN-Befreiung: Markiert einen Schüler als "nicht relevant" für einen LN
/// 
/// Wird verwendet um Schüler von Nachschreiber-Listen auszunehmen,
/// z.B. wenn sie am Tag des LN nicht anwesend waren und nicht nachschreiben müssen.
class LnExemption {
  final String id;
  final String studentId;
  final String leistungsnachweisId;
  final String? grund; // Optional: Grund für die Befreiung
  final DateTime createdAt;
  final String? createdBy; // Kürzel des Erstellers

  LnExemption({
    required this.id,
    required this.studentId,
    required this.leistungsnachweisId,
    required this.createdAt, this.grund,
    this.createdBy,
  });

  factory LnExemption.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LnExemption(
      id: doc.id,
      studentId: data['studentId'] as String,
      leistungsnachweisId: data['leistungsnachweisId'] as String,
      grund: data['grund'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'leistungsnachweisId': leistungsnachweisId,
      'grund': grund,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}
