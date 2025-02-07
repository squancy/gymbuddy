import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy/handlers/handle_login.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:gym_buddy/consts/common_consts.dart' as consts;

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await helpers.firebaseInit(test: true);
  test('Test server-side login functionality', () async {
    // This user exists in the test database
    CheckLogin login = CheckLogin('asd@test.com', 'asdasd');
    expect((true, '', '4f307ff7-f201-4732-93a9-72810a52e194'), await login.validateLogin());

    // This user does not have a valid email
    login = CheckLogin('asd@notavalidemail.com', 'asdasd');
    expect((false, consts.ForgotPasswordConsts.wrongCredentialsText, ''), await login.validateLogin());

    // This user does not have a valid password
    login = CheckLogin('asd@test.com', 'notavalidpassword');
    expect((false, consts.ForgotPasswordConsts.wrongCredentialsText, ''), await login.validateLogin());
  });
}