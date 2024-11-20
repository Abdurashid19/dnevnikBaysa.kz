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
  int? subjectId;

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

      _fetchSubjects();
      _fetchRateTypes();
    } catch (e) {
      print('Ошибка загрузки данных: $e');
    }
  }

  Future<void> _fetchRateTypes() async {
    if (_selectedSubject == null) {
      return; // Проверка на случай, если предмет не выбран
    }

    setState(() => _isLoading = true);

    try {
      subjectId = int.tryParse(_selectedSubject ?? '');
      if (subjectId != null) {
        final rateTypes =
            await widget.userService.getLstRateType(subjectId!, context);
        setState(() {
          _rateTypes = rateTypes;
          // Если только одна запись, устанавливаем её как выбранную
          if (_rateTypes.length == 1) {
            _selectedRateType = _rateTypes.first['id'].toString();
          }
        });
      }
    } catch (e) {
      print("Error fetching rate types: $e");
    } finally {
      setState(() => _isLoading = false);
    }
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
      if (_selectedSubject != null) {
        _fetchRateTypes();
      }
    } catch (e) {
      print("Error fetching subjects: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSpecialClass() async {
    final className = _classNameController.text;

    // Проверка на заполненность обязательных полей
    if (className.isEmpty ||
        _selectedSubject == null ||
        _selectedRateType == null ||
        _selectedPeriod == null) {
      // Показываем сообщение об ошибке
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните все обязательные поля.'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Прерываем выполнение метода
    }

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
        title: Text(
          'Добавление спец.класса',
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
                      controller: _classNameController,
                      labelText: 'Наименование класса',
                    ),
                    const SizedBox(height: 10),
                    AppDropdownField<String>(
                      value: _selectedSubject,
                      items: _subjects
                          .map((subject) => subject['id'].toString())
                          .toList(),
                      labelText: 'Предмет',
                      itemLabelBuilder: (value) {
                        final subject = _subjects.firstWhere(
                          (element) => element['id'].toString() == value,
                        );
                        return subject != null ? subject['name'] : '';
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedSubject = value;
                        });

                        // Вызываем _fetchRateTypes при выборе предмета
                        if (_selectedSubject != null) {
                          _fetchRateTypes();
                        }
                      },
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
                              return type != null ? type['typeName'] : '';
                            },
                            onChanged: (value) {
                              setState(() {
                                _selectedRateType = value;
                              });
                            },
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
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriod = value;
                              });
                            },
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
