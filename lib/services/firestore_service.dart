import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/industry.dart';
import '../models/assessment.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Students
  Future<void> addStudent(Student student) async {
    await _firestore.collection('students').add(student.toMap());
  }

  Future<void> updateStudent(String id, Student student) async {
    await _firestore.collection('students').doc(id).update(student.toMap());
  }

  Future<void> deleteStudent(String id) async {
    await _firestore.collection('students').doc(id).delete();
  }

  Stream<List<Student>> getStudents() {
    return _firestore
        .collection('students')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Student.fromFirestore).toList());
  }

  // Teachers
  Future<void> addTeacher(Teacher teacher) async {
    await _firestore.collection('teachers').add(teacher.toMap());
  }

  Future<void> updateTeacher(String id, Teacher teacher) async {
    await _firestore.collection('teachers').doc(id).update(teacher.toMap());
  }

  Future<void> deleteTeacher(String id) async {
    await _firestore.collection('teachers').doc(id).delete();
  }

  Stream<List<Teacher>> getTeachers() {
    return _firestore
        .collection('teachers')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Teacher.fromFirestore).toList());
  }

  // Industries
  Future<void> addIndustry(Industry industry) async {
    await _firestore.collection('industries').add(industry.toMap());
  }

  Future<void> updateIndustry(String id, Industry industry) async {
    await _firestore.collection('industries').doc(id).update(industry.toMap());
  }

  Future<void> deleteIndustry(String id) async {
    await _firestore.collection('industries').doc(id).delete();
  }

  Stream<List<Industry>> getIndustries() {
    return _firestore
        .collection('industries')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Industry.fromFirestore).toList());
  }

  // Assessments
  Future<void> addAssessment(Assessment assessment) async {
    await _firestore.collection('assessments').add(assessment.toMap());
  }

  Future<void> updateAssessment(String id, Assessment assessment) async {
    await _firestore
        .collection('assessments')
        .doc(id)
        .update(assessment.toMap());
  }

  Future<void> deleteAssessment(String id) async {
    await _firestore.collection('assessments').doc(id).delete();
  }

  Stream<List<Assessment>> getAssessments() {
    return _firestore
        .collection('assessments')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Assessment.fromFirestore).toList());
  }

  Stream<List<Assessment>> getAssessmentsByStudent(String studentId) {
    return _firestore
        .collection('assessments')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Assessment.fromFirestore).toList());
  }

  Stream<List<Assessment>> getAssessmentsByIndustry(String industryId) {
    return _firestore
        .collection('assessments')
        .where('industryId', isEqualTo: industryId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Assessment.fromFirestore).toList());
  }
}
