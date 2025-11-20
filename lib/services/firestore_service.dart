import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade.dart';
import '../models/student.dart';
import '../models/subject.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _students => _db.collection('students');
  CollectionReference get _subjects => _db.collection('subjects');
  CollectionReference get _grades => _db.collection('grades');

  // ============ STUDENTS ============

  Stream<List<Student>> getStudents() {
    return _students
        .orderBy('lastName')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList());
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
    final gradesSnapshot = await _grades.where('studentId', isEqualTo: id).get();
    final batch = _db.batch();
    for (final doc in gradesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_students.doc(id));
    await batch.commit();
  }

  // ============ SUBJECTS ============

  Stream<List<Subject>> getSubjects() {
    return _subjects
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList());
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
    final gradesSnapshot = await _grades.where('subjectId', isEqualTo: id).get();
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
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Grade.fromFirestore(doc)).toList());
  }

  Stream<List<Grade>> getGradesByStudent(String studentId) {
    return _grades
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Grade.fromFirestore(doc)).toList());
  }

  Stream<List<Grade>> getGradesBySubject(String subjectId) {
    return _grades
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Grade.fromFirestore(doc)).toList());
  }

  Stream<List<Grade>> getGradesByStudentAndSubject(String studentId, String subjectId) {
    return _grades
        .where('studentId', isEqualTo: studentId)
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Grade.fromFirestore(doc)).toList());
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

  Future<void> updateGrade(Grade grade) async {
    await _grades.doc(grade.id).update(grade.toFirestore());
  }

  Future<void> deleteGrade(String id) async {
    await _grades.doc(id).delete();
  }

  // ============ STATISTICS ============

  Future<double> calculateAverage(List<Grade> grades) async {
    if (grades.isEmpty) return 0.0;

    double totalWeighted = 0.0;
    double totalWeight = 0.0;

    for (final grade in grades) {
      totalWeighted += grade.value * grade.weight;
      totalWeight += grade.weight;
    }

    return totalWeight > 0 ? totalWeighted / totalWeight : 0.0;
  }

  Future<Map<String, double>> getAveragesBySubject(String studentId) async {
    final subjects = await _subjects.get();
    final Map<String, double> averages = {};

    for (final subjectDoc in subjects.docs) {
      final gradesSnapshot = await _grades
          .where('studentId', isEqualTo: studentId)
          .where('subjectId', isEqualTo: subjectDoc.id)
          .get();

      final grades = gradesSnapshot.docs.map((doc) => Grade.fromFirestore(doc)).toList();
      averages[subjectDoc.id] = await calculateAverage(grades);
    }

    return averages;
  }
}
