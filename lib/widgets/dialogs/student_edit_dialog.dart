import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/rbs_theme.dart';
import '../../models/student.dart';
import '../../providers/app_providers.dart';

/// Dialog for editing an existing student
/// 
/// Note: Creating new students is not supported via this dialog
/// as it requires class selection which is complex.
class StudentEditDialog extends ConsumerStatefulWidget {
  final Student student;

  const StudentEditDialog({super.key, required this.student});

  @override
  ConsumerState<StudentEditDialog> createState() => _StudentEditDialogState();
}

class _StudentEditDialogState extends ConsumerState<StudentEditDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late DateTime _eintrittsDatum;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.student.firstName);
    _lastNameController = TextEditingController(text: widget.student.lastName);
    _eintrittsDatum = widget.student.eintrittsDatum;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schüler bearbeiten'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'Vorname',
              hintText: 'z.B. Max',
            ),
            autofocus: true,
          ),
          const SizedBox(height: RBSSpacing.sm),
          TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Nachname',
              hintText: 'z.B. Mustermann',
            ),
          ),
          const SizedBox(height: RBSSpacing.md),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Eintrittsdatum',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('dd.MM.yyyy').format(_eintrittsDatum)),
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
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: RBSColors.dynamicRed,
            foregroundColor: Colors.white,
          ),
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eintrittsDatum,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Eintrittsdatum',
    );
    if (picked != null) {
      setState(() => _eintrittsDatum = picked);
    }
  }

  Future<void> _save() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    
    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Vor- und Nachname eingeben')),
      );
      return;
    }

    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      await firestoreService.updateStudent(
        widget.student.copyWith(
          firstName: firstName,
          lastName: lastName,
          eintrittsDatum: _eintrittsDatum,
        ),
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schüler aktualisiert'),
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
