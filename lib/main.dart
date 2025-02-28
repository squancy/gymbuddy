import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_buddy/data/repository/email_repository.dart';
import 'package:gym_buddy/data/repository/login_repository.dart';
import 'package:gym_buddy/data/repository/signup_repository.dart';
import 'package:gym_buddy/service/common_service.dart';
import 'package:gym_buddy/ui/auth/view_models/login_view_model.dart';
import 'package:gym_buddy/ui/auth/view_models/signup_view_model.dart';
import 'package:gym_buddy/theme.dart';
import 'package:gym_buddy/ui/auth/widgets/signup_screen.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:gym_buddy/ui/auth/widgets/login_screen.dart';
import 'package:gym_buddy/ui/home/widgets/home_page_screen.dart';
import 'package:gym_buddy/ui/home/view_models/home_page_view_model.dart';
import 'package:gym_buddy/ui/core/ui/common_ui.dart';
import 'package:moye/moye.dart';

typedef PreloadedData = ({
  List<String> activities,
  List<Map<String, dynamic>> gyms, bool loggedIn
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase init START
  await helpers.firebaseInit(test: GlobalConsts.test);
  // Firebase init END
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const GymBuddyApp());
}

class GymBuddyApp extends StatelessWidget {
  const GymBuddyApp({super.key});
  static const ColorScheme gymBuddyColorScheme = GlobalThemeData.defaultColorScheme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Buddy App',
      theme: ThemeData(
        // fontFamily: 'Rethink Sans',
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue.shade900
      ),
      home: WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  /// Get log in status and preload activities & gyms from db
  Future<PreloadedData> _getPreloadedData() async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    bool loggedIn = true;
    bool? fi = await prefs.getBool('loggedIn');
    if (fi == null || fi == false) {
      await prefs.setBool('loggedIn', false);
      loggedIn = false;
    }

    final ActGymRecord actAndGyms =  await helpers.getActivitiesAndGyms();
    return (activities: actAndGyms.activities, gyms: actAndGyms.gyms, loggedIn :loggedIn);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getPreloadedData(),
      builder: (context, AsyncSnapshot<PreloadedData> snapshot) {
        if (snapshot.hasData && (snapshot.data as PreloadedData).loggedIn) {
          final (:activities, :gyms, :loggedIn) = snapshot.data as PreloadedData;
          return HomePage(
            postPageActs: activities,
            postPageGyms: gyms,
            viewModel: HomePageViewModel(),
          );
        } else if (!snapshot.hasData) {
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