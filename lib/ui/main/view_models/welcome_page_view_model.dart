import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';

class WelcomePageViewModel extends ChangeNotifier {
  WelcomePageViewModel({
    required commonRepository
  }) :
  _commonRepository = commonRepository;

  ValueNotifier<PreloadedData?> preloadedData = ValueNotifier(null);
  final CommonRepository _commonRepository;

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

      final InfoRecord actAndGyms = await _commonRepository.getActivitiesAndGyms();
      preloadedData.value = (
        activities: actAndGyms.activities,
        gyms: actAndGyms.gyms,
        loggedIn: loggedIn,
        userID: (await _commonRepository.getUserID())
      );
      notifyListeners();
    } catch (error) {
      log("getPreloadedData(): $error");
    }
  }
}