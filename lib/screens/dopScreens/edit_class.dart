import 'package:baysa_app/models/cst_class.dart';
import 'package:baysa_app/models/success_dialog.dart';
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

  bool get isSpecialClass => widget.classItem['typeClass'] == 1;

  @override
  void initState() {
    super.initState();
    _classNameController.text = widget.classItem['className'];
    _selectedPeriod = widget.classItem['periodType'];
    _initializeDayControllers();
    _fetchRateTypes();
    _fetchStudents();
  }

  void _initializeDayControllers() {
    final Map<int, String> idToWeekday = {
      1: "Понедельник",
      2: "Вторник",
      3: "Среда",
      4: "Четверг",
      5: "Пятница",
      6: "Суббота",
    };

    if (widget.classItem.containsKey('lst')) {
      for (var item in widget.classItem['lst']) {
        int id = item['id'];
        int cntLesson = item['cntLesson'];

        String? weekday = idToWeekday[id];

        if (weekday != null && _dayControllers.containsKey(weekday)) {
          _dayControllers[weekday]?.text = cntLesson.toString();
        }
      }
    }
  }

  Future<void> _fetchRateTypes() async {
    setState(() => _isLoading = true);

    try {
      final rateTypes = await _userService.getLstRateType(context);
      setState(() {
        _rateTypes = rateTypes;

        // Check if rateTypeId exists in classItem and set _selectedRateType accordingly
        if (widget.classItem.containsKey('rateTypeId')) {
          final rateTypeId = widget.classItem['rateTypeId'].toString();
          final matchingRateType = rateTypes.firstWhere(
            (type) => type['id'].toString() == rateTypeId,
            orElse: () => {},
          );

          if (matchingRateType.isNotEmpty) {
            _selectedRateType = rateTypeId;
          }
        }
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

  Future<void> _saveSpecialClass() async {
    final classId = widget.classItem['classId'];
    final teacherId = 1260; // Replace with actual teacher ID
    final subjectId = widget.classItem['subjectId'];
    final schoolYear = 2024;
    final className = _classNameController.text;
    final jsonLstDayNum = _dayControllers.entries.map((entry) {
      int dayId = _getDayId(entry.key);
      return {
        'id': dayId,
        'name': entry.key,
        'cntLesson': int.tryParse(entry.value.text) ?? 0,
      };
    }).toList();

    final success = await _userService.saveSpecialClass(
      classId: classId,
      teacherId: teacherId,
      subjectId: subjectId,
      schoolYear: schoolYear,
      className: className,
      jsonLstDayNum: jsonLstDayNum,
      periodType: _selectedPeriod ?? '',
      rateTypeId: _selectedRateType ?? '',
      context: context,
    );

    if (success) {
      _showSuccessDialog();
    } else {
      print("Failed to save special class");
    }
  }

  int _getDayId(String day) {
    switch (day) {
      case "Понедельник":
        return 1;
      case "Вторник":
        return 2;
      case "Среда":
        return 3;
      case "Четверг":
        return 4;
      case "Пятница":
        return 5;
      case "Суббота":
        return 6;
      default:
        return 0;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => SuccessDialog(
        text: 'Выполнено',
        onClose: () {
          Navigator.of(context).pop();
          Navigator.of(this.context).pop('success');
        },
      ),
    );
  }

  void _showAddStudentDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AddStudentPage(
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
                      enabled: isSpecialClass,
                      controller: _classNameController,
                      decoration: CustomInputDecoration.getDecoration(
                        labelText: 'Наименование класса',
                        isSpecialClass: isSpecialClass,
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
                            onChanged: isSpecialClass
                                ? (value) {
                                    setState(() {
                                      _selectedRateType = value;
                                    });
                                  }
                                : null,
                            decoration: CustomInputDecoration.getDecoration(
                              labelText: 'Тип оценивания',
                              isSpecialClass: isSpecialClass,
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
                            onChanged: isSpecialClass
                                ? (value) {
                                    setState(() {
                                      _selectedPeriod = value;
                                    });
                                  }
                                : null,
                            decoration: CustomInputDecoration.getDecoration(
                              labelText: 'Период',
                              isSpecialClass: isSpecialClass,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildPairLayout(),
                    const SizedBox(height: 10),
                    if (isSpecialClass)
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
                    if (isSpecialClass)
                      ListView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(), // Без отдельного скролла
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return ListTile(
                            title: Text(
                                '${student['fio']} ${student['className']}'),
                          );
                        },
                      ),
                    const SizedBox(height: 10),
                    Center(
                      child: CustomElevatedButton(
                        onPressed: _saveSpecialClass,
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
                  decoration: CustomInputDecoration.getDecoration(
                    labelText: _dayControllers.entries.elementAt(i).key,
                    // isSpecialClass: isSpecial,
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
                    decoration: CustomInputDecoration.getDecoration(
                      labelText: _dayControllers.entries.elementAt(i + 1).key,
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
