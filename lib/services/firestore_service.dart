import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../models/klasse.dart';
import '../models/leistungsnachweis.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _students => _db.collection('students');
  CollectionReference get _subjects => _db.collection('subjects');
  CollectionReference get _grades => _db.collection('grades');
  CollectionReference get _klassen => _db.collection('klassen');
  CollectionReference get _leistungsnachweise =>
      _db.collection('leistungsnachweise');

  // ============ STUDENTS ============

  Stream<List<Student>> getStudents() {
    return _students
        .orderBy('lastName')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList(),
        );
  }

  Future<Student> getStudent(String id) async {
    final doc = await _students.doc(id).get();
    if (!doc.exists) throw Exception('Student nicht gefunden');
    return Student.fromFirestore(doc);
  }

  Future<String> createStudent(Student student) async {
    final docRef = await _students.add(student.toFirestore());
    return docRef.id;
  }

  Future<void> updateStudent(Student student) async {
    await _students.doc(student.id).update(student.toFirestore());
  }

  Future<void> deleteStudent(String id) async {
    // Also delete all grades for this student
    final gradesSnapshot = await _grades
        .where('studentId', isEqualTo: id)
        .get();
    final batch = _db.batch();
    for (final doc in gradesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_students.doc(id));
    await batch.commit();
  }

  /// Schüler nach Klasse abrufen
  Stream<List<Student>> getStudentsByKlasse(String klasseId) {
    return _students
        .where('klasseId', isEqualTo: klasseId)
        .orderBy('pseudonym')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList(),
        );
  }

  /// Nächstes verfügbares Pseudonym für eine Klasse
  Future<String> getNextPseudonym(String klasseId) async {
    final snapshot = await _students
        .where('klasseId', isEqualTo: klasseId)
        .get();
    return Student.generatePseudonym(snapshot.docs.length);
  }

  // ============ SUBJECTS ============

  Stream<List<Subject>> getSubjects() {
    return _subjects
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList(),
        );
  }

  Future<Subject> getSubject(String id) async {
    final doc = await _subjects.doc(id).get();
    if (!doc.exists) throw Exception('Fach nicht gefunden');
    return Subject.fromFirestore(doc);
  }

  Future<String> createSubject(Subject subject) async {
    final docRef = await _subjects.add(subject.toFirestore());
    return docRef.id;
  }

  Future<void> updateSubject(Subject subject) async {
    await _subjects.doc(subject.id).update(subject.toFirestore());
  }

  Future<void> deleteSubject(String id) async {
    // Also delete all grades for this subject
    final gradesSnapshot = await _grades
        .where('subjectId', isEqualTo: id)
        .get();
    final batch = _db.batch();
    for (final doc in gradesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_subjects.doc(id));
    await batch.commit();
  }

  // ============ GRADES ============

  Stream<List<Grade>> getGrades() {
    return _grades
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Grade.fromFirestore(doc)).toList(),
        );
  }

  /// Noten für einen Leistungsnachweis abrufen
  Stream<List<Grade>> getGradesByLeistungsnachweis(String leistungsnachweisId) {
    return _grades
        .where('leistungsnachweisId', isEqualTo: leistungsnachweisId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Grade.fromFirestore(doc)).toList(),
        );
  }

  /// Alle Noten eines Schülers abrufen
  Stream<List<Grade>> getGradesByStudent(String studentId) {
    return _grades
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Grade.fromFirestore(doc)).toList(),
        );
  }

  Future<Grade> getGrade(String id) async {
    final doc = await _grades.doc(id).get();
    if (!doc.exists) throw Exception('Note nicht gefunden');
    return Grade.fromFirestore(doc);
  }

  Future<String> createGrade(Grade grade) async {
    final docRef = await _grades.add(grade.toFirestore());
    return docRef.id;
  }

  /// Mehrere Noten auf einmal speichern (Batch-Operation)
  Future<void> saveGrades(List<Grade> grades) async {
    if (grades.isEmpty) return;
    
    final batch = _db.batch();
    for (final grade in grades) {
      if (grade.id.isEmpty) {
        // Neue Note
        final docRef = _grades.doc();
        batch.set(docRef, grade.copyWith(id: docRef.id).toFirestore());
      } else {
        // Bestehende Note aktualisieren
        batch.update(_grades.doc(grade.id), grade.toFirestore());
      }
    }
    await batch.commit();
  }

  Future<void> updateGrade(Grade grade) async {
    await _grades.doc(grade.id).update(grade.toFirestore());
  }

  Future<void> deleteGrade(String id) async {
    await _grades.doc(id).delete();
  }

  /// Alle Noten eines Leistungsnachweises löschen
  Future<void> deleteGradesByLeistungsnachweis(String leistungsnachweisId) async {
    final snapshot = await _grades
        .where('leistungsnachweisId', isEqualTo: leistungsnachweisId)
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ============ KLASSEN ============

  Stream<List<Klasse>> getKlassen() {
    return _klassen
        .orderBy('schuljahr', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Klasse.fromFirestore(doc)).toList(),
        );
  }

  Future<Klasse> getKlasse(String id) async {
    final doc = await _klassen.doc(id).get();
    if (!doc.exists) throw Exception('Klasse nicht gefunden');
    return Klasse.fromFirestore(doc);
  }

  Stream<List<Klasse>> getKlassenBySchuljahrAndBeruf(
    String schuljahr,
    String berufCode,
  ) {
    return _klassen
        .where('schuljahr', isEqualTo: schuljahr)
        .where('beruf', isEqualTo: berufCode)
        .orderBy('jahrgangsstufe')
        .orderBy('zeitgruppe')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Klasse.fromFirestore(doc)).toList(),
        );
  }

  Future<String> createKlasse(Klasse klasse) async {
    final docRef = await _klassen.add(klasse.toFirestore());
    return docRef.id;
  }

  Future<void> updateKlasse(Klasse klasse) async {
    await _klassen.doc(klasse.id).update(klasse.toFirestore());
  }

  Future<void> deleteKlasse(String id) async {
    // Delete all related Leistungsnachweise
    final lnSnapshot = await _leistungsnachweise
        .where('klasseId', isEqualTo: id)
        .get();
    final batch = _db.batch();
    for (final doc in lnSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_klassen.doc(id));
    await batch.commit();
  }

  // ============ LEISTUNGSNACHWEISE ============

  Stream<List<Leistungsnachweis>> getLeistungsnachweise() {
    return _leistungsnachweise
        .orderBy('datum', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Leistungsnachweis.fromFirestore(doc))
              .toList(),
        );
  }

  Future<Leistungsnachweis> getLeistungsnachweis(String id) async {
    final doc = await _leistungsnachweise.doc(id).get();
    if (!doc.exists) throw Exception('Leistungsnachweis nicht gefunden');
    return Leistungsnachweis.fromFirestore(doc);
  }

  Stream<List<Leistungsnachweis>> getLeistungsnachweiseByKlasse(
    String klasseId,
  ) {
    return _leistungsnachweise
        .where('klasseId', isEqualTo: klasseId)
        .orderBy('datum', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Leistungsnachweis.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<Leistungsnachweis>> getLeistungsnachweiseBySubject(
    String subjectId,
  ) {
    return _leistungsnachweise
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('datum', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Leistungsnachweis.fromFirestore(doc))
              .toList(),
        );
  }

  Future<String> createLeistungsnachweis(Leistungsnachweis ln) async {
    final docRef = await _leistungsnachweise.add(ln.toFirestore());
    return docRef.id;
  }

  Future<void> updateLeistungsnachweis(Leistungsnachweis ln) async {
    await _leistungsnachweise.doc(ln.id).update(ln.toFirestore());
  }

  Future<void> deleteLeistungsnachweis(String id) async {
    // Auch alle zugehörigen Noten löschen
    await deleteGradesByLeistungsnachweis(id);
    await _leistungsnachweise.doc(id).delete();
  }

  // ============ IMPORT (KLASSE + STUDENTS) ============

  Future<String> importKlasseMitSchuelern({
    required Klasse klasse,
    required List<Student> schueler,
    String importSource = 'pdf',
  }) async {
    final klasseId = klasse.id.isEmpty ? _klassen.doc().id : klasse.id;
    final klasseData = klasse.copyWith(id: klasseId).toFirestore()
      ..addAll({
        'importSource': importSource,
        'importTimestamp': Timestamp.now(),
      });

    final batch = _db.batch();
    batch.set(_klassen.doc(klasseId), klasseData);

    for (final student in schueler) {
      final studentId = student.id.isEmpty ? _students.doc().id : student.id;
      batch.set(
        _students.doc(studentId),
        student
            .copyWith(
              id: studentId,
              klasseId: klasseId,
            )
            .toFirestore(),
      );
    }

    await batch.commit();
    return klasseId;
  }

  // ============ STATISTICS ============

  /// Berechnet den gewichteten Notendurchschnitt
  /// Die Gewichtung kommt vom Leistungsnachweis-Typ (muss separat übergeben werden)
  double calculateSimpleAverage(List<Grade> grades) {
    if (grades.isEmpty) return 0.0;
    final sum = grades.fold<int>(0, (sum, g) => sum + g.note);
    return sum / grades.length;
  }

  /// Berechnet den gewichteten Durchschnitt für Noten mit Gewichtungen
  double calculateWeightedAverage(List<({Grade grade, double gewichtung})> gradesWithWeight) {
    if (gradesWithWeight.isEmpty) return 0.0;

    double totalWeighted = 0.0;
    double totalWeight = 0.0;

    for (final item in gradesWithWeight) {
      totalWeighted += item.grade.note * item.gewichtung;
      totalWeight += item.gewichtung;
    }

    return totalWeight > 0 ? totalWeighted / totalWeight : 0.0;
  }
}
