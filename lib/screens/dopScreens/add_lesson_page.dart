import 'package:baysa_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddLessonPage extends StatefulWidget {
  @override
  _AddLessonPageState createState() => _AddLessonPageState();
}

class _AddLessonPageState extends State<AddLessonPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _maxPointsController = TextEditingController();
  final UserService _userService = UserService();

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _gradeTypes = [];
  List<Map<String, dynamic>> _themes = [];

  Map<String, dynamic>? _selectedClass;
  Map<String, dynamic>? _selectedSubject;
  Map<String, dynamic>? _selectedGradeType;
  Map<String, dynamic>? _selectedTheme;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController.text =
        DateFormat('dd.MM.yyyy').format(DateTime.now()); // Default to today
    _fetchClasses();
    _fetchGradeTypes();
  }

  Future<void> _fetchClasses() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid');
    final teacherId = prefs.getInt('userId');
    final schoolYear = prefs.getInt('schoolYear') ?? 2024;

    if (teacherId != null && sid != null) {
      final classes = await _userService.getClassesForAddLesson(
        teacherId,
        sid,
        schoolYear,
        context,
      );
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSubjects(int classId) async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid');
    final teacherId = prefs.getInt('userId');
    final schoolYear = prefs.getInt('schoolYear') ?? 2024;

    if (teacherId != null && sid != null) {
      final subjects = await _userService.getPredmetsForAddLesson(
        teacherId,
        classId,
        sid,
        schoolYear,
        context,
      );
      setState(() {
        _subjects = subjects;
        _selectedSubject = null;
        _themes = []; // Clear themes when fetching new subjects
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGradeTypes() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid');
    final teacherId = prefs.getInt('userId');

    if (teacherId != null && sid != null) {
      final gradeTypes = await _userService.getGradeTypes(
        teacherId,
        sid,
        context,
      );
      setState(() {
        _gradeTypes = gradeTypes;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchThemes(int subjectId, int classId) async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid');
    final schoolYear = prefs.getInt('schoolYear') ?? 2024;
    final teacherId = prefs.getInt('userId');

    if (teacherId != null && sid != null) {
      final themes = await _userService.getThemes(
        subjectId,
        classId,
        schoolYear,
        teacherId,
        sid,
        lessonId: 0,
        context: context,
      );
      setState(() {
        _themes = themes;
        _selectedTheme = null; // Clear selected theme when fetching new themes
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = DateFormat('dd.MM.yyyy').format(pickedDate);
      });
    }
  }

  Future<void> _checkAndSaveLesson() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid');
    final teacherId = prefs.getInt('userId');
    final classId = _selectedClass!['id'];
    final subjectId = _selectedSubject!['id'];
    final gradeType = _selectedGradeType!['id'];

    // Преобразуем дату в нужный формат
    final dateInput = _dateController.text;
    final dateParsed = DateFormat('dd.MM.yyyy').parse(dateInput);
    final dateFormatted = DateFormat('yyyy-MM-dd').format(dateParsed);
    // First API Call to check if there's a duplicate lesson
    final checkDoubleLessonResponse = await _userService.checkDoubleLesson(
      classId: classId,
      date: dateFormatted,
      subjectId: subjectId,
      gradeType: gradeType,
      sid: sid!,
      context: context,
    );

    if (checkDoubleLessonResponse!['retNum'] == 0) {
      // If no duplicate, make the second API call to check with schedule
      final checkWithScheduleResponse = await _userService.checkWithSchedule(
        classId: classId,
        subjectId: subjectId,
        teacherId: teacherId!,
        date: dateFormatted,
        sid: sid,
        context: context,
      );

      if (checkWithScheduleResponse!['retNum'] == 0) {
        // Show dialog if lesson not in schedule
        _showAddLessonConfirmation(checkWithScheduleResponse!['retStr']);
      } else {
        // Handle error case if necessary
        _showErrorDialog('Ошибка при проверке с расписанием');
      }
    } else {
      _showErrorDialog('Урок с такими параметрами уже существует.');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveLesson() async {
    setState(() => _isLoading = true); // Start loader
    try {
      final prefs = await SharedPreferences.getInstance();
      final sid = prefs.getString('sid');
      final teacherId = prefs.getInt('userId');
      final int themeId = _selectedTheme!['id'];
      final int gradeType = _selectedGradeType!['id'];

      final isSaved = await _userService.recLesson(
        recId: 0, // Replace with actual recId if applicable
        classId: _selectedClass!['id'],
        date: _dateController.text,
        subjectId: _selectedSubject!['id'],
        teacherId: teacherId!,
        themeId: themeId,
        maxPoint: int.parse(_maxPointsController.text),
        gradeType: gradeType,
        sid: sid!,
        schoolYear: prefs.getInt('schoolYear') ?? 2024,
        context: context,
      );

      if (isSaved['retNum'] == 0) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            // title: const Text('Успех'),
            content: const Text('Урок успешно сохранен!'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(this.context).pop('success');
                },
                child: const Text('ОК'),
              ),
            ],
          ),
        );
      } else {
        _showErrorDialog(isSaved['retStr'] ?? 'Ошибка при сохранении урока.');
      }
    } catch (e) {
      print('Ошибка при сохранении урока: $e');
      _showErrorDialog('Ошибка при сохранении урока.');
    } finally {
      setState(() => _isLoading = false); // Stop loader
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ошибка'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('ОК'),
            ),
          ],
        );
      },
    );
  }

  void _showAddLessonConfirmation(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Icon(
            Icons.warning,
            size: 50,
            color: Colors.orange,
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveLesson(); // Proceed to save the lesson if confirmed
              },
              child: const Text(
                'Да',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog if "No" is chosen
              },
              child: const Text(
                'Нет',
                style: TextStyle(color: Colors.grey),
              ),
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
        title: const Text('Добавить занятие'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
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
                          controller: _dateController,
                          decoration: InputDecoration(
                            labelText: 'Дата урока',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _selectDate(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedClass,
                          items: _classes.map((classItem) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: classItem,
                              child: Text(classItem['clsName']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedClass = value;
                              _fetchSubjects(value!['id']);
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Класс',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedSubject,
                    items: _subjects.map((subjectItem) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: subjectItem,
                        child: Text(subjectItem['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value;
                        _fetchThemes(value!['id'], _selectedClass!['id']);
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Предмет',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedGradeType,
                          items: _gradeTypes.map((type) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: type,
                              child: Text(type['name']),
                            );
                          }).toList(),
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
                          controller: _maxPointsController,
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
                    value: _selectedTheme,
                    items: _themes
                        .map((theme) => DropdownMenuItem<Map<String, dynamic>?>(
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
                  const SizedBox(height: 10),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _checkAndSaveLesson(); // Initiates the lesson saving process
                      },
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _maxPointsController.dispose();
    super.dispose();
  }
}
