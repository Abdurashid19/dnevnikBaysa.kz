import 'package:baysa_app/models/cst_class.dart';
import 'package:baysa_app/screens/dopScreens/add_student_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:baysa_app/services/user_service.dart';

class EditClassPage extends StatefulWidget {
  final Map<String, dynamic> classItem;

  const EditClassPage({Key? key, required this.classItem}) : super(key: key);

  @override
  _EditClassPageState createState() => _EditClassPageState();
}

class _EditClassPageState extends State<EditClassPage> {
  final UserService _userService = UserService();
  final TextEditingController _classNameController = TextEditingController();
  final Map<String, TextEditingController> _dayControllers = {
    "Понедельник": TextEditingController(),
    "Вторник": TextEditingController(),
    "Среда": TextEditingController(),
    "Четверг": TextEditingController(),
    "Пятница": TextEditingController(),
    "Суббота": TextEditingController(),
  };

  List<Map<String, dynamic>> _rateTypes = [];
  String? _selectedRateType;
  String? _selectedPeriod;
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _classNameController.text = widget.classItem['className'];
    _fetchRateTypes();
    _fetchStudents();
  }

  Future<void> _fetchRateTypes() async {
    setState(() => _isLoading = true);

    try {
      final rateTypes = await _userService.getLstRateType(context);
      setState(() {
        _rateTypes = rateTypes;
      });
    } catch (e) {
      print("Error fetching rate types: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    final response = await _userService.getListStudentForSpecClass(
      classId: widget.classItem['classId'],
      schoolYear: 2024,
      context: context,
    );
    setState(() {
      _students = response;
      _isLoading = false;
    });
  }

  void _showAddStudentDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AddStudentDialog(
          userService: _userService,
          onStudentAdded: (selectedStudent) {
            setState(() {
              _students.add(selectedStudent);
            });
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _dayControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cst.backgroundApp,
      appBar: AppBar(
        title: const Text('Редактирование класса'),
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        backgroundColor: Cst.backgroundAppBar,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(5.0),
              child: CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _classNameController,
                      decoration: const InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFDCE1E6)),
                        ),
                        labelText: 'Наименование класса',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: widget.classItem['subjectName'],
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Предмет',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isDense: true,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            value: _selectedRateType,
                            items: _rateTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type['id'].toString(),
                                child: Text(type['typeName']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRateType = value;
                              });
                            },
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFDCE1E6)),
                              ),
                              labelText: 'Тип оценивания',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            dropdownColor: Colors.white,
                            value: _selectedPeriod,
                            items: const [
                              DropdownMenuItem(
                                value: 'Четверть',
                                child: Text('Четверть'),
                              ),
                              DropdownMenuItem(
                                value: 'Полугодие',
                                child: Text('Полугодие'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriod = value;
                              });
                            },
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFDCE1E6)),
                              ),
                              labelText: 'Период',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildPairLayout(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ученики',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _showAddStudentDialog,
                        ),
                      ],
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return ListTile(
                          title:
                              Text(student['fio'] + ' ' + student['className']),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: CustomElevatedButton(
                        onPressed: () {
                          // Save functionality goes here
                        },
                        text: 'Сохранить',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Layout with two days per row
  Widget _buildPairLayout() {
    final List<Widget> rows = [];

    for (int i = 0; i < _dayControllers.entries.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dayControllers.entries.elementAt(i).value
                    ..text =
                        _dayControllers.entries.elementAt(i).value.text.isEmpty
                            ? '0'
                            : _dayControllers.entries.elementAt(i).value.text,
                  decoration: InputDecoration(
                    labelText: _dayControllers.entries.elementAt(i).key,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFDCE1E6)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Allow only digits
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (i + 1 < _dayControllers.entries.length)
                Expanded(
                  child: TextFormField(
                    controller: _dayControllers.entries.elementAt(i + 1).value
                      ..text = _dayControllers.entries
                              .elementAt(i + 1)
                              .value
                              .text
                              .isEmpty
                          ? '0'
                          : _dayControllers.entries.elementAt(i + 1).value.text,
                    decoration: InputDecoration(
                      labelText: _dayControllers.entries.elementAt(i + 1).key,
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFDCE1E6)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}
