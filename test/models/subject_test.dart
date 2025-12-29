import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/subject.dart';
import 'package:induscore/models/beruf.dart';

void main() {
  group('Subject Model Tests', () {
    // Test Data
    final testDate = DateTime(2024, 1, 15, 10, 30);

    final testData = {
      'name': 'Programmieren',
      'shortName': 'PROG',
      'typ': 'BF',
      'berufe': ['EAT', 'EBT'],
      'wochenstunden': 4,
      'credits': 5.0,
      'color': '#FF5733',
      'createdAt': Timestamp.fromDate(testDate),
    };

    test('fromFirestore should correctly parse all fields', () {
      final mockDoc = _FakeDocumentSnapshot('subject1', testData);
      final subject = Subject.fromFirestore(mockDoc);

      expect(subject.id, 'subject1');
      expect(subject.name, 'Programmieren');
      expect(subject.shortName, 'PROG');
      expect(subject.typ, FachTyp.beruflich);
      expect(subject.berufe.length, 2);
      expect(subject.berufe[0].code, 'EAT');
      expect(subject.berufe[1].code, 'EBT');
      expect(subject.wochenstunden, 4);
      expect(subject.credits, 5.0);
      expect(subject.color, '#FF5733');
      expect(subject.createdAt, testDate);
    });

    test('fromFirestore should handle missing optional fields', () {
      final minimalData = {
        'name': 'Deutsch',
        'typ': 'ABF',
        'createdAt': Timestamp.fromDate(testDate),
      };
      final mockDoc = _FakeDocumentSnapshot('subject2', minimalData);
      final subject = Subject.fromFirestore(mockDoc);

      expect(subject.name, 'Deutsch');
      expect(subject.shortName, null);
      expect(subject.typ, FachTyp.allgemein);
      expect(subject.berufe, isEmpty);
      expect(subject.wochenstunden, 2); // Default
      expect(subject.credits, 3.0); // Default
      expect(subject.color, null);
    });

    test('fromFirestore should handle all FachTyp values', () {
      final allgemeinData = {...testData, 'typ': 'ABF', 'berufe': []};
      final beruflichData = {...testData, 'typ': 'BF'};
      final lernfeldData = {...testData, 'typ': 'LF', 'berufe': []};

      expect(
        Subject.fromFirestore(_FakeDocumentSnapshot('s1', allgemeinData)).typ,
        FachTyp.allgemein,
      );
      expect(
        Subject.fromFirestore(_FakeDocumentSnapshot('s2', beruflichData)).typ,
        FachTyp.beruflich,
      );
      expect(
        Subject.fromFirestore(_FakeDocumentSnapshot('s3', lernfeldData)).typ,
        FachTyp.lernfeld,
      );
    });

    test('fromFirestore should default to beruflich for invalid typ', () {
      final invalidData = {...testData, 'typ': 'INVALID', 'berufe': []};
      final mockDoc = _FakeDocumentSnapshot('subject3', invalidData);
      final subject = Subject.fromFirestore(mockDoc);

      expect(subject.typ, FachTyp.beruflich);
    });

    test('fromFirestore should handle credits as int or double', () {
      final intCreditsData = {...testData, 'credits': 5, 'berufe': []};
      final doubleCreditsData = {...testData, 'credits': 5.5, 'berufe': []};

      final subjectInt = Subject.fromFirestore(
        _FakeDocumentSnapshot('s1', intCreditsData),
      );
      final subjectDouble = Subject.fromFirestore(
        _FakeDocumentSnapshot('s2', doubleCreditsData),
      );

      expect(subjectInt.credits, 5.0);
      expect(subjectDouble.credits, 5.5);
    });

    test('toFirestore should correctly serialize all fields', () {
      final subject = Subject(
        id: 'subject1',
        name: 'Programmieren',
        shortName: 'PROG',
        typ: FachTyp.beruflich,
        berufe: [Beruf.fromCode('EAT'), Beruf.fromCode('EBT')],
        wochenstunden: 4,
        credits: 5.0,
        color: '#FF5733',
        createdAt: testDate,
      );

      final firestoreData = subject.toFirestore();

      expect(firestoreData['name'], 'Programmieren');
      expect(firestoreData['shortName'], 'PROG');
      expect(firestoreData['typ'], 'BF');
      expect(firestoreData['berufe'], ['EAT', 'EBT']);
      expect(firestoreData['wochenstunden'], 4);
      expect(firestoreData['credits'], 5.0);
      expect(firestoreData['color'], '#FF5733');
      expect((firestoreData['createdAt'] as Timestamp).toDate(), testDate);
    });

    test('toFirestore should handle null optional fields', () {
      final subject = Subject(
        id: 'subject1',
        name: 'Deutsch',
        typ: FachTyp.allgemein,
        berufe: [],
        createdAt: testDate,
      );

      final firestoreData = subject.toFirestore();

      expect(firestoreData['name'], 'Deutsch');
      expect(firestoreData['shortName'], null);
      expect(firestoreData['typ'], 'ABF');
      expect(firestoreData['berufe'], isEmpty);
      expect(firestoreData['wochenstunden'], 2); // Default
      expect(firestoreData['credits'], 3.0); // Default
      expect(firestoreData['color'], null);
    });

    test('copyWith should update specified fields only', () {
      final original = Subject(
        id: 'subject1',
        name: 'Programmieren',
        shortName: 'PROG',
        typ: FachTyp.beruflich,
        berufe: [Beruf.fromCode('EAT')],
        wochenstunden: 4,
        credits: 5.0,
        color: '#FF5733',
        createdAt: testDate,
      );

      final updated = original.copyWith(
        name: 'Softwareentwicklung',
        shortName: 'SWE',
        wochenstunden: 6,
        credits: 7.0,
      );

      // Updated fields
      expect(updated.name, 'Softwareentwicklung');
      expect(updated.shortName, 'SWE');
      expect(updated.wochenstunden, 6);
      expect(updated.credits, 7.0);

      // Unchanged fields
      expect(updated.id, 'subject1');
      expect(updated.typ, FachTyp.beruflich);
      expect(updated.berufe.length, 1);
      expect(updated.berufe[0].code, 'EAT');
      expect(updated.color, '#FF5733');
      expect(updated.createdAt, testDate);
    });

    test('copyWith should handle clearing optional fields', () {
      final original = Subject(
        id: 'subject1',
        name: 'Programmieren',
        shortName: 'PROG',
        typ: FachTyp.beruflich,
        berufe: [Beruf.fromCode('EAT')],
        color: '#FF5733',
        createdAt: testDate,
      );

      // Note: copyWith doesn't support clearing non-nullable fields to null
      // This test verifies fields remain unchanged when not specified
      final updated = original.copyWith(
        name: 'Updated Name',
      );

      expect(updated.name, 'Updated Name');
      expect(updated.shortName, 'PROG'); // Unchanged
      expect(updated.color, '#FF5733'); // Unchanged
    });

    test('FachTyp should have correct properties', () {
      expect(FachTyp.allgemein.name, 'Allgemeinbildend');
      expect(FachTyp.allgemein.code, 'ABF');

      expect(FachTyp.beruflich.name, 'Beruflich');
      expect(FachTyp.beruflich.code, 'BF');

      expect(FachTyp.lernfeld.name, 'Lernfeld');
      expect(FachTyp.lernfeld.code, 'LF');
    });

    test('roundtrip fromFirestore/toFirestore should preserve data', () {
      final mockDoc = _FakeDocumentSnapshot('subject1', testData);
      final subject = Subject.fromFirestore(mockDoc);
      final firestoreData = subject.toFirestore();

      // Verify all fields are preserved
      expect(firestoreData['name'], testData['name']);
      expect(firestoreData['shortName'], testData['shortName']);
      expect(firestoreData['typ'], testData['typ']);
      expect(firestoreData['berufe'], testData['berufe']);
      expect(firestoreData['wochenstunden'], testData['wochenstunden']);
      expect(firestoreData['credits'], testData['credits']);
      expect(firestoreData['color'], testData['color']);
    });

    test('fromFirestore should handle empty berufe list', () {
      final dataWithEmptyBerufe = {...testData, 'berufe': []};
      final mockDoc = _FakeDocumentSnapshot('subject1', dataWithEmptyBerufe);
      final subject = Subject.fromFirestore(mockDoc);

      expect(subject.berufe, isEmpty);
    });

    test('fromFirestore should handle berufe list with multiple entries', () {
      final dataWithManyBerufe = {
        ...testData,
        'berufe': ['IE', 'EAT', 'EBT', 'EGS'],
      };
      final mockDoc = _FakeDocumentSnapshot('subject1', dataWithManyBerufe);
      final subject = Subject.fromFirestore(mockDoc);

      expect(subject.berufe.length, 4);
      expect(subject.berufe.map((b) => b.code).toList(), 
        ['IE', 'EAT', 'EBT', 'EGS']);
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
