import 'package:flutter/material.dart';
import 'package:gym_buddy/ui/profile/view_models/profile_field_view_model.dart';
import 'package:gym_buddy/consts/common_consts.dart';

class Bio extends StatelessWidget {
  const Bio({
    required autofocus,
    required viewModel,
    super.key
  }) :
  _autofocus = autofocus,
  _viewModel = viewModel;

  final bool _autofocus;
  final ProfileFieldViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('bioField'),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: ProfileConsts.bioDefaultText,
        hintStyle: TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
        counterText: '',
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      autofocus: _autofocus,
      style: TextStyle(
        fontSize: 14,
        letterSpacing: 0,
        height: 1.4
      ),
      onChanged: (value) {
        _viewModel.setBioText();
      },
      controller: _viewModel.bioController,
      maxLines: null,
      onEditingComplete: () {
        _viewModel.finishBioEdit();
      },
      onSubmitted: (context) {
        _viewModel.finishBioEdit();
      },
      onTapOutside: (event) {
        _viewModel.finishBioEdit();
      },
      focusNode: _viewModel.bioFocusNode,
    );
  }
}

class DisplayUsername extends StatelessWidget {
  const DisplayUsername({
    required autofocus,
    required viewModel,
    super.key
  }) :
  _autofocus = autofocus,
  _viewModel = viewModel;

  final bool _autofocus;
  final ProfileFieldViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('displayUnameField'),
      decoration: InputDecoration(
        border: InputBorder.none,
        counterText: '',
        isDense: true,
        contentPadding: EdgeInsets.zero,
        hintText: ProfileConsts.emptyDisplayUnameText,
        hintStyle: TextStyle(
          color: Colors.grey,
        )
      ),
      controller: _viewModel.controller,
      focusNode: _viewModel.focusNode,
      autofocus: _autofocus,
      maxLength: 100,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
      ),
      onChanged: (value) {
        _viewModel.setDUnameText();
      },
      onEditingComplete: () {
        _viewModel.finishDUnameEdit();
      },
      onSubmitted: (context) {
        _viewModel.finishDUnameEdit();
      },
      onTapOutside: (event) {
        _viewModel.finishDUnameEdit();
      },
    );
  }
}

class DUnameTapRegion extends StatelessWidget {
  const DUnameTapRegion({
    required viewModel,
    super.key
  }) :
  _viewModel = viewModel;

  final ProfileFieldViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: _viewModel.displayUnameTapOutside,
      child: GestureDetector(
        onDoubleTap: _viewModel.displayUnameDoubleTap,
        child: ValueListenableBuilder<bool>(
          valueListenable: _viewModel.toggleEditDUname.showEdit,
          builder: (BuildContext context, bool value, Widget? child) {
            _viewModel.displayUnameMakeEditable();
            if (_viewModel.toggleEditDUname.showEdit.value) {
              return DisplayUsername(
                autofocus: _viewModel.uname.isNotEmpty,
                viewModel: _viewModel,
              );
            } else {
              // Username display
              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                child: Text(_viewModel.uname, style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0,
                )),
              );
            }
          }),
        ),
    );
  }
}

class BioTapRegion extends StatelessWidget {
  const BioTapRegion({
    required viewModel,
    super.key
  }) :
  _viewModel = viewModel;

  final ProfileFieldViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
      child: Builder(
        builder: (context) {
          _viewModel.bioMakeEditable();
          return TapRegion(
            onTapOutside: _viewModel.bioTapOutside,
            child: GestureDetector(
              onDoubleTap: _viewModel.bioDoubleTap,
              child: ValueListenableBuilder<bool>(
                valueListenable: _viewModel.toggleEditBio.showEdit,
                builder: (BuildContext context, bool value, Widget? child) {
                  if (_viewModel.toggleEditBio.showEdit.value) {
                    return Bio(
                      autofocus: _viewModel.bio.isNotEmpty,
                      viewModel: _viewModel,
                    );
                  } else {
                    return Text(
                      _viewModel.bio,
                      style: TextStyle(letterSpacing: 0, height: null),
                    );
                  }
                }
              ),
            ),
          );
        },
      ),
    ); 
  }
}
