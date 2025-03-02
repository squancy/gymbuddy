import 'dart:developer';
import 'package:gym_buddy/data/repository/auth/email_repository.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/utils/test_utils/test_helpers.dart' show generateRandomString;
import 'package:gym_buddy/consts/email_templates.dart';
import 'package:gym_buddy/data/repository/auth/forgot_pass_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPassViewModel extends ChangeNotifier {
  ForgotPassViewModel({
    required emailRepository,
    required forgotPassRepository
  }) :
  _emailRepository = emailRepository,
  _forgotPassRepository = forgotPassRepository;

  final EmailRepository _emailRepository;
  final ForgotPassRepository _forgotPassRepository;

  final TextEditingController emailController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final ValueNotifier<String> forgotPassStatus = ValueNotifier<String>("");
  ValueNotifier<PageTransition> pageTransition = ValueNotifier(PageTransition.stayOnPage);
  String? emailEnterCode;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? userDataEnterCode;

  Future<void> sendPassword() async {
    final String email = emailController.text;

    // Make sure the email is in db
    final userData = await _forgotPassRepository.getUserWithEmail(email);
    if (userData.isEmpty) {
      forgotPassStatus.value = ForgotPasswordConsts.userNotExistsText;
      notifyListeners();
      return;
    } else {
      forgotPassStatus.value = '';

      // Generate a temporary password: user can change it later in their profile
      final tempPass = generateRandomString(10);

      final username = userData[0].data()['username'];
      final userID = userData[0].reference.id;
      final TemporaryPassEmail tempPassEmail = TemporaryPassEmail(
        username: username,
        tempPass: tempPass
      );

      // Send temporary password to user's email address
      try {
        await _emailRepository.sendEmail(
          from: GlobalConsts.infoEmail,
          to: email,
          template: tempPassEmail
        );

        // Set temporary password in db
        await _forgotPassRepository.setTempPass(userID: userID, tempPass: tempPass);

        // Redirect to a new page when user has to enter the code in the email
        userDataEnterCode = userData;
        emailEnterCode = email;
        pageTransition.value = PageTransition.goToNextPage;
      } catch (error) {
        log("sendPassword(): $error");
        forgotPassStatus.value = GlobalConsts.unknownErrorText;
        notifyListeners();
      }
    }
  }


  @override
  void dispose() {
    emailController.dispose();
    emailFocusNode.dispose();
    forgotPassStatus.dispose();
    super.dispose();
  }
}