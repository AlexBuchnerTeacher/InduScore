import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/klasse.dart';
import 'package:induscore/models/beruf.dart';

void main() {
  group('Klasse Model Tests', () {
    // Test Data
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final updateDate = DateTime(2024, 2, 20, 14, 45);

    final testData = {
      'beruf': 'EAT',
      'jahrgangsstufe': 3,
      'zeitgruppe': 2,
      'laufendeNummer': 1,
      'schuljahr': '2024/25',
      'createdAt': Timestamp.fromDate(testDate),
      'updatedAt': Timestamp.fromDate(updateDate),
    };

    test('fromFirestore should correctly parse all fields', () {
      final mockDoc = _MockDocumentSnapshot('klasse1', testData);
      final klasse = Klasse.fromFirestore(mockDoc);

      expect(klasse.id, 'klasse1');
      expect(klasse.beruf.code, 'EAT');
      expect(klasse.jahrgangsstufe, 3);
      expect(klasse.zeitgruppe.nummer, 2);
      expect(klasse.laufendeNummer, 1);
      expect(klasse.schuljahr.toString(), '2024/25');
      expect(klasse.createdAt, testDate);
      expect(klasse.updatedAt, updateDate);
    });

    test('fromFirestore should handle invalid schuljahr gracefully', () {
      final dataWithInvalidSchuljahr = {...testData, 'schuljahr': 'invalid'};
      final mockDoc = _MockDocumentSnapshot('klasse1', dataWithInvalidSchuljahr);
      final klasse = Klasse.fromFirestore(mockDoc);

      // Should default to current Schuljahr
      expect(klasse.schuljahr, Schuljahr.current());
    });

    test('fromFirestore should parse different Beruf codes', () {
      final ieData = {...testData, 'beruf': 'IE'};
      final eatData = {...testData, 'beruf': 'EAT'};
      final ebtData = {...testData, 'beruf': 'EBT'};
      final egsData = {...testData, 'beruf': 'EGS'};

      expect(
        Klasse.fromFirestore(_MockDocumentSnapshot('k1', ieData)).beruf.code,
        'IE',
      );
      expect(
        Klasse.fromFirestore(_MockDocumentSnapshot('k2', eatData)).beruf.code,
        'EAT',
      );
      expect(
        Klasse.fromFirestore(_MockDocumentSnapshot('k3', ebtData)).beruf.code,
        'EBT',
      );
      expect(
        Klasse.fromFirestore(_MockDocumentSnapshot('k4', egsData)).beruf.code,
        'EGS',
      );
    });

    test('fromFirestore should handle all Zeitgruppe values', () {
      final zeitgruppe1Data = {...testData, 'zeitgruppe': 1};
      final zeitgruppe2Data = {...testData, 'zeitgruppe': 2};
      final zeitgruppe3Data = {...testData, 'zeitgruppe': 3};

      expect(
        Klasse.fromFirestore(_MockDocumentSnapshot('k1', zeitgruppe1Data))
            .zeitgruppe.nummer,
        1,
      );
      expect(
        Klasse.fromFirestore(_MockDocumentSnapshot('k2', zeitgruppe2Data))
            .zeitgruppe.nummer,
        2,
      );
      expect(
        Klasse.fromFirestore(_MockDocumentSnapshot('k3', zeitgruppe3Data))
            .zeitgruppe.nummer,
        3,
      );
    });

    test('toFirestore should correctly serialize all fields', () {
      final klasse = Klasse(
        id: 'klasse1',
        beruf: Beruf.fromCode('EAT'),
        jahrgangsstufe: 3,
        zeitgruppe: Zeitgruppe.fromNummer(2),
        laufendeNummer: 1,
        schuljahr: Schuljahr.fromString('2024/25'),
        createdAt: testDate,
        updatedAt: updateDate,
      );

      final firestoreData = klasse.toFirestore();

      expect(firestoreData['beruf'], 'EAT');
      expect(firestoreData['jahrgangsstufe'], 3);
      expect(firestoreData['zeitgruppe'], 2);
      expect(firestoreData['laufendeNummer'], 1);
      expect(firestoreData['schuljahr'], '2024/25');
      expect((firestoreData['createdAt'] as Timestamp).toDate(), testDate);
      expect((firestoreData['updatedAt'] as Timestamp).toDate(), updateDate);
    });

    test('copyWith should update specified fields only', () {
      final original = Klasse(
        id: 'klasse1',
        beruf: Beruf.fromCode('EAT'),
        jahrgangsstufe: 3,
        zeitgruppe: Zeitgruppe.fromNummer(2),
        laufendeNummer: 1,
        schuljahr: Schuljahr.fromString('2024/25'),
        createdAt: testDate,
        updatedAt: testDate,
      );

      final updated = original.copyWith(
        jahrgangsstufe: 4,
        laufendeNummer: 2,
        updatedAt: updateDate,
      );

      // Updated fields
      expect(updated.jahrgangsstufe, 4);
      expect(updated.laufendeNummer, 2);
      expect(updated.updatedAt, updateDate);

      // Unchanged fields
      expect(updated.id, 'klasse1');
      expect(updated.beruf.code, 'EAT');
      expect(updated.zeitgruppe.nummer, 2);
      expect(updated.schuljahr.toString(), '2024/25');
      expect(updated.createdAt, testDate);
    });

    test('name getter should return correct format', () {
      final klasse = Klasse(
        id: 'klasse1',
        beruf: Beruf.fromCode('EAT'),
        jahrgangsstufe: 3,
        zeitgruppe: Zeitgruppe.fromNummer(2),
        laufendeNummer: 1,
        schuljahr: Schuljahr.fromString('2024/25'),
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(klasse.name, 'EAT321');
    });

    test('name getter should handle different combinations', () {
      final klasse1 = Klasse(
        id: 'k1',
        beruf: Beruf.fromCode('IE'),
        jahrgangsstufe: 1,
        zeitgruppe: Zeitgruppe.fromNummer(1),
        laufendeNummer: 1,
        schuljahr: Schuljahr.fromString('2024/25'),
        createdAt: testDate,
        updatedAt: testDate,
      );

      final klasse2 = Klasse(
        id: 'k2',
        beruf: Beruf.fromCode('EBT'),
        jahrgangsstufe: 4,
        zeitgruppe: Zeitgruppe.fromNummer(3),
        laufendeNummer: 2,
        schuljahr: Schuljahr.fromString('2024/25'),
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(klasse1.name, 'IE111');
      expect(klasse2.name, 'EBT432');
    });

    test('fullName getter should include Schuljahr', () {
      final klasse = Klasse(
        id: 'klasse1',
        beruf: Beruf.fromCode('EAT'),
        jahrgangsstufe: 3,
        zeitgruppe: Zeitgruppe.fromNummer(2),
        laufendeNummer: 1,
        schuljahr: Schuljahr.fromString('2024/25'),
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(klasse.fullName, 'EAT321 (2024/25)');
    });

    test('roundtrip fromFirestore/toFirestore should preserve data', () {
      final mockDoc = _MockDocumentSnapshot('klasse1', testData);
      final klasse = Klasse.fromFirestore(mockDoc);
      final firestoreData = klasse.toFirestore();

      // Verify all fields are preserved
      expect(firestoreData['beruf'], testData['beruf']);
      expect(firestoreData['jahrgangsstufe'], testData['jahrgangsstufe']);
      expect(firestoreData['zeitgruppe'], testData['zeitgruppe']);
      expect(firestoreData['laufendeNummer'], testData['laufendeNummer']);
      expect(firestoreData['schuljahr'], testData['schuljahr']);
    });
  });

  group('ParsedKlassenname Tests', () {
    test('parse should correctly parse valid Klassenname', () {
      final parsed = ParsedKlassenname.parse('EAT321');

      expect(parsed.beruf.code, 'EAT');
      expect(parsed.jahrgangsstufe, 3);
      expect(parsed.zeitgruppe.nummer, 2);
      expect(parsed.laufendeNummer, 1);
    });

    test('parse should handle different valid formats', () {
      final parsed1 = ParsedKlassenname.parse('IE111');
      final parsed2 = ParsedKlassenname.parse('EBT332');
      final parsed3 = ParsedKlassenname.parse('EGS222');

      expect(parsed1.beruf.code, 'IE');
      expect(parsed1.jahrgangsstufe, 1);

      expect(parsed2.beruf.code, 'EBT');
      expect(parsed2.jahrgangsstufe, 3);

      expect(parsed3.beruf.code, 'EGS');
      expect(parsed3.zeitgruppe.nummer, 2);
    });

    test('parse should handle lowercase and trim whitespace', () {
      final parsed1 = ParsedKlassenname.parse('  eat321  ');
      final parsed2 = ParsedKlassenname.parse('EbT111');

      expect(parsed1.beruf.code, 'EAT');
      expect(parsed2.beruf.code, 'EBT');
    });

    test('parse should throw FormatException for invalid format', () {
      expect(
        () => ParsedKlassenname.parse('INVALID'),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => ParsedKlassenname.parse('EAT12'), // Too short
        throwsA(isA<FormatException>()),
      );

      expect(
        () => ParsedKlassenname.parse('EAT3211'), // Too long
        throwsA(isA<FormatException>()),
      );

      expect(
        () => ParsedKlassenname.parse('ABC321'), // Invalid Beruf
        throwsA(isA<FormatException>()),
      );
    });

    test('parse should throw FormatException for invalid Jahrgangsstufe', () {
      expect(
        () => ParsedKlassenname.parse('EAT021'), // Stufe 0
        throwsA(isA<FormatException>()),
      );

      expect(
        () => ParsedKlassenname.parse('EAT521'), // Stufe 5 (zu hoch)
        throwsA(isA<FormatException>()),
      );
    });

    test('parse should accept all valid Beruf codes', () {
      final berufe = ['IE', 'EAT', 'EBT', 'EGS'];

      for (final beruf in berufe) {
        final parsed = ParsedKlassenname.parse('${beruf}321');
        expect(parsed.beruf.code, beruf);
      }
    });

    test('parse should accept all valid Zeitgruppen', () {
      // Only Zeitgruppen 1-3 are valid
      for (int i = 1; i <= 3; i++) {
        final parsed = ParsedKlassenname.parse('EAT3${i}1');
        expect(parsed.zeitgruppe.nummer, i);
      }
    });

    test('parse should accept all valid laufende Nummern', () {
      for (int i = 1; i <= 9; i++) {
        final parsed = ParsedKlassenname.parse('EAT32$i');
        expect(parsed.laufendeNummer, i);
      }
    });
  });
}

// Fake DocumentSnapshot for testing
class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;

  final Map<String, dynamic> _data;

  _MockDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
