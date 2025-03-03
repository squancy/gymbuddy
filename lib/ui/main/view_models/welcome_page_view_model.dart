import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';

class WelcomePageViewModel extends ChangeNotifier {
  WelcomePageViewModel();

  ValueNotifier<PreloadedData?> preloadedData = ValueNotifier(null);

  /// Get log in status and preload activities & gyms from db
  Future<void> getPreloadedData() async {
    try {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      bool loggedIn = true;
      bool? fi = await prefs.getBool('loggedIn');
      if (fi == null || fi == false) {
        await prefs.setBool('loggedIn', false);
        loggedIn = false;
      }

      final ActGymRecord actAndGyms = await CommonRepository().getActivitiesAndGyms();
      preloadedData.value = (
        activities: actAndGyms.activities,
        gyms: actAndGyms.gyms, loggedIn :loggedIn
      );
      notifyListeners();
    } catch (error) {
      log("getPreloadedData(): $error");
    }
  }
}