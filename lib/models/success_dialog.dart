import 'package:baysa_app/models/cst_class.dart';
import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  final String text;
  final VoidCallback onClose;

  const SuccessDialog({Key? key, required this.text, required this.onClose})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(''),
      content: Row(
        children: [
          Icon(
            Icons.task_alt,
            color: Cst.accent_color,
            size: 36.0,
          ),
          SizedBox(
            width: 12,
          ),
          Flexible(child: Text('${text}', maxLines: 8, softWrap: true)),
        ],
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
          onPressed: onClose,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
