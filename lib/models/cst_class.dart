import 'package:flutter/material.dart';

class Cst {
  static Color accent_color = marketColor('#00C003');
  static Color primary_color = Color.fromRGBO(233, 236, 239, 1.0);
  static Color buy_btn_color =
      Colors.blueAccent; // Например, используем готовый цвет

  static Color background = Color(0xFF4d4d4d);
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
