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
  Map<String, int> _classMap = {};

  List<String> _subjects = [];
  String? _selectedSubject;
  Map<String, int> _subjectMap = {};

  bool _isLoading = true;
  List<Map<String, dynamic>> _lessons = [];

  bool _isLoadingLessons = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // Метод инициализации
  Future<void> _initialize() async {
    await _loadInitialData();
    await _loadSavedParameters();
    if (_selectedClass != null) {
      await _loadSubjects(_classMap[_selectedClass]!);
    }
    if (_selectedSubject != null &&
        _startDateController.text.isNotEmpty &&
        _endDateController.text.isNotEmpty) {
      await _updateLessons();
    }
    setState(() {
      _isLoading = false;
    });
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
    } catch (e) {
      print('Ошибка загрузки данных: $e');
    }
  }

  // Метод для загрузки сохраненных параметров
  Future<void> _loadSavedParameters() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStartDate = prefs.getString('startDate');
    final savedEndDate = prefs.getString('endDate');
    final savedClass = prefs.getString('selectedClass');
    final savedSubject = prefs.getString('selectedSubject');

    if (savedStartDate != null &&
        savedEndDate != null &&
        savedClass != null &&
        savedSubject != null) {
      setState(() {
        _startDateController.text = savedStartDate;
        _endDateController.text = savedEndDate;
        _selectedClass = savedClass;
        _selectedSubject = savedSubject;
      });
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
    if (!_subjects.contains(_selectedSubject)) {
      setState(() {
        _selectedSubject = _subjects.isNotEmpty ? _subjects[0] : null;
      });
    }
  }

  // Метод для форматирования даты
  String _formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd.MM.yyyy').format(parsedDate);
  }

  Future<void> _updateLessons() async {
    // Сохраняем выбранные параметры
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('startDate', _startDateController.text);
    await prefs.setString('endDate', _endDateController.text);
    await prefs.setString('selectedClass', _selectedClass!);
    await prefs.setString('selectedSubject', _selectedSubject!);

    setState(() {
      _isLoadingLessons = true; // Начинаем загрузку
    });

    try {
      final classId = _classMap[_selectedClass]!;
      final subjectId = _subjectMap[_selectedSubject]!;

      final startDate = DateFormat('EEE MMM dd yyyy', 'en_US')
          .format(DateFormat('dd.MM.yyyy').parse(_startDateController.text));
      final endDate = DateFormat('EEE MMM dd yyyy', 'en_US')
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
      backgroundColor: Cst.backgroundApp,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(5.0),
              child: CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_fio',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _buildDateField(
                                'Начало периода', _startDateController)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildDateField(
                                'Конец периода', _endDateController)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildClassDropdown(),
                    const SizedBox(height: 10),
                    _buildSubjectDropdown(),
                    const SizedBox(height: 20),
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

            String formattedDate = '';
            try {
              DateTime parsedDate = DateTime.parse(lesson['date2']);
              formattedDate = DateFormat('dd.MM.yyyy').format(parsedDate);
            } catch (e) {
              formattedDate = lesson['date2'];
            }

            bool isSor = [11, 12, 13, 14].contains(lesson['gradeId']);
            bool isSoch = lesson['gradeId'] == 15;
            bool isExam = lesson['gradeId'] == 7;
            bool error = lesson['sorWithoutLesson'] == 1 &&
                !(lesson['gradeId'] == 1 || lesson['maxPoint'] == 0);

            Color cardColor = Colors.white;
            if (error) {
              cardColor = Colors.red.shade300;
            } else if (isSor) {
              cardColor = Colors.green.shade300;
            } else if (isSoch) {
              cardColor = const Color.fromARGB(255, 229, 151, 115);
            } else if (isExam) {
              cardColor = Colors.lightBlue.shade300;
            }

            return GestureDetector(
              onTap: () {
                _showActionDialog(context, lesson);
              },
              child: CustomCard(
                backgroundColor: cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

  void _showActionDialog(
      BuildContext context, Map<String, dynamic> lesson) async {
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
            height: screenHeight * 0.3,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Выберите действие',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ButtonBar(
                      alignment: MainAxisAlignment.center,
                      buttonPadding:
                          const EdgeInsets.symmetric(horizontal: 8.0),
                      children: <Widget>[
                        SizedBox(
                          width: 160,
                          child: OutlinedButton(
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final _teacherId = prefs.getInt('userId');

                              if (_teacherId == lesson['teacherId']) {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        LessonDetailsPage(lesson: lesson),
                                  ),
                                );

                                if (result == 'success') {
                                  Navigator.of(context).pop();
                                  _updateLessons();
                                }
                              } else {
                                _showErrorDialog(
                                    'Занятие было введено другим учителем');
                              }
                            },
                            child: const Text('Редактировать'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              side: const BorderSide(
                                color: Color(0xFFDCE1E6),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 160,
                          child: OutlinedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ClassGradesPage(lesson: lesson),
                                ),
                              );

                              if (result == 'updated') {
                                _updateLessons();
                              } else {
                                Navigator.of(context).pop();
                                _updateLessons();
                              }
                            },
                            child: const Text('Оценки'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              side: const BorderSide(
                                color: Color(0xFFDCE1E6),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
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
              await _loadSubjects(_classMap[newValue]!);
              setState(() {
                _selectedClass = newValue!;
                _selectedSubject = null;
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
