import 'package:gym_buddy/ui/auth/view_models/login_view_model.dart';
import 'package:gym_buddy/ui/auth/widgets/login_screen.dart';
import 'package:gym_buddy/data/repository/auth/login_repository.dart';
import 'package:gym_buddy/data/service/common_service.dart';
import 'package:gym_buddy/data/repository/auth/signup_repository.dart';
import 'package:gym_buddy/data/repository/auth/email_repository.dart';
import 'package:gym_buddy/ui/auth/view_models/signup_view_model.dart';
import 'package:gym_buddy/ui/auth/widgets/signup_screen.dart';
import 'package:gym_buddy/ui/auth/widgets/renew_password_screen.dart';
import 'package:gym_buddy/ui/auth/view_models/renew_password_view_model.dart';
import 'package:gym_buddy/data/repository/auth/renew_password_repository.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/ui/main/widgets/welcome_page_screen.dart';
import 'package:gym_buddy/ui/main/view_models/welcome_page_view_model.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';
import 'package:gym_buddy/data/repository/auth/enter_code_repository.dart';
import 'package:gym_buddy/data/repository/auth/forgot_pass_repository.dart';
import 'package:gym_buddy/ui/auth/view_models/enter_code_view_model.dart';
import 'package:gym_buddy/ui/auth/widgets/enter_code_screen.dart';
import 'package:gym_buddy/ui/home/view_models/home_page_view_model.dart';
import 'package:gym_buddy/ui/home/widgets/home_page_screen.dart';
import 'package:gym_buddy/ui/auth/widgets/forgot_pass_screen.dart';
import 'package:gym_buddy/ui/auth/view_models/forgot_pass_view_model.dart';

class CustomRoutes {
  static MaterialPageRoute generateRoute(RouteSettings settings) {
    final Map<String, dynamic> args = (settings.arguments ?? <String, dynamic>{}) as Map<String, dynamic>;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => WelcomePage(
            viewModel: WelcomePageViewModel(
              commonRepository: CommonRepository()
            )
          )
        );
      case '/login':
        return MaterialPageRoute(builder: (context) => LoginPage(
          viewModel: LoginViewModel(
            signupRepository: SignupRepository(
              commononService: CommonService()
            ),
            loginRepository: LoginRepository()
          )
        ));
      case '/signup':
        return MaterialPageRoute(builder: (context) => SignupPage(
          viewModel: SignupViewModel(
            signupRepository: SignupRepository(
              commononService: CommonService()
            ),
            emailRepository: EmailRepository()
          )
        ));
      case '/renewPassword':
        return MaterialPageRoute(builder: (context) => RenewPasswordPage(
          userID: args['userID'],
          viewModel: RenewPasswordViewModel(
            renewPasswordRepository: RenewPasswordRepository()
          ),
        ));
      case '/enterCode':
        return MaterialPageRoute(
        builder: (context) => EnterCodePage(
          email: args['email'],
          userData: args['userData'],
          viewModel: EnterCodeViewModel(
            emailRepository: EmailRepository(),
            forgotPassRepository: ForgotPassRepository(),
            enterCodeRepository: EnterCodeRepository()
          ),
        ));
      case '/home':
        return MaterialPageRoute(
          builder: (context) => HomePage(
            postPageActs: args['info'].activities,
            postPageGyms: args['info'].gyms,
            userID: args['info'].userID as String,
            viewModel: HomePageViewModel(),
          ),
        );
      case '/forgotPassword':
        return MaterialPageRoute(builder: (context) => ForgotPasswordPage(
          viewModel: ForgotPassViewModel(
            emailRepository: EmailRepository(),
            forgotPassRepository: ForgotPassRepository()
          )
        ));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}')),
          ));
    }
  }
}