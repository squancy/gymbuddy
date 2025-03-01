import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_fade/image_fade.dart';
import 'dart:io';
import 'package:moye/moye.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../consts/common_consts.dart';
import 'package:gym_buddy/firestore_cache/cache.dart';
import 'package:gym_buddy/ui/home/widgets/home_page_screen.dart';
import 'package:gym_buddy/ui/home/view_models/home_page_view_model.dart';

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

Future<String?> getUserID() async {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  return prefs.getString('userID');
}

Future<void> logout() async {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  await prefs.setBool('loggedIn', false);
}

class BlackTextfield extends StatelessWidget {
  const BlackTextfield(
    this.context,
    this.labelText,
    this.controller,
    this.focusNode,
    {required this.isPassword, required this.isEmail, super.key}
  );

  final BuildContext context;
  final String labelText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool isPassword;
  final bool isEmail;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
        labelText: labelText,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.tertiary,
          fontWeight: FontWeight.w500
        ),
        floatingLabelStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary
        ),
        fillColor: Colors.black,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      onTapOutside: (event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
    );
  }
}

MaterialPageRoute<dynamic> homePageRoute(ActGymRecord actsAndGyms) {
  return MaterialPageRoute(
    builder: (context) => HomePage(
      postPageActs: actsAndGyms.activities,
      postPageGyms: actsAndGyms.gyms,
      viewModel: HomePageViewModel(),
    ),
  );
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

class ImageBig {
  const ImageBig(this.context, this.image);

  final BuildContext context;
  final ImageProvider<Object>? image;

  SafeArea buildImage() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BottomSheetHandle().alignCenter,
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ImageFade(
                image: image,
                placeholder: Container(
                  color: Colors.black,
                ),
              ),
            ),
          )
        ]
      )
    );
  }

  void showImageInBig() {
    BottomSheetUtils.showBottomSheet(
      context: context,
      borderRadius: BorderRadius.circular(16),
      config: WrapBottomSheetConfig(
        builder: (context, controller) {
          return buildImage();
        },
      ),
    );
  }
}

class HorizontalImageViewer extends StatelessWidget {
  const HorizontalImageViewer({
    super.key,
    required this.showImages,
    required this.images,
    required this.isPost,
    this.context
  });

  final bool showImages;
  final List<dynamic> images;
  final bool isPost;
  final BuildContext? context;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: showImages ? 150 : 0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        children: [
        for (final el in images)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: GestureDetector(
              onTap: () {
                final imgb = ImageBig(context, isPost ? FileImage(File(el.path)) : NetworkImage(el));
                imgb.showImageInBig();
              },
              child: SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: ImageFade(
                      image: isPost ? FileImage(File(el.path)) : NetworkImage(el),
                      placeholder: Container(
                        width: 180,
                        height: 150,
                        color: Colors.black,
                      ),
                    )
                  ),
                ),
              ),
            ),
          ),
      ],),
    );
  }
}

class ProfilePicPlaceholder extends StatelessWidget {
  const ProfilePicPlaceholder({super.key, required this.radius});
  
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Color.fromARGB(255, 14, 22, 29),
    );
  }
}

class ProgressBtn extends StatelessWidget {
  const ProgressBtn({
    super.key,
    required this.onPressedFn,
    required this.child
  });

  final dynamic onPressedFn;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProgressButton(
      onPressed: onPressedFn,
      loadingType: ProgressButtonLoadingType.replace,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.secondary),
        foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onSecondary),
        textStyle: WidgetStatePropertyAll(
          TextStyle(
            fontWeight: FontWeight.bold
          )
        )
      ),
      type: ProgressButtonType.filled,
      child: child,
    );
  }
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
Future<ActGymRecord> getActivitiesAndGyms() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final allGyms = await getAllGymsWithProps(db.collection('gyms/budapest/gyms'));
  sortGymsByName(allGyms);

  final allActivities = await getAllActivitiesWithoutProps(db.collection('activities'));
  allActivities.sort();
  return (activities: allActivities, gyms: allGyms);
}

class ValidatePassword {
  ValidatePassword(
    this._password,
    this._passwordConf,
  );
  final String _password;
  final String _passwordConf;

  (bool isValid, String errorMsg) isValidPassword() {
    if (_password.isEmpty || _passwordConf.isEmpty) {
      return (false, SignupConsts.allFieldsText);
    } else if (_password != _passwordConf) {
      return (false, SignupConsts.passwordMismatchText);
    } else if (_password.length < ValidateSignupConsts.maxPasswordLength) {
      return (false, SignupConsts.passwordLengthText);
    }
    return (true, '');
  }
}