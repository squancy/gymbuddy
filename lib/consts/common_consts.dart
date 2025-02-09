import 'package:flutter/material.dart';

// Login page [login_page.dart]
class LoginConsts {
  static const String appBarText = 'Log in';
  static const String mainScreenText = 'Welcome back';
  static const String forgotPasswordText = 'Forgot password';
}

// Signup page [signup_page.dart]
class SignupConsts {
  static const String appBarText = 'Sign up';
  static const String mainScreenText = 'Create account';
  static const String usernameText = 'Username';
  static const String emailText = 'Email';
  static const String passwordText = 'Password';
  static const String passwordConfText = 'Confirm password';
  static const String accountExistsText = 'Already have an account?';
  static const String passwordLengthText = 'Your password is too short (min ${ValidateSignupConsts.maxPasswordLength} characters)';
  static const String allFieldsText = 'Fill all fields';
  static const String usernameTooLongText = 'Username is too long';
  static const String invalidEmailText = 'Email is invalid';
  static const String passwordMismatchText = 'Password fields do not match';
  static const String invalidUsernameText = 'Username can only contain alphanumeric characters and _ and .'; // TODO - Add more characters
  static const String emailAddrTakenText = 'This email address is already taken';
  static const String usernameTakenText = 'This username is already taken';
}

// Home page [main.dart]
class HomeConsts {
  static const String appTitle = 'Gym Buddy App'; 
  static const String loginButtonTitle = 'Log in';
  static const String signupButtonTitle = 'Sign up';
}

// Forgot password [forgot_password.dart]
class ForgotPasswordConsts {
  static const String appBarText = 'Forgot password';
  static const String mainScreenText = 'New password';
  static const String infoText = 'We will send a temporary password to your email';
  static const String redBtnText = 'Send password';
  static const String wrongCredentialsText = 'Your email or password is incorrect';
}

// Post page [post_page.dart]
class PostPageConsts {
  static const String appBarText = 'Find a gym buddy';
  static const String textBarText = 'Looking for a buddy?';
  static const String dayTypeText = 'What are you going to do?';
  static const String gymTypeText = 'Which gym are you going to?';
  static const String timeTypeText = 'What time?';
  static const String photosUploadText = 'Add photos';
  static const String postButtonText = 'Post';
  static const String emptyFieldError = 'Fill why you want a gym buddy';
  static const int maxNumOfImages = 5;
}

// Signup page validation 
class ValidateSignupConsts {
  static const int maxUsernameLength = 100;
  static const int maxPasswordLength = 6;
}

// Profile page [profile_page.dart]
class ProfileConsts {
  static const int maxBioLength = 200;
  static const String defaultProfilePicPath = 'assets/default_profile_pic.png';
  static const int paginationNum = 24;
  static const int profilePicSize = 200;
  static const String bioDefaultText = 'Write something about yourself...';
  static const String emptyDisplayUnameText = 'Edit username...';
}

class GlobalConsts {
  static const spinkit = CircularProgressIndicator.adaptive();
  static const bool test = true;
  static const String defaultProfilePicPath = 'assets/default_profile_pic.png';
  static const String inputSourcePopupText = 'Select an input source';
  static const String photoGalleryText = 'Photo gallery';
  static const String cameraText = 'Camera';
  static const String unknownErrorText = 'An unknown error occurred';

  // Now the list of potential activities are given here
  // In the future they are going to be fetched from a file or other sources
  static const List<String> activities = [
    'Chest',
    'Back',
    'Legs',
    'Cardio',
    'Arms'
  ];
}

// Typedefs
typedef ActGymRecord = ({List<String> activities, List<Map<String, dynamic>> gyms});