import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_buddy/theme.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/ui/main/widgets/welcome_page_screen.dart';
import 'package:gym_buddy/ui/main/view_models/welcome_page_view_model.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase init START
  await CommonRepository().firebaseInit(test: GlobalConsts.test);
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
      home: WelcomePage(
        viewModel: WelcomePageViewModel(),
      ),
    );
  }
}