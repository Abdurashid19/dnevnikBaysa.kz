import 'package:baysa_app/models/cst_class.dart';
import 'package:baysa_app/models/success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:baysa_app/services/user_service.dart';

class AddStudentPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onStudentAdded;
  final UserService userService;
  final int classId;
  final int schoolYear;

  const AddStudentPage({
    Key? key,
    required this.onStudentAdded,
    required this.userService,
    required this.classId,
    required this.schoolYear,
  }) : super(key: key);

  @override
  _AddStudentPageState createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
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
      schoolYear: widget.schoolYear,
      query: query,
      context: context,
    );

    setState(() {
      _searchResults = results;
      isSearching = false;
    });
  }

  Future<void> _saveStudent() async {
    if (_selectedStudent != null) {
      final studentId = _selectedStudent!['id'];
      final isSuccess = await widget.userService.addStudentForSpecClass(
        classId: widget.classId,
        studentId: studentId,
        schoolYear: widget.schoolYear,
        context: context,
      );

      if (isSuccess) {
        showDialog(
          context: context,
          builder: (BuildContext context) => SuccessDialog(
            text: 'Ученик добавлен',
            onClose: () {
              Navigator.of(context).pop();
              Navigator.of(this.context).pop('success');
            },
          ),
        );
        // showDialog(
        //   context: context,
        //   builder: (BuildContext context) => AlertDialog(
        //     content: const Text('Ученик добавлен'),
        //     actions: [
        //       TextButton(
        //         onPressed: () {
        //           Navigator.of(context).pop();
        //           Navigator.of(this.context).pop('success');
        //         },
        //         child: const Text('ОК'),
        //       ),
        //     ],
        //   ),
        // );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите ученика'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _studentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cst.backgroundApp,
      appBar: AppBar(
        title: const Text('Добавление ученика в спец.класс'),
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        backgroundColor: Cst.backgroundAppBar,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(5.0),
        child: CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Container(
                height: 350, // Limit the height for the ListView
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final student = _searchResults[index];
                    return ListTile(
                      title: Text('${student['fio']} ${student['className']}'),
                      onTap: () {
                        setState(() {
                          _selectedStudent = student;
                          _studentSearchController.text = student['fio'];
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveStudent,
                  child: const Text('Сохранить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
