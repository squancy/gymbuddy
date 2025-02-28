import 'package:flutter/material.dart';
import 'package:moye/moye.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gym_buddy/consts/common_consts.dart' as consts;

class PhotoUploadPopup {
  const PhotoUploadPopup(
    this.context,
    this.selectFromSource,
  );

  final BuildContext context;
  final Function selectFromSource;

  SafeArea buildBottomSheetContent(
    BuildContext context,
    Function selectFromSource) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BottomSheetHandle().alignCenter,
          s8HeightBox,
          Text(consts.GlobalConsts.inputSourcePopupText,
                style: context.textTheme.headlineMedium.bold,
                textAlign: TextAlign.center,
              ).withPadding(EdgeInsets.fromLTRB(0, 0, 0, 16)),
          GestureDetector(
            onTap: () {
              selectFromSource(ImageSource.gallery);
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
                consts.GlobalConsts.photoGalleryText,
                textAlign:
                TextAlign.center,
                style: TextStyle(fontSize: 18),
              ).withPadding(s16Padding),
            ),
          ),
          GestureDetector(
            onTap: () {
              selectFromSource(ImageSource.camera);
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white12)
                )
              ),
              child: Text(
                consts.GlobalConsts.cameraText,
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

  void showOptions() {
    BottomSheetUtils.showBottomSheet(
      context: context,
      borderRadius: BorderRadius.circular(16),
      config: WrapBottomSheetConfig(
        builder: (context, controller) {
          return buildBottomSheetContent(context, selectFromSource);
        },
      ),
    );
  }
}