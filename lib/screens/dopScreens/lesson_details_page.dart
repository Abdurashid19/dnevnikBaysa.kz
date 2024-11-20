import 'dart:convert';
import 'package:baysa_app/models/cst_class.dart';
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
    String formattedDate = DateFormat('dd.MM.yyyy').format(parsedDate);

    _dateController = TextEditingController(text: formattedDate);
    _cntRatesController =
        TextEditingController(text: widget.lesson['cntRates'].toString());
    _maxPointController =
        TextEditingController(text: widget.lesson['maxPoint'].toString());
    // _selectedTheme = {
    //   'id': widget.lesson['themeId'],
    //   'name': widget.lesson['themeName'],
    // };
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
        _selectedTheme = _themes.firstWhere(
          (theme) => theme['id'] == widget.lesson['themeId'],
        );
      });
    } catch (e) {
      print('Ошибка при загрузке тем: $e');
    } finally {
      setState(() => isLoading = false); // Отключаем прелоудер
    }
  }

  Future<void> _saveLesson() async {
    if (_selectedTheme != null) {
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
    } else {}
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
      backgroundColor: Cst.backgroundApp,
      appBar: AppBar(
        title: Text(
          'Редактирование урока',
          style: TextStyle(fontSize: Cst.appBarTextSize, color: Cst.color),
        ),
        scrolledUnderElevation: 0.0,
        centerTitle: true,
        backgroundColor: Cst.backgroundAppBar,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading // Показываем прелоудер вместо содержимого, если isLoading == true
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(5.0),
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppTextFormField(
                                controller: TextEditingController(
                                    text: widget.lesson['className']),
                                labelText: 'Класс',
                                enabled: false,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppTextFormField(
                                controller: TextEditingController(
                                    text: widget.lesson['subjectName']),
                                labelText: 'Предмет',
                                enabled: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        AppTextFormField(
                          controller: _dateController,
                          labelText: 'Дата',
                          keyboardType: TextInputType.datetime,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () =>
                                _selectDate(context, _dateController),
                          ),
                          onTap: () {
                            _selectDate(context,
                                _dateController); // Optional: Trigger date picker on tap as well
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: AppDropdownField<Map<String, dynamic>>(
                                value: _selectedGradeType,
                                items: _gradeTypes,
                                itemLabelBuilder: (type) =>
                                    type['name'], // Builds the display text
                                labelText: 'Тип занятия',
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGradeType = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppTextFormField(
                                controller: _maxPointController,
                                labelText: 'Максимальный балл',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        AppDropdownField<Map<String, dynamic>?>(
                          value: _selectedTheme,
                          items: _themes,
                          itemLabelBuilder: (theme) =>
                              theme!['name'], // Builds the display text
                          labelText: 'Тема урока',
                          onChanged: (value) {
                            setState(() {
                              _selectedTheme = value;
                            });
                          },
                        ),
                        // const SizedBox(height: 20),
                        Center(
                          child: CustomElevatedButton(
                            onPressed: _saveLesson,
                            text: 'Сохранить',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate;
    try {
      initialDate = DateFormat('dd.MM.yyyy').parse(controller.text);
    } catch (e) {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      locale: const Locale('ru', 'RU'),
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        controller.text = DateFormat('dd.MM.yyyy').format(picked);
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
