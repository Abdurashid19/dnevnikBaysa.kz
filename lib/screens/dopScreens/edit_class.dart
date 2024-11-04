import 'package:baysa_app/models/cst_class.dart';
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
    final TextEditingController _studentSearchController =
        TextEditingController();
    List<Map<String, dynamic>> _searchResults = [];
    Map<String, dynamic>? _selectedStudent;
    bool isSearching = false;

    Future<void> _searchStudent(String query) async {
      setState(() {
        isSearching = true;
      });

      final results = await _userService.getListStudentForSpecClassForSelect(
        schoolYear: 2024,
        query: query,
        context: context,
      );

      setState(() {
        _searchResults = results;
        isSearching = false;
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
            child: Stack(
              children: [
                Positioned(
                  right: -10.0,
                  top: -10.0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 30),
                    const Text(
                      'Добавление ученика в спец.класс',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                    // if (_searchResults.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.2,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final student = _searchResults[index];
                          return ListTile(
                            title: Text(
                                '${student['fio']} ${student['className']}'),
                            onTap: () {
                              setState(() {
                                _selectedStudent = student;
                                _studentSearchController.text = student['fio'];
                                _searchResults =
                                    []; // Clear results after selection
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedStudent != null) {
                          setState(() {
                            _students.add(_selectedStudent!);
                          });
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
              ],
            ),
          ),
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
