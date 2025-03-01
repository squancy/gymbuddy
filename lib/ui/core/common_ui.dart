import 'package:flutter/material.dart';
import 'package:moye/moye.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gym_buddy/consts/common_consts.dart';

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

class BottomSheetContent extends StatelessWidget {
  const BottomSheetContent({
    required selectFromSource,
    super.key
  }) :
  _selectFromSource = selectFromSource;

  final Function _selectFromSource;

  void showOptions(BuildContext context) {
    BottomSheetUtils.showBottomSheet(
      context: context,
      borderRadius: BorderRadius.circular(16),
      config: WrapBottomSheetConfig(
        builder: (context, controller) {
          return BottomSheetContent(
            selectFromSource: _selectFromSource,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BottomSheetHandle().alignCenter,
          s8HeightBox,
          Text(GlobalConsts.inputSourcePopupText,
            style: context.textTheme.headlineMedium.bold,
            textAlign: TextAlign.center,
          ).withPadding(EdgeInsets.fromLTRB(0, 0, 0, 16)),
          GestureDetector(
            onTap: () {
              _selectFromSource(ImageSource.gallery);
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white12),
                  bottom: BorderSide(color: Colors.white12)
                )
              ),
              child: Text(
                GlobalConsts.photoGalleryText,
                textAlign:
                TextAlign.center,
                style: TextStyle(fontSize: 18),
              ).withPadding(s16Padding),
            ),
          ),
          GestureDetector(
            onTap: () {
              _selectFromSource(ImageSource.camera);
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white12)
                )
              ),
              child: Text(
                GlobalConsts.cameraText,
                textAlign:
                TextAlign.center,
                style: TextStyle(fontSize: 18),
              ).withPadding(s16Padding),
            ),
          ),
        ],
      ),
    );
  }
}