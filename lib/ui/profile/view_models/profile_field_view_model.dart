import 'package:flutter/material.dart';
import 'package:gym_buddy/data/repository/profile/profile_field_repository.dart';
import 'package:gym_buddy/consts/common_consts.dart';

class Toggle {
  final ValueNotifier<bool> showEdit = ValueNotifier<bool>(false);

  void makeEditable() {
    showEdit.value = true;
  }

  void makeUneditable() {
    showEdit.value = false;
  }
}

class ProfileFieldViewModel extends ChangeNotifier {
  ProfileFieldViewModel({
    required profileFieldRepository
  }) :
  _profileFieldRepository = profileFieldRepository;

  final ProfileFieldRepository _profileFieldRepository;
  final toggleEditDUname = Toggle();
  final toggleEditBio = Toggle();
  final controller = TextEditingController();
  final bioController = TextEditingController();
  final focusNode = FocusNode();
  final bioFocusNode = FocusNode();
  String uname = '';
  String bio = '';
  final bottomScrollController = ScrollController();

  Future<void> _resetToTxt({
    required Toggle toggle,
    required TextEditingController controller,
    required int maxLen,
    required String fieldName,
    required bool isBio}) async {
    if (toggle.showEdit.value) {
      if (controller.text.isNotEmpty) toggle.makeUneditable();
      await _profileFieldRepository.saveNewData(
        controller.text,
        maxLen,
        fieldName,
        isBio: isBio
      );
    }
  }

  void setBioText() {
    bio = bioController.text;
  }

  void setDUnameText() {
    uname = controller.text;
  }

  Future<void> _finishEdit({
    required Toggle toggle,
    required TextEditingController controller,
    required int maxLen,
    required String fieldName,
    required bool isBio}) async {
    _resetToTxt(
      toggle: toggle,
      controller: controller,
      maxLen: maxLen,
      fieldName: fieldName,
      isBio: isBio
    );
    await _profileFieldRepository.saveNewData(
      controller.text,
      maxLen,
      fieldName,
      isBio: isBio
    );
  }

  void finishBioEdit() {
    _finishEdit(
      toggle: toggleEditBio,
      controller: bioController,
      maxLen: ProfileConsts.maxBioLength,
      fieldName: 'bio',
      isBio: true
    );
  }

  void finishDUnameEdit() {
    _finishEdit(
      toggle: toggleEditDUname,
      controller: controller,
      maxLen: ValidateSignupConsts.maxUsernameLength,
      fieldName: 'display_username',
      isBio: false
    );
  }

  void displayUnameTapOutside(PointerDownEvent _) async {
    if (controller.text.isEmpty) {
      focusNode.unfocus();      
    } else {
      if (toggleEditDUname.showEdit.value) {
        uname = controller.text;
      }
      await _resetToTxt(
        toggle: toggleEditDUname,
        controller: controller,
        maxLen: ValidateSignupConsts.maxUsernameLength,
        fieldName: 'display_username',
        isBio: false
      );
    }
  }

  void bioTapOutside(PointerDownEvent _) async {
    if (bioController.text.isEmpty) {
      bioFocusNode.unfocus();      
    } else {
      if (toggleEditBio.showEdit.value) bio = bioController.text;
      await _resetToTxt(
        toggle: toggleEditBio,
        controller: bioController,
        maxLen: ProfileConsts.maxBioLength,
        fieldName: 'bio',
        isBio: true
      );
    }
  }

  void displayUnameDoubleTap() {
    toggleEditDUname.makeEditable();
    controller.text = uname;
  }

  void displayUnameMakeEditable() {
    if (uname.isEmpty) {
      toggleEditDUname.makeEditable();
    }
  }
  
  void bioMakeEditable() {
    if (bio.isEmpty) {
      toggleEditBio.makeEditable();
    }
  }

  void bioDoubleTap() {
    if (bio.isEmpty) return;
    toggleEditBio.makeEditable();
    bioController.text = bio;
  }

  @override
  void dispose() {
    controller.dispose();
    bioController.dispose();
    bioFocusNode.dispose();
    focusNode.dispose();
    super.dispose();
  } 
}