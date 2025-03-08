import 'package:flutter/material.dart';
import 'package:image_fade/image_fade.dart';
import 'package:gym_buddy/ui/core/common_ui.dart';
import 'package:gym_buddy/ui/profile/view_models/profile_photo_view_model.dart';

// Profile photo widget
class ProfilePhoto extends StatefulWidget {
  const ProfilePhoto({
    required this.viewModel,
    required this.userID,
    super.key
  });

  final ProfilePhotoViewModel viewModel;
  final String userID;

  @override
  State<ProfilePhoto> createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends State<ProfilePhoto> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.getProfilePicFile(widget.userID);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (BuildContext context, Widget? child) {
        if (widget.viewModel.profilePicFile != null) {
          return GestureDetector(
            onDoubleTap: () {
              BottomSheetContent(
                selectFromSource: widget.viewModel.selectFromSource
              ).showOptions(context);
            },
            child: Builder(
              builder: (context) {
                return SizedBox(
                  width: 80,
                  height: 80,
                  child: ClipOval(
                    child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                      child: ImageFade(
                        key: const Key('profilePic'),
                        image: widget.viewModel.showFile ?
                          FileImage(widget.viewModel.image) :
                          widget.viewModel.getBgImage(),
                        placeholder: Container(
                          width: 80,
                          height: 80,
                          color: Colors.black,
                        ),
                      )
                    ),
                  ),
                );
              }
            ),
          );
        } else {
          return ProfilePicPlaceholder(radius: 40,);
        }
      }
    );
  }
}