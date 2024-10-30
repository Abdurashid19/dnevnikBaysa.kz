import 'package:baysa_app/models/cst_class.dart';
import 'package:baysa_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClassGradesPage extends StatefulWidget {
  final Map<String, dynamic> lesson;

  const ClassGradesPage({Key? key, required this.lesson}) : super(key: key);

  @override
  _ClassGradesPageState createState() => _ClassGradesPageState();
}

class _ClassGradesPageState extends State<ClassGradesPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _grades = [];
  final UserService _userService = UserService();
  bool _showFullInfo = false;

  @override
  void initState() {
    super.initState();
    _fetchGrades();
  }

  String getQuaterDisplayValue(Map<String, dynamic> grade, String quaterKey) {
    final quaterValue = grade[quaterKey];
    final rateTypeId = grade['rateTypeId'];

    if (quaterValue == -5) {
      return 'Зачет';
    } else if (quaterValue == -2) {
      return 'Незачет';
    } else if (rateTypeId == 5) {
      if (quaterValue == null) {
        return '';
      } else if (quaterValue < 3) {
        return 'Незачет';
      } else {
        return quaterValue.toString();
      }
    } else {
      return quaterValue != null ? quaterValue.toString() : '-';
    }
  }

  void _showWorningDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WarningDialog(
          message: message,
        );
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> grade) {
    TextEditingController _gradeController = TextEditingController(
      text: grade['rate'] != null ? grade['rate'].toString() : '',
    );
    TextEditingController _commentsController = TextEditingController(
      text: grade['comments'] ?? '',
    );
    bool _notPresence =
        grade['notPresence'] == true || grade['notPresence'] == 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Редактирование оценки'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Поле для ввода оценки
                    TextField(
                      controller: _gradeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Оценка',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    // Чекбокс для отсутствия
                    Row(
                      children: [
                        Text(
                          'Отсутствие',
                          style: TextStyle(fontSize: 16),
                        ),
                        Checkbox(
                          value: _notPresence,
                          onChanged: (value) {
                            setState(() {
                              _notPresence = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Поле для комментария
                    TextField(
                      controller: _commentsController,
                      decoration: InputDecoration(
                        labelText: 'Комментарий',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.red, // Красный фон для кнопки "Отмена"
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Закрываем диалог без сохранения
                  },
                  child: Text(
                    'Отмена',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green, // Зеленый фон для кнопки "Сохранить"
                  ),
                  onPressed: () async {
                    // Проверяем условие: если оценка не пустая и установлен флаг отсутствия
                    if (_gradeController.text.isNotEmpty && _notPresence) {
                      // Показываем предупреждение
                      // await showDialog(
                      //   context: context,
                      //   builder: (context) => AlertDialog(
                      //     title: Text('Ошибка'),
                      //     content: Text(
                      //         'Оценка и отсутствие не могут быть установлены одновременно.'),
                      //     actions: [
                      //       TextButton(
                      //         onPressed: () => Navigator.pop(context),
                      //         child: Text('Ок'),
                      //       ),
                      //     ],
                      //   ),
                      // );
                      _showWorningDialog(
                          'Оценка и отсутствие не могут быть установлены одновременно.');
                    } else {
                      Navigator.pop(
                          context); // Закрываем диалог перед сохранением
                      // Сохраняем данные
                      await _saveGrade(
                        grade,
                        _gradeController.text,
                        _notPresence,
                        _commentsController.text,
                      );
                    }
                  },
                  child: Text(
                    'Сохранить',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveGrade(
    Map<String, dynamic> grade,
    String rate,
    bool notPresence,
    String comments,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final sid = prefs.getString('sid');
      final teacherId = prefs.getInt('userId');
      final schoolYear = prefs.getInt('schoolYear') ?? 2024;

      int rateValue = rate.isNotEmpty ? int.parse(rate) : -1;
      int notPresenceValue = notPresence ? 1 : 0;

      // Вызываем сервис для сохранения данных
      final response = await _userService.putRate(
        lessonId: widget.lesson['id'],
        studentId: grade['studentId'],
        rate: rateValue,
        notPresence: notPresenceValue,
        schoolYear: schoolYear,
        userId: teacherId!,
        comments: comments,
        sid: sid!,
        context: context,
      );

      if (response != null && response['rv']['retNum'] == 0) {
        // Успешно, обновляем список оценок
        await _fetchGrades();
      } else {
        // Обработка ошибки
        print('Ошибка при сохранении оценки: ${response!['rv']['retStr']}');
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Ошибка'),
            content: Text('Не удалось сохранить изменения.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Ок'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Ошибка при сохранении оценки: $e');
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Ошибка'),
          content: Text('Произошла ошибка при сохранении.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Ок'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGrades() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final sid = prefs.getString('sid');
      final teacherId = prefs.getInt('userId');
      final schoolYear = prefs.getInt('schoolYear') ?? 2024;

      // Получаем оценки из сервиса
      final response = await _userService.getRates(
        lessonId: widget.lesson['id'],
        teacherId: teacherId!,
        sid: sid!,
        schoolYear: schoolYear,
        context: context,
      );

      if (response!['rv']['retNum'] == 0) {
        setState(() {
          _grades = List<Map<String, dynamic>>.from(response['lst']);
        });
      } else {
        // Обработка ошибки
        print('Ошибка при получении оценок: ${response['rv']['retStr']}');
      }
    } catch (e) {
      print('Ошибка при получении оценок: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getHalfYearDisplayValue(
      Map<String, dynamic> grade, String halfYearKey) {
    final halfYearValue = grade[halfYearKey];
    final rateTypeId = grade['rateTypeId'];

    if (halfYearValue == -5) {
      return 'Зачет';
    } else if (halfYearValue == -2) {
      return 'Незачет';
    } else if (rateTypeId == 5) {
      if (halfYearValue == null) {
        return '';
      } else if (halfYearValue < 3) {
        return 'Незачет';
      } else {
        return halfYearValue.toString();
      }
    } else {
      return halfYearValue != null ? halfYearValue.toString() : '-';
    }
  }

  Widget _buildGradeItem(Map<String, dynamic> grade) {
    return GestureDetector(
      onTap: () => _showEditDialog(grade),
      child: CustomCard(
        child: _showFullInfo ? _buildFullInfo(grade) : _buildShortInfo(grade),
      ),
    );
  }

  Widget _buildShortInfo(Map<String, dynamic> grade) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            grade['studentName'] ?? 'Имя не указано',
            style: const TextStyle(
              // fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            grade['notPresence'] == true
                ? 'нб'
                : (grade['rate'] != null
                    ? grade['rate'].toString()
                    : '-'), // Если есть оценка, показать её, иначе '-'
            style: TextStyle(
              // fontSize: 16,
              color: grade['notPresence'] == true
                  ? Colors.red
                  : Colors.black87, // Цвет текста в зависимости от отсутствия
            ),
          ),
        ],
      ),
      Text('....'),
    ]);
  }

  Widget _buildFullInfo(Map<String, dynamic> grade) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ФИО и оценка на одной линии
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              grade['studentName'] ?? 'Имя не указано',
              style: const TextStyle(
                // fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              grade['notPresence'] == true
                  ? 'нб'
                  : (grade['rate'] != null
                      ? grade['rate'].toString()
                      : '-'), // Если есть оценка, показать её, иначе '-'
              style: TextStyle(
                // fontSize: 16,
                color: grade['notPresence'] == true
                    ? Colors.red
                    : Colors.black87, // Цвет текста в зависимости от отсутствия
              ),
            ),
          ],
        ),

        // Условное отображение квартальных оценок
        if (widget.lesson['quaterColumnVisible'] == true) ...[
          // First Quarter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '1 четв:  ',
                      style: TextStyle(
                          // fontSize: 16,
                          color: Colors.black87),
                    ),
                    TextSpan(
                      text: getQuaterDisplayValue(grade, 'quater1'),
                      style: const TextStyle(
                        // fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                grade['qtr1Calc'] ?? '-',
                // style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          // Second Quarter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '2 четв:  ',
                      style: TextStyle(
                          // fontSize: 16,
                          color: Colors.black87),
                    ),
                    TextSpan(
                      text: getQuaterDisplayValue(grade, 'quater2'),
                      style: const TextStyle(
                        // fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                grade['qtr2Calc'] ?? '-',
                // style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          // Third Quarter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '3 четв:  ',
                      style: TextStyle(
                          // fontSize: 16,
                          color: Colors.black87),
                    ),
                    TextSpan(
                      text: getQuaterDisplayValue(grade, 'quater3'),
                      style: const TextStyle(
                        // fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                grade['qtr3Calc'] ?? '-',
                // style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          // Fourth Quarter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '4 четв:  ',
                      style: TextStyle(
                          // fontSize: 16,
                          color: Colors.black87),
                    ),
                    TextSpan(
                      text: getQuaterDisplayValue(grade, 'quater4'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                grade['qtr4Calc'] ?? '-',
                // style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          if (grade['comments'] != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Комментарий:',
                  // style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      grade['comments'] ?? '-',
                      // style: const TextStyle(fontSize: 16),
                      softWrap: true,
                      maxLines: null,
                      textAlign: TextAlign
                          .right, // Выравнивание текста по правому краю
                    ),
                  ),
                ),
              ],
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Годовая:',
                // style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    grade['yearCalc'] ?? '-',
                    // style: const TextStyle(fontSize: 16),
                    softWrap: true,
                    maxLines: null,
                    textAlign:
                        TextAlign.right, // Выравнивание текста по правому краю
                  ),
                ),
              ),
            ],
          ),
        ],

        // Условное отображение полугодовых оценок
        if (widget.lesson['halfYearColumnVisible'] == true) ...[
          // Полугодие 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Полугодие 1:  ',
                      style: TextStyle(
                          // fontSize: 16,
                          color: Colors.black87),
                    ),
                    TextSpan(
                      text: getHalfYearDisplayValue(grade, 'halfYear1'),
                      style: const TextStyle(
                        // fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                grade['hlf1Calc'] ?? '-',
                // style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          // Полугодие 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Полугодие 2:  ',
                      style: TextStyle(
                          // fontSize: 16,
                          color: Colors.black87),
                    ),
                    TextSpan(
                      text: getHalfYearDisplayValue(grade, 'halfYear2'),
                      style: const TextStyle(
                        // fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                grade['hlf2Calc'] ?? '-',
                // style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          if (grade['comments'] != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Комментарий:',
                  // style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      grade['comments'] ?? '-',
                      // style: const TextStyle(fontSize: 16),
                      softWrap: true,
                      maxLines: null,
                      textAlign: TextAlign
                          .right, // Выравнивание текста по правому краю
                    ),
                  ),
                ),
              ],
            ),

          // Годовая оценка
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Годовая:',
                // style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    grade['yearCalc'] ?? '-',
                    // style: const TextStyle(fontSize: 16),
                    softWrap: true,
                    maxLines: null,
                    textAlign:
                        TextAlign.right, // Выравнивание текста по правому краю
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  // Widget _buildGradeItem(Map<String, dynamic> grade) {
  //   return GestureDetector(
  //     onTap: () => _showEditDialog(grade),
  //     child: CustomCard(
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // ФИО и оценка на одной линии
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 grade['studentName'] ?? 'Имя не указано',
  //                 style: const TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //               Text(
  //                 grade['notPresence'] == true
  //                     ? 'нб'
  //                     : (grade['rate'] != null
  //                         ? grade['rate'].toString()
  //                         : '-'), // Если есть оценка, показать её, иначе '-'
  //                 style: TextStyle(
  //                   fontSize: 16,
  //                   color: grade['notPresence'] == true
  //                       ? Colors.red
  //                       : Colors
  //                           .black87, // Цвет текста в зависимости от отсутствия
  //                 ),
  //               ),
  //             ],
  //           ),

  //           // Условное отображение квартальных оценок
  //           if (widget.lesson['quaterColumnVisible'] == true) ...[
  //             // First Quarter
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 RichText(
  //                   text: TextSpan(
  //                     children: [
  //                       const TextSpan(
  //                         text: '1 четв:  ',
  //                         style: TextStyle(fontSize: 16, color: Colors.black87),
  //                       ),
  //                       TextSpan(
  //                         text: getQuaterDisplayValue(grade, 'quater1'),
  //                         style: const TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.black87,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 Text(
  //                   grade['qtr1Calc'] ?? '-',
  //                   style: const TextStyle(fontSize: 16),
  //                 ),
  //               ],
  //             ),
  //             // Second Quarter
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 RichText(
  //                   text: TextSpan(
  //                     children: [
  //                       const TextSpan(
  //                         text: '2 четв:  ',
  //                         style: TextStyle(fontSize: 16, color: Colors.black87),
  //                       ),
  //                       TextSpan(
  //                         text: getQuaterDisplayValue(grade, 'quater2'),
  //                         style: const TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.black87,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 Text(
  //                   grade['qtr2Calc'] ?? '-',
  //                   style: const TextStyle(fontSize: 16),
  //                 ),
  //               ],
  //             ),
  //             // Third Quarter
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 RichText(
  //                   text: TextSpan(
  //                     children: [
  //                       const TextSpan(
  //                         text: '3 четв:  ',
  //                         style: TextStyle(fontSize: 16, color: Colors.black87),
  //                       ),
  //                       TextSpan(
  //                         text: getQuaterDisplayValue(grade, 'quater3'),
  //                         style: const TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.black87,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 Text(
  //                   grade['qtr3Calc'] ?? '-',
  //                   style: const TextStyle(fontSize: 16),
  //                 ),
  //               ],
  //             ),
  //             // Fourth Quarter
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 RichText(
  //                   text: TextSpan(
  //                     children: [
  //                       const TextSpan(
  //                         text: '4 четв:  ',
  //                         style: TextStyle(fontSize: 16, color: Colors.black87),
  //                       ),
  //                       TextSpan(
  //                         text: getQuaterDisplayValue(grade, 'quater4'),
  //                         style: const TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.black87,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 Text(
  //                   grade['qtr4Calc'] ?? '-',
  //                   style: const TextStyle(fontSize: 16),
  //                 ),
  //               ],
  //             ),
  //             if (grade['comments'] != null)
  //               Row(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     'Комментарий:',
  //                     style: TextStyle(fontSize: 16),
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Expanded(
  //                     child: Align(
  //                       alignment: Alignment.centerRight,
  //                       child: Text(
  //                         grade['comments'] ?? '-',
  //                         style: const TextStyle(fontSize: 16),
  //                         softWrap: true,
  //                         maxLines: null,
  //                         textAlign: TextAlign
  //                             .right, // Выравнивание текста по правому краю
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),

  //             Row(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Text(
  //                   'Годовая:',
  //                   style: TextStyle(fontSize: 16),
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Expanded(
  //                   child: Align(
  //                     alignment: Alignment.centerRight,
  //                     child: Text(
  //                       grade['yearCalc'] ?? '-',
  //                       style: const TextStyle(fontSize: 16),
  //                       softWrap: true,
  //                       maxLines: null,
  //                       textAlign: TextAlign
  //                           .right, // Выравнивание текста по правому краю
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],

  //           // Условное отображение полугодовых оценок
  //           if (widget.lesson['halfYearColumnVisible'] == true) ...[
  //             // Полугодие 1
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 RichText(
  //                   text: TextSpan(
  //                     children: [
  //                       const TextSpan(
  //                         text: 'Полугодие 1:  ',
  //                         style: TextStyle(fontSize: 16, color: Colors.black87),
  //                       ),
  //                       TextSpan(
  //                         text: getHalfYearDisplayValue(grade, 'halfYear1'),
  //                         style: const TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.black87,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 Text(
  //                   grade['hlf1Calc'] ?? '-',
  //                   style: const TextStyle(fontSize: 16),
  //                 ),
  //               ],
  //             ),
  //             // Полугодие 2
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 RichText(
  //                   text: TextSpan(
  //                     children: [
  //                       const TextSpan(
  //                         text: 'Полугодие 2:  ',
  //                         style: TextStyle(fontSize: 16, color: Colors.black87),
  //                       ),
  //                       TextSpan(
  //                         text: getHalfYearDisplayValue(grade, 'halfYear2'),
  //                         style: const TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.black87,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 Text(
  //                   grade['hlf2Calc'] ?? '-',
  //                   style: const TextStyle(fontSize: 16),
  //                 ),
  //               ],
  //             ),
  //             if (grade['comments'] != null)
  //               Row(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     'Комментарий:',
  //                     style: TextStyle(fontSize: 16),
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Expanded(
  //                     child: Align(
  //                       alignment: Alignment.centerRight,
  //                       child: Text(
  //                         grade['comments'] ?? '-',
  //                         style: const TextStyle(fontSize: 16),
  //                         softWrap: true,
  //                         maxLines: null,
  //                         textAlign: TextAlign
  //                             .right, // Выравнивание текста по правому краю
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),

  //             // Годовая оценка
  //             Row(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Text(
  //                   'Годовая:',
  //                   style: TextStyle(fontSize: 16),
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Expanded(
  //                   child: Align(
  //                     alignment: Alignment.centerRight,
  //                     child: Text(
  //                       grade['yearCalc'] ?? '-',
  //                       style: const TextStyle(fontSize: 16),
  //                       softWrap: true,
  //                       maxLines: null,
  //                       textAlign: TextAlign
  //                           .right, // Выравнивание текста по правому краю
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cst.backgroundApp,
      appBar: AppBar(
        title: Text('Оценки класса'),
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        backgroundColor: Cst.backgroundAppBar,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _grades.isEmpty
              ? Center(child: Text('Оценки отсутствуют'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(5.0),
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Дата урока в формате dd.MM.yyyy
                            Text(
                              formatDateString(widget.lesson[
                                  'date2']), // Применяем функцию форматирования
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),

                            Text(
                              'Макс.балл: ${widget.lesson['maxPoint']}',
                              style: TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),
                        // Строка с классом и предметом
                        Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.lesson['className']}',
                              style: TextStyle(fontSize: 16),
                              overflow: TextOverflow
                                  .ellipsis, // Сокращение текста, если не помещается
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.lesson['subjectName']}',
                              style: TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),

                        // Тема урока
                        Text(
                          '${widget.lesson['themeName']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Показать подробную информацию',
                              style: TextStyle(fontSize: 13),
                            ),
                            Checkbox(
                              value: _showFullInfo,
                              onChanged: (value) {
                                setState(() {
                                  _showFullInfo = value ?? true;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Список оценок
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _grades.length,
                          itemBuilder: (context, index) {
                            return _buildGradeItem(_grades[index]);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
