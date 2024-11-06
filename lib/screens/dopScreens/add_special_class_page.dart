import 'package:baysa_app/models/cst_class.dart';
import 'package:baysa_app/models/success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:baysa_app/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddSpecialClassPage extends StatefulWidget {
  final UserService userService;

  const AddSpecialClassPage({
    Key? key,
    required this.userService,
  }) : super(key: key);

  @override
  _AddSpecialClassPageState createState() => _AddSpecialClassPageState();
}

class _AddSpecialClassPageState extends State<AddSpecialClassPage> {
  final TextEditingController _classNameController = TextEditingController();
  final Map<String, TextEditingController> _dayControllers = {
    "Понедельник": TextEditingController(),
    "Вторник": TextEditingController(),
    "Среда": TextEditingController(),
    "Четверг": TextEditingController(),
    "Пятница": TextEditingController(),
    "Суббота": TextEditingController(),
  };
  int? _schoolYear;
  int? _teacherId;

  List<Map<String, dynamic>> _rateTypes = [];
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedRateType;
  String? _selectedPeriod;
  String? _selectedSubject;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Получаем данные пользователя из SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _schoolYear = prefs.getInt('schoolYear') ?? 2024;
      _teacherId = prefs.getInt('userId');

      if (_teacherId == null) {
        final userEmail = prefs.getString('userEmail') ?? '';
        await widget.userService.checkUserMs(userEmail, context);

        // Повторно получаем данные после загрузки

        _schoolYear = prefs.getInt('schoolYear') ?? 2024;
        _teacherId = prefs.getInt('userId');
      }

      _fetchRateTypes();
      _fetchSubjects();
    } catch (e) {
      print('Ошибка загрузки данных: $e');
    }
  }

  Future<void> _fetchRateTypes() async {
    setState(() => _isLoading = true);

    try {
      final rateTypes = await widget.userService.getLstRateType(context);
      setState(() {
        _rateTypes = rateTypes;
      });
    } catch (e) {
      print("Error fetching rate types: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);

    try {
      final subjects = await widget.userService.getListPredmetForSpecClass(
        teacherId: _teacherId!,
        schoolYear: _schoolYear!,
        context: context,
      );

      setState(() {
        _subjects = subjects;
        if (_subjects.length == 1) {
          _selectedSubject = _subjects.first['id'].toString();
        }
      });
    } catch (e) {
      print("Error fetching subjects: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSpecialClass() async {
    final className = _classNameController.text;
    final jsonLstDayNum = _dayControllers.entries.map((entry) {
      int dayId = _getDayId(entry.key);
      return {
        'id': dayId,
        'name': entry.key,
        'cntLesson': int.tryParse(entry.value.text) ?? 0,
      };
    }).toList();

    final success = await widget.userService.saveSpecialClass(
      classId: 0, // New class
      teacherId: _teacherId!,
      subjectId: int.tryParse(_selectedSubject ?? '') ?? 0,
      schoolYear: _schoolYear!,
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
        text: 'Класс успешно добавлен',
        onClose: () {
          Navigator.of(context).pop();
          Navigator.of(this.context).pop('success');
        },
      ),
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
        title: const Text('Добавление спец.класса'),
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
                      decoration: CustomInputDecoration.getDecoration(
                        labelText: 'Наименование класса',
                        isSpecialClass: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      value: _selectedSubject,
                      items: _subjects.map((subject) {
                        return DropdownMenuItem<String>(
                          value: subject['id'].toString(),
                          child: Text(subject['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubject = value;
                        });
                      },
                      decoration: CustomInputDecoration.getDecoration(
                        labelText: 'Предмет',
                        isSpecialClass: true,
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
                            decoration: CustomInputDecoration.getDecoration(
                              labelText: 'Тип оценивания',
                              isSpecialClass: true,
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
                            decoration: CustomInputDecoration.getDecoration(
                              labelText: 'Период',
                              isSpecialClass: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildPairLayout(),
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
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
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
