import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy/handlers/handle_signup.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/consts/common_consts.dart' as consts;

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await helpers.firebaseInit(test: true);
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final users = db.collection('users');

  test('Test server-side signup functionality', () async {
    // This user exists with the given username
    ValidateSignup signup = ValidateSignup('test', '', '', '');
    expect((false, consts.SignupConsts.usernameTakenText), await signup.userExists());

    // This user exists with the given email
    signup = ValidateSignup('', 'asd@test.com', '', '');
    expect((false, consts.SignupConsts.emailAddrTakenText), await signup.userExists());

    // This user does not exist
    signup = ValidateSignup('newuser', 'newuser@test.com', '', '');
    expect((true, ''), await signup.userExists());

    InsertSignup insert = InsertSignup('newuser@test.com', 'password', 'newuser');
    await insert.insertToDB();

    // Make sure it is pushed to db
    QuerySnapshot usersWithUsername = await users.where('username', isEqualTo: 'newuser').get();
    expect(usersWithUsername.docs.length, 1);
    var userData = usersWithUsername.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    expect(userData[0]['username'], 'newuser');
    expect(userData[0]['email'], 'newuser@test.com');
  });
}