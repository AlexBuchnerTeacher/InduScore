import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/leistungsnachweis.dart';

void main() {
  group('Leistungsnachweis Model Tests', () {
    // Test Data
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final lnDate = DateTime(2024, 2, 20);
    final updateDate = DateTime(2024, 2, 21, 14, 45);

    final testData = {
      'subjectId': 'subject1',
      'klasseId': 'klasse1',
      'typ': 'wochentest',
      'bezeichnung': '1. Schulaufgabe',
      'datum': Timestamp.fromDate(lnDate),
      'gewichtung': 2.0,
      'beschreibung': 'Kapitel 1-3',
      'createdBy': 'user123',
      'createdAt': Timestamp.fromDate(testDate),
      'updatedAt': Timestamp.fromDate(updateDate),
    };

    test('fromFirestore should correctly parse all fields', () {
      final mockDoc = _FakeDocumentSnapshot('ln1', testData);
      final ln = Leistungsnachweis.fromFirestore(mockDoc);

      expect(ln.id, 'ln1');
      expect(ln.subjectId, 'subject1');
      expect(ln.klasseId, 'klasse1');
      expect(ln.typ, LeistungsnachweisTyp.wochentest);
      expect(ln.bezeichnung, '1. Schulaufgabe');
      expect(ln.datum, lnDate);
      expect(ln.gewichtung, 2.0);
      expect(ln.beschreibung, 'Kapitel 1-3');
      expect(ln.createdBy, 'user123');
      expect(ln.createdAt, testDate);
      expect(ln.updatedAt, updateDate);
    });

    test('fromFirestore should handle missing optional fields', () {
      final minimalData = {
        'subjectId': 'subject1',
        'klasseId': 'klasse1',
        'typ': 'wochentest',
        'bezeichnung': '1. Wochentest',
        'datum': Timestamp.fromDate(lnDate),
        'createdAt': Timestamp.fromDate(testDate),
        'updatedAt': Timestamp.fromDate(testDate),
      };
      final mockDoc = _FakeDocumentSnapshot('ln2', minimalData);
      final ln = Leistungsnachweis.fromFirestore(mockDoc);

      expect(ln.subjectId, 'subject1');
      expect(ln.klasseId, 'klasse1');
      expect(ln.typ, LeistungsnachweisTyp.wochentest);
      expect(ln.bezeichnung, '1. Wochentest');
      expect(ln.datum, lnDate);
      expect(ln.gewichtung, 1.0); // Default
      expect(ln.beschreibung, null);
      expect(ln.createdBy, null);
    });

    test('fromFirestore should handle all LeistungsnachweisTyp values', () {
      final wochentestData = {...testData, 'typ': 'wochentest'};
      final praktischData = {...testData, 'typ': 'praktisch'};
      final muendlichData = {...testData, 'typ': 'muendlich'};
      final mitarbeitData = {...testData, 'typ': 'mitarbeit'};

      expect(
        Leistungsnachweis.fromFirestore(_FakeDocumentSnapshot('ln1', wochentestData)).typ,
        LeistungsnachweisTyp.wochentest,
      );
      expect(
        Leistungsnachweis.fromFirestore(_FakeDocumentSnapshot('ln2', praktischData)).typ,
        LeistungsnachweisTyp.praktisch,
      );
      expect(
        Leistungsnachweis.fromFirestore(_FakeDocumentSnapshot('ln3', muendlichData)).typ,
        LeistungsnachweisTyp.muendlich,
      );
      expect(
        Leistungsnachweis.fromFirestore(_FakeDocumentSnapshot('ln4', mitarbeitData)).typ,
        LeistungsnachweisTyp.mitarbeit,
      );
    });

    test('fromFirestore should handle gewichtung as int or double', () {
      final intGewichtungData = {...testData, 'gewichtung': 2};
      final doubleGewichtungData = {...testData, 'gewichtung': 1.5};

      final lnInt = Leistungsnachweis.fromFirestore(
        _FakeDocumentSnapshot('ln1', intGewichtungData),
      );
      final lnDouble = Leistungsnachweis.fromFirestore(
        _FakeDocumentSnapshot('ln2', doubleGewichtungData),
      );

      expect(lnInt.gewichtung, 2.0);
      expect(lnDouble.gewichtung, 1.5);
    });

    test('toFirestore should correctly serialize all fields', () {
      final ln = Leistungsnachweis(
        id: 'ln1',
        subjectId: 'subject1',
        klasseId: 'klasse1',
        typ: LeistungsnachweisTyp.wochentest,
        bezeichnung: '1. Schulaufgabe',
        datum: lnDate,
        gewichtung: 2.0,
        beschreibung: 'Kapitel 1-3',
        createdBy: 'user123',
        createdAt: testDate,
        updatedAt: updateDate,
      );

      final firestoreData = ln.toFirestore();

      expect(firestoreData['subjectId'], 'subject1');
      expect(firestoreData['klasseId'], 'klasse1');
      expect(firestoreData['typ'], 'wochentest');
      expect(firestoreData['bezeichnung'], '1. Schulaufgabe');
      expect((firestoreData['datum'] as Timestamp).toDate(), lnDate);
      expect(firestoreData['gewichtung'], 2.0);
      expect(firestoreData['beschreibung'], 'Kapitel 1-3');
      expect(firestoreData['createdBy'], 'user123');
      expect((firestoreData['createdAt'] as Timestamp).toDate(), testDate);
      expect((firestoreData['updatedAt'] as Timestamp).toDate(), updateDate);
    });

    test('toFirestore should handle null optional fields', () {
      final ln = Leistungsnachweis(
        id: 'ln1',
        subjectId: 'subject1',
        klasseId: 'klasse1',
        typ: LeistungsnachweisTyp.wochentest,
        bezeichnung: '1. Wochentest',
        datum: lnDate,
        gewichtung: 1.0,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final firestoreData = ln.toFirestore();

      expect(firestoreData['beschreibung'], null);
      expect(firestoreData['createdBy'], null);
    });

    test('copyWith should update specified fields only', () {
      final original = Leistungsnachweis(
        id: 'ln1',
        subjectId: 'subject1',
        klasseId: 'klasse1',
        typ: LeistungsnachweisTyp.wochentest,
        bezeichnung: '1. Schulaufgabe',
        datum: lnDate,
        gewichtung: 2.0,
        beschreibung: 'Kapitel 1-3',
        createdBy: 'user123',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final updated = original.copyWith(
        bezeichnung: '2. Schulaufgabe',
        gewichtung: 1.5,
        updatedAt: updateDate,
      );

      // Updated fields
      expect(updated.bezeichnung, '2. Schulaufgabe');
      expect(updated.gewichtung, 1.5);
      expect(updated.updatedAt, updateDate);

      // Unchanged fields
      expect(updated.id, 'ln1');
      expect(updated.subjectId, 'subject1');
      expect(updated.klasseId, 'klasse1');
      expect(updated.typ, LeistungsnachweisTyp.wochentest);
      expect(updated.datum, lnDate);
      expect(updated.beschreibung, 'Kapitel 1-3');
      expect(updated.createdBy, 'user123');
      expect(updated.createdAt, testDate);
    });

    test('copyWith should handle clearing optional fields', () {
      final original = Leistungsnachweis(
        id: 'ln1',
        subjectId: 'subject1',
        klasseId: 'klasse1',
        typ: LeistungsnachweisTyp.wochentest,
        bezeichnung: '1. Schulaufgabe',
        datum: lnDate,
        gewichtung: 2.0,
        beschreibung: 'Kapitel 1-3',
        createdBy: 'user123',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Note: copyWith doesn't support clearing optional fields to null
      // This test verifies fields remain unchanged when not specified
      final updated = original.copyWith(
        bezeichnung: 'Updated',
      );

      expect(updated.bezeichnung, 'Updated');
      expect(updated.beschreibung, 'Kapitel 1-3'); // Unchanged
      expect(updated.createdBy, 'user123'); // Unchanged
    });

    test('LeistungsnachweisTyp should have correct labels', () {
      expect(LeistungsnachweisTyp.wochentest.label, 'Wochentest');
      expect(LeistungsnachweisTyp.praktisch.label, 'Praktisch');
      expect(LeistungsnachweisTyp.muendlich.label, 'Mündlich');
      expect(LeistungsnachweisTyp.mitarbeit.label, 'Mitarbeit');
    });

    test('LeistungsnachweisTyp.fromString should handle valid values', () {
      expect(
        LeistungsnachweisTyp.fromString('wochentest'),
        LeistungsnachweisTyp.wochentest,
      );
      expect(
        LeistungsnachweisTyp.fromString('praktisch'),
        LeistungsnachweisTyp.praktisch,
      );
      expect(
        LeistungsnachweisTyp.fromString('muendlich'),
        LeistungsnachweisTyp.muendlich,
      );
      expect(
        LeistungsnachweisTyp.fromString('mitarbeit'),
        LeistungsnachweisTyp.mitarbeit,
      );
    });

    test('LeistungsnachweisTyp.fromString should handle labels', () {
      expect(
        LeistungsnachweisTyp.fromString('Wochentest'),
        LeistungsnachweisTyp.wochentest,
      );
      expect(
        LeistungsnachweisTyp.fromString('Praktisch'),
        LeistungsnachweisTyp.praktisch,
      );
      expect(
        LeistungsnachweisTyp.fromString('Mündlich'),
        LeistungsnachweisTyp.muendlich,
      );
      expect(
        LeistungsnachweisTyp.fromString('Mitarbeit'),
        LeistungsnachweisTyp.mitarbeit,
      );
    });

    test('LeistungsnachweisTyp.fromString should default to wochentest for invalid values', () {
      expect(
        LeistungsnachweisTyp.fromString('invalid'),
        LeistungsnachweisTyp.wochentest,
      );
    });

    test('roundtrip fromFirestore/toFirestore should preserve data', () {
      final mockDoc = _FakeDocumentSnapshot('ln1', testData);
      final ln = Leistungsnachweis.fromFirestore(mockDoc);
      final firestoreData = ln.toFirestore();

      // Verify all fields are preserved
      expect(firestoreData['subjectId'], testData['subjectId']);
      expect(firestoreData['klasseId'], testData['klasseId']);
      expect(firestoreData['typ'], testData['typ']);
      expect(firestoreData['bezeichnung'], testData['bezeichnung']);
      expect(firestoreData['gewichtung'], testData['gewichtung']);
      expect(firestoreData['beschreibung'], testData['beschreibung']);
      expect(firestoreData['createdBy'], testData['createdBy']);
    });
  });

  group('IHKNotenschluessel Tests', () {
    test('prozentZuNote should return correct grades', () {
      expect(IHKNotenschluessel.prozentZuNote(100), 1);
      expect(IHKNotenschluessel.prozentZuNote(92), 1);
      expect(IHKNotenschluessel.prozentZuNote(91), 2);
      expect(IHKNotenschluessel.prozentZuNote(81), 2);
      expect(IHKNotenschluessel.prozentZuNote(80), 3);
      expect(IHKNotenschluessel.prozentZuNote(67), 3);
      expect(IHKNotenschluessel.prozentZuNote(66), 4);
      expect(IHKNotenschluessel.prozentZuNote(50), 4);
      expect(IHKNotenschluessel.prozentZuNote(49), 5);
      expect(IHKNotenschluessel.prozentZuNote(30), 5);
      expect(IHKNotenschluessel.prozentZuNote(29), 6);
      expect(IHKNotenschluessel.prozentZuNote(0), 6);
    });

    test('punkteZuNote should calculate correct grades', () {
      expect(IHKNotenschluessel.punkteZuNote(50, 50), 1); // 100%
      expect(IHKNotenschluessel.punkteZuNote(46, 50), 1); // 92%
      expect(IHKNotenschluessel.punkteZuNote(45, 50), 2); // 90%
      expect(IHKNotenschluessel.punkteZuNote(40, 50), 3); // 80%
      expect(IHKNotenschluessel.punkteZuNote(33, 50), 4); // 66%
      expect(IHKNotenschluessel.punkteZuNote(25, 50), 4); // 50%
      expect(IHKNotenschluessel.punkteZuNote(20, 50), 5); // 40%
      expect(IHKNotenschluessel.punkteZuNote(15, 50), 5); // 30%
      expect(IHKNotenschluessel.punkteZuNote(10, 50), 6); // 20%
      expect(IHKNotenschluessel.punkteZuNote(0, 50), 6); // 0%
    });

    test('punkteZuNote should handle edge case with maxPunkte 0', () {
      expect(IHKNotenschluessel.punkteZuNote(10, 0), 6);
    });

    test('punkteZuNote should handle negative maxPunkte', () {
      expect(IHKNotenschluessel.punkteZuNote(10, -5), 6);
    });

    test('punkteZuNote should handle decimal points', () {
      expect(IHKNotenschluessel.punkteZuNote(46.5, 50), 1); // 93%
      expect(IHKNotenschluessel.punkteZuNote(40.5, 50), 2); // 81%
      expect(IHKNotenschluessel.punkteZuNote(35.5, 50), 3); // 71%
    });

    test('notengrenzen should return correct percentages', () {
      final grenzen = IHKNotenschluessel.notengrenzen;

      expect(grenzen[1], '92-100%');
      expect(grenzen[2], '81-91%');
      expect(grenzen[3], '67-80%');
      expect(grenzen[4], '50-66%');
      expect(grenzen[5], '30-49%');
      expect(grenzen[6], '0-29%');
    });
  });
}

// Fake DocumentSnapshot for testing
// ignore: subtype_of_sealed_class
class _FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;

  final Map<String, dynamic> _data;

  _FakeDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic>? data() => _data;
}
