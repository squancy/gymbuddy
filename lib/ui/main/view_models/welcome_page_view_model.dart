import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;

class WelcomePageViewModel extends ChangeNotifier {
  WelcomePageViewModel();

  ValueNotifier<PreloadedData?> preloadedData = ValueNotifier(null);

  /// Get log in status and preload activities & gyms from db
  Future<void> getPreloadedData() async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    bool loggedIn = true;
    bool? fi = await prefs.getBool('loggedIn');
    if (fi == null || fi == false) {
      await prefs.setBool('loggedIn', false);
      loggedIn = false;
    }

    final ActGymRecord actAndGyms = await helpers.getActivitiesAndGyms();
    preloadedData.value = (
      activities: actAndGyms.activities,
      gyms: actAndGyms.gyms, loggedIn :loggedIn
    );
    notifyListeners();
  }
}