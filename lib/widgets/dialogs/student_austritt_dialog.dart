import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/rbs_theme.dart';
import '../../models/student.dart';
import '../../providers/app_providers.dart';

/// Dialog for marking a student as withdrawn (ausgetreten)
class StudentAustrittDialog extends ConsumerStatefulWidget {
  final Student student;

  const StudentAustrittDialog({super.key, required this.student});

  @override
  ConsumerState<StudentAustrittDialog> createState() => _StudentAustrittDialogState();
}

class _StudentAustrittDialogState extends ConsumerState<StudentAustrittDialog> {
  late DateTime _austrittsDatum;

  @override
  void initState() {
    super.initState();
    _austrittsDatum = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Austritt markieren'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${widget.student.displayName} als ausgetreten markieren?'),
          const SizedBox(height: RBSSpacing.md),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Austrittsdatum',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('dd.MM.yyyy').format(_austrittsDatum)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _markAsAusgetreten,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Als ausgetreten markieren'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _austrittsDatum,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Austrittsdatum',
    );
    if (picked != null) {
      setState(() => _austrittsDatum = picked);
    }
  }

  Future<void> _markAsAusgetreten() async {
    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      await firestoreService.updateStudent(
        widget.student.copyWith(
          austrittsDatum: _austrittsDatum,
          status: StudentStatus.ausgetreten,
        ),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.student.displayName} wurde als ausgetreten markiert'),
            backgroundColor: RBSColors.courtGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: RBSColors.dynamicRed,
          ),
        );
      }
    }
  }
}
