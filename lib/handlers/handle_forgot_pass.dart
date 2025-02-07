import 'package:cloud_firestore/cloud_firestore.dart';

class HandleForgotPass {
  const HandleForgotPass(this.email);

  final String email;

  Future<bool> emailExists() async {
    // Check if email exists in DB
    return Future(() => true,);
  }
}