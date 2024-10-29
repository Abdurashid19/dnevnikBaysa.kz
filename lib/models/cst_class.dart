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
    this.margin = const EdgeInsets.symmetric(vertical: 8),
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

String formatDate(DateTime date) {
  return DateFormat('dd.MM.yyyy').format(date);
}
