import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy/consts/email_templates.dart' show EmailTemplate;
import 'package:gym_buddy/data/repository/auth/email_repository.dart';
import 'package:gym_buddy/data/repository/auth/forgot_pass_repository.dart';
import 'package:gym_buddy/data/repository/auth/login_repository.dart';
import 'package:gym_buddy/data/repository/auth/signup_repository.dart';

// In-memory stand-ins for the auth repositories, so widget tests never touch
// Firebase, geolocation or SMTP. A method a test does not override throws
// UnimplementedError (from Fake), which makes an unexpected backend call fail loudly.

class FakeSignupRepository extends Fake implements SignupRepository {
  FakeSignupRepository({this.takenUsernames = const {}, this.takenEmails = const {}});

  final Set<String> takenUsernames;
  final Set<String> takenEmails;
  final List<Map<String, String>> insertedUsers = [];

  @override
  Future<void> requestPosition() async {}

  @override
  Future<(bool isValid, String errorMsg)> userExists({
    required String username,
    required String email
  }) async {
    if (takenUsernames.contains(username)) return (false, 'username taken');
    if (takenEmails.contains(email)) return (false, 'email taken');
    return (true, '');
  }

  @override
  Future<(bool success, String errorMsg, String userID)> insertToDB({
    required String username,
    required String email,
    required String password,
    required String sex
  }) async {
    insertedUsers.add({'username': username, 'email': email, 'sex': sex});
    return (true, '', 'fake-user-id');
  }

  @override
  Future<void> setUserState({required String userID, required bool loggedIn}) async {}
}

class FakeLoginRepository extends Fake implements LoginRepository {}

class FakeForgotPassRepository extends Fake implements ForgotPassRepository {}

class FakeEmailRepository extends Fake implements EmailRepository {
  final List<String> sentTo = [];

  @override
  Future<void> sendEmail({
    required String from,
    required String to,
    required EmailTemplate template
  }) async {
    sentTo.add(to);
  }
}
