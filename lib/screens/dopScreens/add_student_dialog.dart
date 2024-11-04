// add_student_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:baysa_app/services/user_service.dart';

class AddStudentDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onStudentAdded;
  final UserService userService;

  const AddStudentDialog({
    Key? key,
    required this.onStudentAdded,
    required this.userService,
  }) : super(key: key);

  @override
  _AddStudentDialogState createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  final TextEditingController _studentSearchController =
      TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedStudent;
  bool isSearching = false;

  Future<void> _searchStudent(String query) async {
    setState(() {
      isSearching = true;
    });

    final results =
        await widget.userService.getListStudentForSpecClassForSelect(
      schoolYear: 2024,
      query: query,
      context: context,
    );

    setState(() {
      _searchResults = results;
      isSearching = false;
    });
  }

  @override
  void dispose() {
    _studentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.5,
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Добавление ученика в спец.класс',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _studentSearchController,
              decoration: const InputDecoration(
                labelText: 'Ученик',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _searchStudent(value);
                } else {
                  setState(() {
                    _searchResults = [];
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              value: _selectedStudent,
              hint: const Text('Выберите ученика'),
              items: _searchResults.map((student) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: student,
                  child: Text('${student['fio']} ${student['className']}'),
                );
              }).toList(),
              onChanged: (selected) {
                setState(() {
                  _selectedStudent = selected;
                  _studentSearchController.text = selected?['fio'] ?? '';
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_selectedStudent != null) {
                  widget.onStudentAdded(_selectedStudent!);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Пожалуйста, выберите ученика'),
                    ),
                  );
                }
              },
              child: const Text('Сохранить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
