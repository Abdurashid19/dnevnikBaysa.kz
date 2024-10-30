import 'package:baysa_app/models/cst_class.dart';
import 'package:baysa_app/models/error_dialog.dart';
import 'package:baysa_app/models/success_dialog.dart';
import 'package:baysa_app/screens/dopScreens/add_lesson_page.dart';
import 'package:baysa_app/screens/dopScreens/class_grades_page.dart';
import 'package:baysa_app/screens/dopScreens/lesson_details_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ListActivities extends StatefulWidget {
  const ListActivities({Key? key}) : super(key: key);

  @override
  _ListActivitiesState createState() => _ListActivitiesState();
}

class _ListActivitiesState extends State<ListActivities> {
  final UserService _userService = UserService();

  // Контроллеры для полей даты
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();

  // Переменные для хранения данных
  String? _fio;
  String? _sid;
  int? _schoolYear;
  int? _teacherId;

  List<String> _classes = [];
  String? _selectedClass;
  Map<String, int> _classMap =
      {}; // Для хранения соответствия между именами и ID классов

  List<String> _subjects = [];
  String? _selectedSubject;
  Map<String, int> _subjectMap =
      {}; // Для хранения соответствия между именами и ID предметов

  bool _isLoading = true;
  List<Map<String, dynamic>> _lessons = [];

  bool _isLoadingLessons = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Метод для загрузки начальных данных
  Future<void> _loadInitialData() async {
    try {
      // Получаем данные пользователя из SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _fio = prefs.getString('userFio');
      _sid = prefs.getString('sid');
      _schoolYear = prefs.getInt('schoolYear') ?? 2024;
      _teacherId = prefs.getInt('userId');

      // Если данных нет, необходимо их загрузить
      if (_fio == null || _sid == null || _teacherId == null) {
        final userEmail = prefs.getString('userEmail') ?? '';
        await _userService.checkUserMs(userEmail, context);

        // Повторно получаем данные после загрузки
        _fio = prefs.getString('userFio');
        _sid = prefs.getString('sid');
        _schoolYear = prefs.getInt('schoolYear') ?? 2024;
        _teacherId = prefs.getInt('userId');
      }

      // Получаем даты начала и конца периода
      final dates =
          await _userService.getFirstAndLastDate(_schoolYear!, context);
      _startDateController.text = _formatDate(dates[0]);
      _endDateController.text = _formatDate(dates[1]);

      // Получаем список классов
      final classData = await _userService.getClassesForTeacher(
          _teacherId!, _sid!, _schoolYear!, context);

      // Заполняем _classes и _classMap
      _classes = [];
      _classMap = {};
      for (var cls in classData) {
        _classes.add(cls['clsName']);
        _classMap[cls['clsName']] = cls['id'];
      }

      // // Устанавливаем выбранный класс по умолчанию
      // _selectedClass = _classes.isNotEmpty ? _classes[0] : null;

      // // Загружаем предметы для выбранного класса
      // if (_selectedClass != null) {
      //   await _loadSubjects(_classMap[_selectedClass]!);
      // }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки данных: $e');
    }
  }

  // Метод для загрузки предметов по ID класса
  Future<void> _loadSubjects(int classId) async {
    final subjectData = await _userService.getAllSubjectsForClass(
        classId, _teacherId!, _sid!, _schoolYear!, context);

    // Заполняем _subjects и _subjectMap
    _subjects = [];
    _subjectMap = {};
    for (var subj in subjectData) {
      _subjects.add(subj['name']);
      _subjectMap[subj['name']] = subj['id'];
    }

    // Устанавливаем выбранный предмет по умолчанию
    setState(() {
      _selectedSubject =
          _subjects.isNotEmpty && _subjects.length == 1 ? _subjects[0] : null;
    });
  }

  // Метод для форматирования даты
  String _formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd.MM.yyyy').format(parsedDate);
  }

  Future<void> _updateLessons() async {
    setState(() {
      _isLoadingLessons = true; // Начинаем загрузку
    });

    try {
      final classId = _classMap[_selectedClass]!;
      final subjectId = _subjectMap[_selectedSubject]!;

      final startDate = DateFormat('EEE MMM dd yyyy')
          .format(DateFormat('dd.MM.yyyy').parse(_startDateController.text));
      final endDate = DateFormat('EEE MMM dd yyyy')
          .format(DateFormat('dd.MM.yyyy').parse(_endDateController.text));

      final lessons = await _userService.getLessons(
        teacherId: _teacherId!,
        date1: startDate,
        date2: endDate,
        classId: classId,
        sid: _sid!,
        schoolYear: _schoolYear!,
        subjectId: subjectId,
        context: context,
      );

      setState(() {
        _lessons = lessons;
      });
    } catch (e) {
      print('Ошибка при обновлении данных: $e');
    } finally {
      setState(() {
        _isLoadingLessons = false; // Завершаем загрузку
      });
    }
  }

  // Метод для выхода и очистки данных
  Future<void> _logout() async {
    // Очищаем данные в SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Очищаем кэш
    await DefaultCacheManager().emptyCache();

    // Выходим из Firebase
    await FirebaseAuth.instance.signOut();

    // Переход на экран входа после небольшой задержки
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    });
  }

  // Открытие диалога выбора даты
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Список занятий',
        ),
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        backgroundColor: Cst.backgroundAppBar,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      // Устанавливаем цвет фона Scaffold
      backgroundColor: Cst.backgroundApp,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(5.0),
              child: CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ФИО преподавателя
                    Text(
                      '$_fio',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // Поля для выбора дат с возможностью изменения
                    Row(
                      children: [
                        Expanded(
                            child: _buildDateField(
                                'Начало периода', _startDateController)),
                        const SizedBox(width: 16), // Отступ между полями
                        Expanded(
                            child: _buildDateField(
                                'Конец периода', _endDateController)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Выпадающие меню для класса и предмета
                    _buildClassDropdown(),
                    const SizedBox(height: 10),
                    _buildSubjectDropdown(),
                    const SizedBox(height: 20),

                    // Кнопка обновить
                    if (_selectedClass != null && _selectedSubject != null)
                      Center(
                        child: CustomElevatedButton(
                          onPressed: _updateLessons,
                          text: 'Обновить',
                        ),
                      ),

                    const SizedBox(height: 20),
                    _buildLessonsTable(),
                  ],
                ),
              ),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddLessonPage()),
          );

          if (result == 'success') {
            _updateLessons();
          }
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildLessonsTable() {
    if (_isLoadingLessons) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lessons.isEmpty) {
      return const Center(child: Text('Нет данных для отображения.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_selectedClass    $_selectedSubject',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _lessons.length,
          itemBuilder: (context, index) {
            final lesson = _lessons[index];

            // Форматируем дату
            String formattedDate = '';
            try {
              DateTime parsedDate = DateTime.parse(lesson['date2']);
              formattedDate = DateFormat('dd.MM.yyyy').format(parsedDate);
            } catch (e) {
              formattedDate = lesson['date2'];
            }

            // Проверяем тип урока: СОР, СОЧ или Экзамен
            bool isSor = [11, 12, 13, 14].contains(lesson['gradeId']);
            bool isSoch = lesson['gradeId'] == 15;
            bool isExam = lesson['gradeId'] == 7;
            bool error = lesson['sorWithoutLesson'] == 1 &&
                !(lesson['gradeId'] == 1 || lesson['maxPoint'] == 0);
            // Логика для изменения цвета карточки
            Color cardColor = Colors.white; // По умолчанию белый цвет
            if (error) {
              cardColor = Colors.red.shade300;
            } else if (isSor) {
              cardColor = Colors.green.shade300;
            } else if (isSoch) {
              cardColor = const Color.fromARGB(255, 229, 151, 115);
            } else if (isExam) {
              cardColor = Colors.lightBlue.shade300;
            }
            // Логика для подсветки карточки, если количество студентов, не получивших оценку, больше нуля
            // if ((lesson['cntStudents'] - lesson['cntRates'] > 0) &&
            //     !(lesson['gradeId'] == 1 || lesson['maxPoint'] == 0)) {
            //   cardColor = Colors.red.shade300;
            // }

            return GestureDetector(
              onTap: () {
                _showActionDialog(
                    context, lesson); // Показать диалог выбора действия
              },
              child: CustomCard(
                backgroundColor: cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Первая строка: Дата, Период и Оценки
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${lesson['typePeriod']}',
                        ),
                        const SizedBox(width: 5),
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Оценки: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextSpan(
                                text: '${lesson['cntRates']}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                              if (isSor || isSoch || isExam)
                                TextSpan(
                                  text: '/${lesson['cntStudents']}',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Макс: ',
                                style: TextStyle(
                                  color: Colors.black87,
                                ),
                              ),
                              TextSpan(
                                text: '${lesson['maxPoint']}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Вторая строка: Тема урока
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: lesson['themeName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_teacherId != lesson['teacherId'])
                      const SizedBox(height: 8),
                    if (_teacherId != lesson['teacherId'])
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: lesson['teacherName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

// Метод для показа диалога с выбором действия
  void _showActionDialog(
      BuildContext context, Map<String, dynamic> lesson) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Получаем высоту экрана
        final screenHeight = MediaQuery.of(context).size.height;

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Скругление углов
          ),
          child: Container(
            height: screenHeight * 0.3, // Устанавливаем высоту в 30% от экрана
            padding: const EdgeInsets.all(16.0), // Внутренние отступы
            child: Stack(
              children: [
                // Кнопка закрытия в верхнем правом углу
                Positioned(
                  right: -10.0,
                  top: -10.0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Закрываем диалог
                    },
                  ),
                ),
                // Основное содержимое
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Заголовок диалога
                    Text(
                      'Выберите действие',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20, // Увеличиваем размер шрифта
                        fontWeight: FontWeight.bold, // Делаем текст жирным
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Кнопки действий
                    ButtonBar(
                      alignment: MainAxisAlignment.center,
                      buttonPadding:
                          const EdgeInsets.symmetric(horizontal: 8.0),
                      children: <Widget>[
                        SizedBox(
                          width: 160, // Задаем одинаковую ширину для кнопок
                          child: OutlinedButton(
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final _teacherId = prefs.getInt('userId');

                              if (_teacherId == lesson['teacherId']) {
                                // Если учитель совпадает, открыть экран редактирования
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        LessonDetailsPage(lesson: lesson),
                                  ),
                                );

                                if (result == 'success') {
                                  Navigator.of(context)
                                      .pop(); // Закрываем диалог
                                  _updateLessons();
                                }
                              } else {
                                _showErrorDialog(
                                    'Занятие было введено другим учителем');
                              }
                            },
                            child: const Text('Редактировать'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white, // Белый фон кнопки
                              foregroundColor: Colors.black, // Цвет текста
                              side: const BorderSide(
                                color: Color(0xFFDCE1E6), // Цвет обводки
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    10.0), // Скругление углов
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 160,
                          child: OutlinedButton(
                            onPressed: () async {
                              // Переходим на экран с оценками
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ClassGradesPage(lesson: lesson),
                                ),
                              );

                              if (result == 'updated') {
                                // Обновляем данные, если необходимо
                                _updateLessons(); // Например, метод обновления данных в вашем виджете
                              } else {
                                Navigator.of(context).pop(); // Закрываем диалог
                                _updateLessons();
                              }
                            },
                            child: const Text('Оценки'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white, // Белый фон кнопки
                              foregroundColor: Colors.black, // Цвет текста
                              side: const BorderSide(
                                color: Color(0xFFDCE1E6), // Цвет обводки
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    10.0), // Скругление углов
                              ),
                            ),
                          ),
                        ),
                      ],
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

  // Виджет для поля даты
  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '$label',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context, controller),
            ),
          ),
          keyboardType: TextInputType.datetime,
        ),
      ],
    );
  }

  // Виджет для выпадающего списка классов
  Widget _buildClassDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Container(
          child: DropdownButtonFormField<String>(
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              labelText: 'Класс',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 10.0,
              ),
            ),
            isDense: true,
            isExpanded: true,
            items: _classes.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            value: _selectedClass != null && _selectedClass!.isNotEmpty
                ? _selectedClass
                : null,
            onChanged: (String? newValue) async {
              // Загружаем предметы для выбранного класса
              await _loadSubjects(_classMap[newValue]!);
              setState(() {
                _selectedClass = newValue!;
                _lessons.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WarningDialog(
          message: message,
        );
      },
    );
  }

// Виджет для выпадающего списка предметов
  Widget _buildSubjectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Container(
          child: DropdownButtonFormField<String>(
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              labelText: 'Предмет',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 10.0,
              ),
            ),
            isDense: true,
            isExpanded: true,
            items: _subjects.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            value: _selectedSubject,
            onChanged: (String? newValue) {
              setState(() {
                _selectedSubject = newValue!;
              });
            },
          ),
        ),
      ],
    );
  }
}
