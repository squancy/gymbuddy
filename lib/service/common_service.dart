import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';

class CommonService {
  CommonService();

  String getPlatform() {
    // Detect current platform
    String platform = 'unknown';
    if (Platform.isAndroid) {
      platform = 'Android';
    } else if (Platform.isIOS) {
      platform = 'iOS';
    }
    return platform;
  }

  Future<Position?> getGeolocation() async { 
    // Get geolocation data, if available
    try {
      Position? geoloc;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (serviceEnabled && permission != LocationPermission.denied) {
        geoloc = await Geolocator.getCurrentPosition();
      } else {
        geoloc = await Geolocator.getLastKnownPosition();
      }
      return geoloc;
    } catch (e) {
      return null;
    }
  }

  Future<void> requestPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }
  }
}