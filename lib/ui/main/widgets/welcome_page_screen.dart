import 'package:flutter/material.dart';
import 'package:gym_buddy/data/repository/auth/email_repository.dart';
import 'package:gym_buddy/data/repository/auth/login_repository.dart';
import 'package:gym_buddy/data/repository/auth/signup_repository.dart';
import 'package:gym_buddy/data/service/common_service.dart';
import 'package:gym_buddy/ui/auth/view_models/login_view_model.dart';
import 'package:gym_buddy/ui/auth/view_models/signup_view_model.dart';
import 'package:gym_buddy/ui/auth/widgets/signup_screen.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:gym_buddy/ui/auth/widgets/login_screen.dart';
import 'package:gym_buddy/ui/home/widgets/home_page_screen.dart';
import 'package:gym_buddy/ui/home/view_models/home_page_view_model.dart';
import 'package:gym_buddy/ui/core/common_ui.dart';
import 'package:moye/moye.dart';
import 'package:gym_buddy/ui/main/view_models/welcome_page_view_model.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({
    required this.viewModel,
    super.key
  });
  
  final WelcomePageViewModel viewModel;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
@override
  void initState() {
    super.initState();
    widget.viewModel.getPreloadedData();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PreloadedData?>(
      valueListenable: widget.viewModel.preloadedData,
      builder: (BuildContext context, PreloadedData? data, Widget? child) {
        if (data != null && data.loggedIn) {
          return HomePage(
            postPageActs: data.activities,
            postPageGyms: data.gyms,
            viewModel: HomePageViewModel(),
            userID: data.userID,
          );
        } else if (data == null) {
          return Scaffold(
            body: Center(
              child: GlobalConsts.spinkit
            )
          );
        } else {
          return Scaffold(
            body: MovingBackground(
              animationType: AnimationType.translation,
              backgroundColor: Colors.black,
              circles: [
                MovingCircle(color: Theme.of(context).colorScheme.tertiary),
                MovingCircle(color: Theme.of(context).colorScheme.tertiary),
                MovingCircle(color: Theme.of(context).colorScheme.primary),
                MovingCircle(color: Theme.of(context).colorScheme.primary),
              ],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [Text(
                      WelcomePageConsts.appTitle,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                      )
                    ),
                    const SizedBox(height: 60),
                    MainButton(
                      displayText: WelcomePageConsts.loginButtonTitle,
                      onPressedFunc: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage(
                            viewModel: LoginViewModel(
                              signupRepository: SignupRepository(
                                commononService: CommonService()
                              ),
                              loginRepository: LoginRepository()
                            )
                          )),
                        );
                      },
                      fontSize: 18,
                    ).withGlowContainer(
                      color: Colors.white24,
                      blurRadius: 20
                    ),
                    const SizedBox(height: 30),
                    MainButton(
                      displayText: WelcomePageConsts.signupButtonTitle,
                      onPressedFunc: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignupPage(
                            viewModel: SignupViewModel(
                              signupRepository: SignupRepository(
                                commononService: CommonService()
                              ),
                              emailRepository: EmailRepository()
                            )
                          )),
                        );
                      },
                      fontSize: 18,
                    ).withGlowContainer(
                      color: Colors.white24,
                      blurRadius: 20
                    )
                  ],
                ),
              ),
            ),
          );
        }
      }
    );
  }
}