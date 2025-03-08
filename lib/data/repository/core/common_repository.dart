import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/firestore_cache/cache.dart';
import 'package:gym_buddy/firebase_options.dart';

class CommonRepository {
  CommonRepository();

  Future<List<String>> getAllActivitiesWithoutProps(CollectionReference collection) async {
    QuerySnapshot querySnapshot = await collection.getCached();
    return querySnapshot.docs
      .map((doc) => (doc.data() as Map<String, dynamic>?)?['name'] as String? ?? 'Unknown')
      .toList()..sort();
  }

  // In-place function
  void sortGymsByName(List<Map<String, dynamic>> gyms) {
    gyms.sort((a, b) {
      return a[a.keys.toList()[0]]['name'].compareTo(b[b.keys.toList()[0]]['name']);
    });
  }

  Future<List<Map<String, dynamic>>> getAllGymsWithProps(CollectionReference collection) async {
    QuerySnapshot querySnapshot = await collection.getCached();
    return querySnapshot.docs
      .map((doc) {
        String docID = doc.reference.id;
        Map<String, dynamic> res = {};
        Map<String, dynamic>? docData = (doc.data() as Map<String, dynamic>?);
        res[docID] = {
          'name': docData?['name'],
          'address': docData?['address']
        };
        return res;
      }).toList();
  }

  Future<String> getUserID() async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    return (await prefs.getString('userID')) as String;
  }

  Future<void> logout() async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    await prefs.setBool('loggedIn', false);
  }

  Future<void> firebaseInit({required bool test}) async {
    if (!test) {
      WidgetsFlutterBinding.ensureInitialized();
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (GlobalConsts.test) {
      try {
        FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
        FirebaseStorage.instance.useStorageEmulator('127.0.0.1', 9199);
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }
  }

  /// Fetch all activities and gyms from db
  Future<InfoRecord> getActivitiesAndGyms() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final allGyms = await getAllGymsWithProps(db.collection('gyms/budapest/gyms'));
    sortGymsByName(allGyms);

    final allActivities = await getAllActivitiesWithoutProps(db.collection('activities'));
    allActivities.sort();

    final String userID = await getUserID();
    return (activities: allActivities, gyms: allGyms, userID: userID);
  }
}