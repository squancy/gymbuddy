abstract class EmailTemplate {
  String get subject;
  String generateEmail();
}

mixin CommonContent {
  final String head = '''
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Temporary Password</title>
        <style>
            body, .container {
                font-family: Arial, sans-serif;
                background-color: #15202b !important;
                color: #ffffff !important;
                margin: 0;
                padding: 0;
            }
            .container {
                max-width: 600px;
                margin: 20px auto;
                background: #15202b;
                padding: 20px;
                border-radius: 8px;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                text-align: center;
                font-size: 16px;
            }
            .button {
                display: block;
                padding: 10px 20px;
                margin-top: 20px;
                color: black;
                background: linear-gradient(90deg, #e0bbdd, #b0c6ff);
                text-decoration: none;
                border-radius: 5px;
                font-size: 16px;
                width: max-content;
                text-align: center;
            }
            .highlight {
                font-size: 20px;
                font-weight: bold;
                color: #e0bbdd; /* Special color for the username */
            }
            .temp-password {
                font-size: 20px;
                font-weight: bold;
                color: #b0c6ff; /* Special color for the temporary password */
            }
            .footer {
                margin-top: 20px;
                font-size: 12px;
                color: #777;
            }
        </style>
    </head>
  ''';
}

class SignUpEmail extends EmailTemplate with CommonContent {
  final String username;

  SignUpEmail({required this.username});

  @override
  String get subject {
    return 'Welcome to Kagur';
  }

  @override
  String generateEmail() {
    return '''
      <!DOCTYPE html>
      <html>
      $head
      <body>
          <div class="container">
              <h2>Welcome to Kagur!</h2>
              <p>
                Hello, <span class="highlight">$username</span>
              </p>
              <p>
                We're excited to have you on board and hope you will have a lot of exciting
                workout sessions. 
              </p>
              <p class="highlight">Your journey starts now!</p>
              <p class="footer">
                If you have any questions, feel free to reach out to our support team.
              </p>
          </div>
      </body>
      </html>
    ''';
  }
}

class TemporaryPassEmail extends EmailTemplate with CommonContent {
  final String username;
  final String tempPass;

  TemporaryPassEmail({
    required this.username,
    required this.tempPass
  });

  @override
  String get subject {
    return 'Temporary password for your Kagur account';
  }

  @override
  String generateEmail() {
    return '''
      <!DOCTYPE html>
      <html>
      $head
      <body>
          <div class="container">
              <h2>Temporary Password</h2>
              <p>
                Hello, <span class="highlight">$username</span>
              </p>
              <p>
                We have generated a temporary code for your account that you can find below.
              </p>
              <p class="temp-password">$tempPass</p>
              <p>
                You will need this code to authenticate yourself in Kagur.
                After that, you can set a new password.
              </p>
              <p class="footer">
                If you did not request this, please ignore this email or contact support.
              </p>
          </div>
      </body>
      </html>
    ''';
  }
}
