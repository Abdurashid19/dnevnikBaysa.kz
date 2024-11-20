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
  int? subjectId;

  @override
  void initState() {
    super.initState();
    _classNameController.text = widget.classItem['className'];
    _selectedPeriod = widget.classItem['periodType'] == ''
        ? 'Четверть'
        : widget.classItem['periodType'];
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
      final rateTypes = await _userService.getLstRateType(
          widget.classItem['subjectId'], context);
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
    final prefs = await SharedPreferences.getInstance();
    final schoolYear = prefs.getInt('schoolYear') ?? 2024;

    final response = await _userService.getListStudentForSpecClass(
      classId: widget.classItem['classId'],
      schoolYear: schoolYear,
      context: context,
    );
    setState(() {
      _students = response;
      _isLoading = false;
    });
  }

  Future<void> _saveSpecialClass() async {
    final prefs = await SharedPreferences.getInstance();
    final schoolYear = prefs.getInt('schoolYear') ?? 2024;
    final teacherId = prefs.getInt('userId');

    final classId = widget.classItem['classId'];
    final subjectId = widget.classItem['subjectId'];
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
      teacherId: teacherId!,
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
    final result = await showDialog(
      context: context,
      builder: (context) {
        return AddStudentPage(
          classId: widget.classItem['classId'],
          schoolYear: 2024,
          userService: _userService,
          onStudentAdded: (selectedStudent) {
            setState(() {
              _students.add(selectedStudent);
            });
            // Close dialog with "success" result
            Navigator.of(context).pop('success');
          },
        );
      },
    );

    if (result == 'success') {
      _fetchStudents();
    }
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
        title: Text(
          'Редактирование класса',
          style: TextStyle(fontSize: Cst.appBarTextSize, color: Cst.color),
        ),
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
                    AppTextFormField(
                      enabled: isSpecialClass,
                      controller: _classNameController,
                      labelText: 'Наименование класса',
                    ),
                    const SizedBox(height: 10),
                    AppTextFormField(
                      initialValue: widget.classItem['subjectName'],
                      enabled: false,
                      labelText: 'Предмет',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppDropdownField<String>(
                            value: _selectedRateType,
                            items: _rateTypes
                                .map((type) => type['id'].toString())
                                .toList(),
                            labelText: 'Тип оценивания',
                            itemLabelBuilder: (value) {
                              final type = _rateTypes.firstWhere(
                                (element) => element['id'].toString() == value,
                              );
                              return type['typeName'] ?? '';
                            },
                            onChanged: isSpecialClass
                                ? (value) {
                                    setState(() {
                                      _selectedRateType = value;
                                    });
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppDropdownField<String>(
                            value: _selectedPeriod,
                            items: ['Четверть', 'Полугодие'],
                            labelText: 'Период',
                            itemLabelBuilder: (value) {
                              if (value == 'Четверть') return 'Четверть';
                              if (value == 'Полугодие') return 'Полугодие';
                              return '';
                            },
                            onChanged: isSpecialClass
                                ? (value) {
                                    setState(() {
                                      _selectedPeriod = value;
                                    });
                                  }
                                : null,
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
                        physics: const NeverScrollableScrollPhysics(),
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

  void _handleHourInput(int index, String value) {
    final controller = _dayControllers.entries.elementAt(index).value;

    // Убираем ведущие нули
    final sanitizedValue = value.replaceFirst(RegExp(r'^0+'), '');

    // Если поле становится пустым, возвращаем значение '0'
    if (sanitizedValue.isEmpty) {
      controller.text = '0';
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
      return;
    }

    // Обновляем значение без ведущих нулей
    controller.text = sanitizedValue;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
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
                child: AppTextFormField(
                  controller: _dayControllers.entries.elementAt(i).value
                    ..text =
                        _dayControllers.entries.elementAt(i).value.text.isEmpty
                            ? '0'
                            : _dayControllers.entries.elementAt(i).value.text,
                  labelText: _dayControllers.entries.elementAt(i).key,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onTap: () {
                    if (_dayControllers.entries.elementAt(i).value.text ==
                        '0') {
                      _dayControllers.entries.elementAt(i).value.clear();
                    }
                  },
                  onChanged: (value) {
                    _handleHourInput(i, value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (i + 1 < _dayControllers.entries.length)
                Expanded(
                  child: AppTextFormField(
                    controller: _dayControllers.entries.elementAt(i + 1).value
                      ..text = _dayControllers.entries
                              .elementAt(i + 1)
                              .value
                              .text
                              .isEmpty
                          ? '0'
                          : _dayControllers.entries.elementAt(i + 1).value.text,
                    labelText: _dayControllers.entries.elementAt(i + 1).key,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onTap: () {
                      if (_dayControllers.entries.elementAt(i + 1).value.text ==
                          '0') {
                        _dayControllers.entries.elementAt(i + 1).value.clear();
                      }
                    },
                    onChanged: (value) {
                      _handleHourInput(i + 1, value);
                    },
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
