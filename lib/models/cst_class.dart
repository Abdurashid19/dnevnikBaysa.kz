import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Cst {
  static Color accent_color = marketColor('#00C003');
  static Color primary_color = Color.fromRGBO(233, 236, 239, 1.0);
  static Color buy_btn_color =
      Colors.blueAccent; // Например, используем готовый цвет

  static Color background = Color(0xFF4d4d4d);
  static Color backgroundAppBar = Color(0xFFffffff);
  static Color backgroundCard = Color(0xFFffffff);
  static Color backgroundApp = Color(0xFFEBEDF0);
  static Color color = Color(0xFF4d4d4d);

  /// конвертирует цвет
  static Color marketColor(String colors2) {
    try {
      Color color1 = HexColor(colors2);
      return color1;
    } catch (_) {
      return Color(0xFF4d4d4d);
    }
  }
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF" + hexColor;
      }
      return int.parse(hexColor, radix: 16);
    } catch (e) {
      print("Invalid hex color format: $hexColor");
      // Возвращаем черный цвет в случае ошибки
      return int.parse("FF000000", radix: 16);
    }
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color borderColor;
  final double elevation;
  final Color backgroundColor;

  const CustomCard({
    Key? key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(vertical: 3),
    this.padding = const EdgeInsets.all(12.0),
    this.borderRadius = 10.0,
    this.borderColor = const Color(0xFFDCE1E6),
    this.elevation = 0.0,
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      color: backgroundColor,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final Color backgroundColor;
  final Color foregroundColor;

  const CustomElevatedButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.padding = const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
    this.fontSize = 18,
    this.backgroundColor = Colors.blue,
    this.foregroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
      style: ElevatedButton.styleFrom(
        padding: padding,
        textStyle: TextStyle(fontSize: fontSize),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
    );
  }
}

class WarningDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;

  const WarningDialog({
    Key? key,
    required this.message,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Icon(
        Icons.warning,
        size: 50,
        color: Colors.orange,
      ),
      content: Text(
        message,
        textAlign: TextAlign.center, // Центрируем текст
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onClose != null) {
              onClose!();
            }
          },
          child: const Text('ОК'),
        ),
      ],
    );
  }
}

class DropdownTextField extends StatefulWidget {
  final List<String> items;
  final String labelText;
  final Function(String) onChanged;

  const DropdownTextField({
    Key? key,
    required this.items,
    required this.labelText,
    required this.onChanged,
  }) : super(key: key);

  @override
  _DropdownTextFieldState createState() => _DropdownTextFieldState();
}

class _DropdownTextFieldState extends State<DropdownTextField> {
  final TextEditingController _controller = TextEditingController();
  bool _isDropdownOpened = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpened = !_isDropdownOpened;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleDropdown,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: widget.labelText,
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            readOnly: true,
          ),
          if (_isDropdownOpened)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: ListView(
                shrinkWrap: true,
                children: widget.items.map((item) {
                  return ListTile(
                    title: Text(item),
                    onTap: () {
                      setState(() {
                        _controller.text = item;
                        _isDropdownOpened = false;
                      });
                      widget.onChanged(item);
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class CustomInputDecoration {
  static InputDecoration getDecoration({
    required String labelText,
    bool isSpecialClass = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: const Color.fromARGB(255, 159, 163, 166),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: const Color(0xFFDCE1E6),
        ),
      ),
      border: const OutlineInputBorder(),
    );
  }
}

String formatDate(DateTime date) {
  return DateFormat('dd.MM.yyyy').format(date);
}

String formatDateString(String date) {
  final parsedDate = DateTime.parse(date);
  return DateFormat('dd.MM.yyyy').format(parsedDate);
}
