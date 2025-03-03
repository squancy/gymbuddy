import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:gym_buddy/consts/email_templates.dart' show EmailTemplate;

class EmailRepository {
  EmailRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Send an email to a given email address
  Future<void> sendEmail ({
    required String from,
    required String to,
    required EmailTemplate template
    }) async {
    // First get email credentials from db
    final Map<String, dynamic> emailCreds = (await _db.collection('email')
      .doc('email_settings')
      .get())
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
      ..subject = template.subject
      ..html = template.generateEmail();

    await send(message, smtpServer);
  }
}