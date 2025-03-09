import 'package:flutter/material.dart';
import 'package:moye/moye.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:image_fade/image_fade.dart';
import 'dart:io';
import 'package:gym_buddy/ui/home/view_models/home_page_view_model.dart';
import 'package:gym_buddy/ui/home/widgets/home_page_screen.dart';

MaterialPageRoute<dynamic> homePageRoute(InfoRecord info) {
  return MaterialPageRoute(
    builder: (context) => HomePage(
      postPageActs: info.activities,
      postPageGyms: info.gyms,
      userID: info.userID as String,
      viewModel: HomePageViewModel(),
    ),
  );
}

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

class BlackTextfield extends StatelessWidget {
  const BlackTextfield(
    this.context,
    this.labelText,
    this.controller,
    this.focusNode,
    {required this.isPassword, required this.isEmail, super.key}
  );

  final BuildContext context;
  final String labelText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool isPassword;
  final bool isEmail;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
        labelText: labelText,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.tertiary,
          fontWeight: FontWeight.w500
        ),
        floatingLabelStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary
        ),
        fillColor: Colors.black,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      onTapOutside: (event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
    );
  }
}

class ImageBig {
  const ImageBig(this.context, this.image);

  final BuildContext context;
  final ImageProvider<Object>? image;

  SafeArea buildImage() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BottomSheetHandle().alignCenter,
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ImageFade(
                image: image,
                placeholder: Container(
                  color: Colors.black,
                ),
              ),
            ),
          )
        ]
      )
    );
  }

  void showImageInBig() {
    BottomSheetUtils.showBottomSheet(
      context: context,
      borderRadius: BorderRadius.circular(16),
      config: WrapBottomSheetConfig(
        builder: (context, controller) {
          return buildImage();
        },
      ),
    );
  }
}

class HorizontalImageViewer extends StatelessWidget {
  const HorizontalImageViewer({
    super.key,
    required this.showImages,
    required this.images,
    required this.isPost,
    this.context
  });

  final bool showImages;
  final List<dynamic> images;
  final bool isPost;
  final BuildContext? context;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: showImages ? 150 : 0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        children: [
        for (final el in images)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: GestureDetector(
              onTap: () {
                final imgb = ImageBig(context, isPost ? FileImage(File(el.path)) : NetworkImage(el));
                imgb.showImageInBig();
              },
              child: SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: ImageFade(
                      image: isPost ? FileImage(File(el.path)) : NetworkImage(el),
                      placeholder: Container(
                        width: 180,
                        height: 150,
                        color: Colors.black,
                      ),
                    )
                  ),
                ),
              ),
            ),
          ),
      ],),
    );
  }
}

class ProfilePicPlaceholder extends StatelessWidget {
  const ProfilePicPlaceholder({super.key, required this.radius});
  
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Color.fromARGB(255, 14, 22, 29),
    );
  }
}

class ProgressBtn extends StatelessWidget {
  const ProgressBtn({
    super.key,
    required this.onPressedFn,
    required this.child
  });

  final dynamic onPressedFn;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProgressButton(
      onPressed: onPressedFn,
      loadingType: ProgressButtonLoadingType.replace,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.secondary),
        foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onSecondary),
        textStyle: WidgetStatePropertyAll(
          TextStyle(
            fontWeight: FontWeight.bold
          )
        )
      ),
      type: ProgressButtonType.filled,
      child: child,
    );
  }
}