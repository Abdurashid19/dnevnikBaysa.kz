import 'dart:convert';
import 'package:baysa_app/models/error_dialog.dart';
import 'package:baysa_app/models/success_dialog.dart';
import 'package:baysa_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonDetailsPage extends StatefulWidget {
  final Map<String, dynamic> lesson;

  const LessonDetailsPage({Key? key, required this.lesson}) : super(key: key);

  @override
  _LessonDetailsPageState createState() => _LessonDetailsPageState();
}

class _LessonDetailsPageState extends State<LessonDetailsPage> {
  late TextEditingController _dateController;
  late TextEditingController _cntRatesController;
  late TextEditingController _maxPointController;

  List<Map<String, dynamic>> _gradeTypes = [];
  List<Map<String, dynamic>> _themes = [];
  Map<String, dynamic>? _selectedGradeType;
  Map<String, dynamic>? _selectedTheme;

  final UserService _userService = UserService();
  bool isLoading = false; // Переменная для состояния загрузки

  @override
  void initState() {
    super.initState();

    DateTime parsedDate = DateTime.parse(widget.lesson['date2']);
    String formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);

    _dateController = TextEditingController(text: formattedDate);
    _cntRatesController =
        TextEditingController(text: widget.lesson['cntRates'].toString());
    _maxPointController =
        TextEditingController(text: widget.lesson['maxPoint'].toString());

    _fetchGradeTypes();
    _fetchThemes();
  }

  // Получаем типы занятий
  Future<void> _fetchGradeTypes() async {
    setState(() => isLoading = true); // Включаем прелоудер
    try {
      final prefs = await SharedPreferences.getInstance();
      final _sid = prefs.getString('sid');
      final _teacherId = prefs.getInt('userId');

      final gradeTypes = await _userService.getGradeTypes(
        _teacherId!,
        _sid!,
        context,
      );
      setState(() {
        _gradeTypes = gradeTypes;
        _selectedGradeType = gradeTypes.isNotEmpty ? gradeTypes[0] : null;
      });
    } catch (e) {
      print('Ошибка при загрузке типов занятий: $e');
    } finally {
      setState(() => isLoading = false); // Отключаем прелоудер
    }
  }

  // Получаем список тем
  Future<void> _fetchThemes() async {
    setState(() => isLoading = true); // Включаем прелоудер
    try {
      final prefs = await SharedPreferences.getInstance();
      final _sid = prefs.getString('sid');
      final _schoolYear = prefs.getInt('schoolYear') ?? 2024;
      final _teacherId = prefs.getInt('userId');

      final themes = await _userService.getThemes(
        widget.lesson['subjectId'],
        widget.lesson['classId'],
        _schoolYear,
        _teacherId!,
        _sid!,
        lessonId: widget.lesson['id'],
        context: context,
      );
      setState(() {
        _themes = themes;
      });
    } catch (e) {
      print('Ошибка при загрузке тем: $e');
    } finally {
      setState(() => isLoading = false); // Отключаем прелоудер
    }
  }

  Future<void> _saveLesson() async {
    setState(() => isLoading = true); // Включаем прелоудер
    try {
      final prefs = await SharedPreferences.getInstance();
      final _sid = prefs.getString('sid');
      final _teacherId = prefs.getInt('userId');
      final _schoolYear = prefs.getInt('schoolYear') ?? 2024;
      final int themeId = _selectedTheme!['id'];
      final int gradeType = _selectedGradeType!['id'];

      final isSaved = await _userService.recLesson(
        recId: widget.lesson['id'],
        classId: widget.lesson['classId'],
        date: _dateController.text,
        subjectId: widget.lesson['subjectId'],
        teacherId: _teacherId!,
        themeId: themeId,
        maxPoint: int.parse(_maxPointController.text),
        gradeType: gradeType,
        sid: _sid!,
        schoolYear: _schoolYear,
        context: context,
      );

      if (isSaved['retNum'] == 0) {
        // Показ успешного сообщения
        showDialog(
          context: context,
          builder: (BuildContext context) => SuccessDialog(
            text: 'Урок успешно сохранен!',
            onClose: () {
              Navigator.of(context).pop(); // Закрываем диалог
              Navigator.of(this.context)
                  .pop('success'); // Закрываем экран и передаем результат
            },
          ),
        );
      } else if (isSaved['retNum'] == -1) {
        // Показ сообщения об ошибке
        showDialog(
          context: context,
          builder: (BuildContext context) => ErrorDialog(
            text: isSaved['retStr'] ?? 'Ошибка при сохранении урока.',
            onClose: () {
              Navigator.of(context).pop(); // Закрываем диалог
              // Navigator.of(this.context)
              //     .pop('error'); // Закрываем экран и передаем результат
            },
          ),
        );
      } else {
        // Показ сообщения об ошибке
        showDialog(
          context: context,
          builder: (BuildContext context) => ErrorDialog(
            text: isSaved['retStr'] ?? 'Ошибка при сохранении урока.',
            onClose: () {
              Navigator.of(context).pop(); // Закрываем диалог
              // Navigator.of(this.context)
              //     .pop('error'); // Закрываем экран и передаем результат
            },
          ),
        );
      }
    } catch (e) {
      print('Ошибка при сохранении урока: $e');
    } finally {
      setState(() => isLoading = false); // Отключаем прелоудер
    }
  }

  // Функция для показа диалога об успешном сохранении
  void _showSuccessDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // title: Text(
          //   'Успешно', // Здесь вы можете заменить заголовок, если нужно
          //   style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          // ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.task_alt,
                  color: Color.fromARGB(221, 12, 184, 0),
                  size: 36.0,
                ),
                const SizedBox(height: 15),
                Text(
                  text,
                  maxLines: null,
                  softWrap: true,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color.fromARGB(221, 255, 255, 255),
                backgroundColor: const Color.fromRGBO(19, 153, 124, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Закрываем диалог
                Navigator.of(this.context)
                    .pop(true); // Закрываем экран и передаем результат
                print('OkFinal');
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Редактирование раздела',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 10, 84, 255),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading // Показываем прелоудер вместо содержимого, если isLoading == true
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: widget.lesson['className'],
                              decoration: const InputDecoration(
                                labelText: 'Класс',
                                border: OutlineInputBorder(),
                              ),
                              enabled: false,
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: widget.lesson['subjectName'],
                              decoration: const InputDecoration(
                                labelText: 'Предмет',
                                border: OutlineInputBorder(),
                              ),
                              enabled: false,
                              maxLines: null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'Дата',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                        keyboardType: TextInputType.datetime,
                        maxLines: null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child:
                                DropdownButtonFormField<Map<String, dynamic>>(
                              value: _selectedGradeType,
                              items: _gradeTypes
                                  .map((type) =>
                                      DropdownMenuItem<Map<String, dynamic>>(
                                        value: type,
                                        child: Text(type['name']),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGradeType = value;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Тип занятия',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _maxPointController,
                              decoration: const InputDecoration(
                                labelText: 'Максимальный балл',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<Map<String, dynamic>?>(
                        value: _selectedTheme ??
                            _themes.firstWhere(
                              (theme) =>
                                  theme['name'] == widget.lesson['themeName'],
                              // orElse: () =>
                              //     null, // Возвращаем null, если совпадений нет
                            ),
                        items: _themes
                            .map((theme) =>
                                DropdownMenuItem<Map<String, dynamic>?>(
                                  value: theme,
                                  child: Container(
                                    child: Text(
                                      theme['name'],
                                      softWrap: true,
                                      maxLines: null,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTheme = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Тема урока',
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed:
                              _selectedTheme != null ? _saveLesson : null,
                          child: const Text('Сохранить'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate;
    try {
      initialDate = DateFormat('yyyy-MM-dd').parse(_dateController.text);
    } catch (e) {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _cntRatesController.dispose();
    _maxPointController.dispose();
    super.dispose();
  }
}
