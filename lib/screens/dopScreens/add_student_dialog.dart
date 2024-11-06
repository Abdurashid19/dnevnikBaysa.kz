import 'package:baysa_app/models/cst_class.dart';
import 'package:flutter/material.dart';
import 'package:baysa_app/services/user_service.dart';

class AddStudentPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onStudentAdded;
  final UserService userService;

  const AddStudentPage({
    Key? key,
    required this.onStudentAdded,
    required this.userService,
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
                height: 200, // Set a fixed height to limit ListView.builder
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Function to open AddStudentPage
void _openAddStudentPage(BuildContext context, UserService userService) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddStudentPage(
        onStudentAdded: (student) {
          // Handle the added student here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Добавлен ученик: ${student['fio']}'),
            ),
          );
          // You can add logic to update the list or database here
        },
        userService: userService,
      ),
    ),
  );
}

// Example usage in a parent widget
class ParentWidget extends StatelessWidget {
  final UserService userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная страница'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _openAddStudentPage(context, userService),
          child: const Text('Добавить ученика в спец.класс'),
        ),
      ),
    );
  }
}
