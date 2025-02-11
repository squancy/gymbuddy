abstract class EmailTemplate {
  String get subject;
  String generateEmail();
}

class TemporaryPassEmail extends EmailTemplate {
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

  // TODO: set the link to a correct destination once the app is finished
  @override
  String generateEmail() {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Temporary Password</title>
          <style>
              body {
                  font-family: Arial, sans-serif;
                  background-color: #f4f4f4;
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
                  color: #ffffff;
                  font-size: 16px;
              }
              .button {
                  display: inline-block;
                  padding: 10px 20px;
                  margin-top: 20px;
                  color: #ffffff;
                  background: linear-gradient(90deg, #e0bbdd, #b0c6ff);
                  text-decoration: none;
                  border-radius: 5px;
                  font-size: 16px;
                color: black;
              }
              .temp-password {
                  font-size: 20px;
                  font-weight: bold;
                  background: linear-gradient(90deg, #e0bbdd, #b0c6ff);
                  -webkit-background-clip: text;
                  -webkit-text-fill-color: transparent;
              }
              .footer {
                  margin-top: 20px;
                  font-size: 12px;
                  color: #777;
              }
          </style>
      </head>
      <body>
          <div class="container">
              <h2>Temporary Password</h2>
              <p>
                Hello, <span class="temp-password" style="font-size: 16px;">$username</span>
              </p>
              <p>
                We have generated a temporary password for your account.
                Please use the password below to log in and reset your password immediately.
              </p>
              <p class="temp-password">$tempPass</p>
              <p>Click the button below to log in and change your password:</p>
              <a href="https://www.kagur.com" class="button">Reset Your Password</a>
              <p class="footer">
                If you did not request this, please ignore this email or contact support.
              </p>
          </div>
      </body>
      </html>
    ''';
  }
}