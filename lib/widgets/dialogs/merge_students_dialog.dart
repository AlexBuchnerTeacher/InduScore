import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/student.dart';
import '../../core/theme/rbs_theme.dart';
import '../../providers/student_provider.dart';

class MergeStudentsDialog extends StatefulWidget {
  final Student student1;
  final Student student2;

  const MergeStudentsDialog({
    super.key,
    required this.student1,
    required this.student2,
  });

  @override
  State<MergeStudentsDialog> createState() => _MergeStudentsDialogState();
}

class _MergeStudentsDialogState extends State<MergeStudentsDialog> {
  late Student _primaryStudent;
  late Student _secondaryStudent;

  @override
  void initState() {
    super.initState();
    _primaryStudent = widget.student1;
    _secondaryStudent = widget.student2;
  }

  void _swapStudents() {
    setState(() {
      final temp = _primaryStudent;
      _primaryStudent = _secondaryStudent;
      _secondaryStudent = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Merge Students'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select which student record to keep as primary:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: RbsSpacing.md),
            _buildStudentCard(_primaryStudent, isPrimary: true),
            const SizedBox(height: RbsSpacing.sm),
            Center(
              child: IconButton(
                icon: const Icon(Icons.swap_vert),
                onPressed: _swapStudents,
                tooltip: 'Swap primary and secondary',
              ),
            ),
            const SizedBox(height: RbsSpacing.sm),
            _buildStudentCard(_secondaryStudent, isPrimary: false),
            const SizedBox(height: RbsSpacing.md),
            const Text(
              'The primary student\'s information will be kept. '
              'All grades and attendance from both students will be merged.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _performMerge(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: RbsColors.primary,
          ),
          child: const Text('Merge Students'),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Student student, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.all(RbsSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(
          color: isPrimary ? RbsColors.primary : RbsColors.border,
          width: isPrimary ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isPrimary ? RbsColors.primary.withOpacity(0.1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPrimary)
            const Padding(
              padding: EdgeInsets.only(bottom: RbsSpacing.xs),
              child: Text(
                'PRIMARY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: RbsColors.primary,
                ),
              ),
            ),
          Text(
            '${student.lastName}, ${student.firstName}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: RbsSpacing.xs),
          Text('Student ID: ${student.studentId}'),
          if (student.email.isNotEmpty) Text('Email: ${student.email}'),
          if (student.parentEmail.isNotEmpty)
            Text('Parent Email: ${student.parentEmail}'),
        ],
      ),
    );
  }

  Future<void> _performMerge(BuildContext context) async {
    try {
      final studentProvider =
          Provider.of<StudentProvider>(context, listen: false);

      // Merge the students
      await studentProvider.mergeStudents(
        primaryStudent: _primaryStudent,
        secondaryStudent: _secondaryStudent,
      );

      if (context.mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Students merged successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error merging students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
