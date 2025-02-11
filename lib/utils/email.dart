import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

/// Send an email to a given email address
Future<void> sendEmail ({
  required String from,
  required String to,
  required String subject,
  required String content}) async {
  // First get email credentials from db
  final Map<String, dynamic> emailCreds = (await db.collection('email').doc('email_settings').get())
    .data() as Map<String, dynamic>; 
  final String username = emailCreds['username']; 
  final String password = emailCreds['password']; 
  final String incomingOutgoingServer = emailCreds['smtp'];

  final smtpServer = SmtpServer(
    incomingOutgoingServer,
    port: 465,
    ignoreBadCertificate: false,
    ssl: true,
    username: username,
    password: password
  );

  final message = Message()
    ..from = Address(username, 'Kagur')
    ..recipients.add(to)
    ..subject = subject
    ..html = content;

  // The caller is responsible for catching any error that might happen at this point
  await send(message, smtpServer);
}