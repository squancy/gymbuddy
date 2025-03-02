import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/data/repository/auth/email_repository.dart';
import 'package:gym_buddy/data/repository/auth/enter_code_repository.dart';
import 'package:gym_buddy/data/repository/auth/forgot_pass_repository.dart';
import 'package:gym_buddy/utils/test_utils/test_helpers.dart' show generateRandomString;
import 'package:gym_buddy/consts/email_templates.dart';

class EnterCodeViewModel extends ChangeNotifier {
  EnterCodeViewModel({
    required emailRepository,
    required forgotPassRepository,
    required enterCodeRepository
  }) :
  _emailRepository = emailRepository,
  _forgotPassRepository = forgotPassRepository,
  _enterCodeRepository = enterCodeRepository;

  final EmailRepository _emailRepository;
  final ForgotPassRepository _forgotPassRepository;
  final EnterCodeRepository _enterCodeRepository;
  final FocusNode codeFocusNode = FocusNode();
  final TextEditingController codeController = TextEditingController();
  final ValueNotifier<String> codeStatus = ValueNotifier<String>("");
  final ValueNotifier<String> forgotPassStatus = ValueNotifier<String>("");
  ValueNotifier<PageTransition> pageTransition = ValueNotifier(PageTransition.stayOnPage);
  String userIDRenewPass = '';

  /// Make sure the user enters the correct code (=temporary password) received in email
  Future<void> checkCode({
    required String email,
    required String code
    }) async {
    // Get the ID of the potential user
    try {
      final userDocs = await _enterCodeRepository.getUserWithCode(
        email: email,
        code: code
      );

      if (userDocs.isEmpty) {
        codeStatus.value = ForgotPasswordConsts.codePageErrorText;
        notifyListeners();
        return;
      } else if (userDocs.length == 1) {
        final String userID = userDocs.toList()[0].reference.id;

        // If the entered code is correct redirect user to the next page
        // There they can change their password
        userIDRenewPass = userID;
        pageTransition.value = PageTransition.goToNextPage;
      } else {
        codeStatus.value = GlobalConsts.unknownErrorText;
        notifyListeners();
        return;
      }
    } catch (error) {
      log("checkCode(): $error");
      codeStatus.value = GlobalConsts.unknownErrorText;
      notifyListeners();
      return;
    }
  }

  Future<void> sendPassword({
    required String email,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> userData
    }) async {
    // Generate a temporary password: user can change it later in their profile
    try {
      final tempPass = generateRandomString(10);

      final username = userData[0].data()['username'];
      final userID = userData[0].reference.id;
      final TemporaryPassEmail tempPassEmail = TemporaryPassEmail(
        username: username,
        tempPass: tempPass
      );

      // Send temporary password to user's email address
      await _emailRepository.sendEmail(
        from: GlobalConsts.infoEmail,
        to: email,
        template: tempPassEmail
      );

      // Set temporary password in db
      _forgotPassRepository.setTempPass(userID: userID, tempPass: tempPass);
    } catch (error) {
      log("sendPassword(): $error");
      codeStatus.value = GlobalConsts.unknownErrorText;
      notifyListeners();
      return;
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    codeFocusNode.dispose();
    codeStatus.dispose();
    super.dispose();
  }
}