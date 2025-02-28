import 'package:flutter/material.dart';

class MainButton extends StatelessWidget {
  const MainButton({
    super.key,
    required this.displayText,
    required this.onPressedFunc,
    required this.fontSize,
  });

  final String displayText;
  final VoidCallback onPressedFunc;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressedFunc,
      style: ButtonStyle(
        padding: WidgetStateProperty.all<EdgeInsets>(
          const EdgeInsets.fromLTRB(30, 10, 30, 10),
        ),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          side: BorderSide(
            color: Colors.white24,
            width: 2,
            style: BorderStyle.solid
          ),
          borderRadius: BorderRadius.circular(50))
        ),
        backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surface),
        minimumSize: WidgetStateProperty.all(Size(150, 50))
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold
        )
      )
    );
  }
}