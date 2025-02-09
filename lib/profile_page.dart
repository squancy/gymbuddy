import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/main.dart';
import 'consts/common_consts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'utils/photo_upload_popup.dart';
import 'utils/upload_image_firestorage.dart';
import 'utils/helpers.dart' as helpers;
import 'utils/post_builder.dart' as post_builder;
import 'package:image_fade/image_fade.dart';
import 'consts/common_consts.dart' as consts;
import 'package:gym_buddy/utils/mocks.dart';

final FirebaseFirestore db = FirebaseFirestore.instance; // Get Firestore instance
final storageRef = FirebaseStorage.instance.ref(); // Get Firebase Storage instance

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class Toggle {
  final ValueNotifier<bool> showEdit = ValueNotifier<bool>(false);

  void makeEditable() {
    showEdit.value = true;
  }

  void makeUneditable() {
    showEdit.value = false;
  }
}

// Profile photo widget
class ProfilePhoto extends StatefulWidget {
  const ProfilePhoto({super.key});

  @override
  State<ProfilePhoto> createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends State<ProfilePhoto> {
  var _image = File(ProfileConsts.defaultProfilePicPath);
  final _picker = ImagePicker();
  bool _showFile = false;

  /// Upload the profile picture to Firebase Storage
  Future<void> _uploadPic(File file, String? userID) async {
    var (String downloadURL, String filename) = await UploadImageFirestorage(storageRef).uploadImage(file, ProfileConsts.profilePicSize, "profile_pics/$userID"); 
    final settingsDocRef = db.collection('user_settings').doc(userID);
    try {
      await settingsDocRef.update({
        'profile_pic_path': filename,
        'profile_pic_url': downloadURL
      });
    } catch (e) {
      // ...
    }
  }

  /// Select an image from the gallery or camera
  void _selectFromSource(ImageSource sourceType) async {
    final pickedFile = await _picker.pickImage(source: sourceType);
    final userID = await helpers.getUserID();
    if (pickedFile != null) {
      _uploadPic(File(pickedFile.path), userID);
    }

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _showFile = true;
      }
    });
  }

  /// Image selection mock (select default profile pic)
  void _selectFromSourceMock(ImageSource sourceType) async {
    File file = await getDefaultProfilePicAsFile();
    _uploadPic(file, await helpers.getUserID());
    setState(() {
      _image = file;
      _showFile = true;
    });
  }

  /// Get the profile picture URL
  Future<String> _getProfilePicURL() async {
    final userID = await helpers.getUserID();
    final settingsDocRef = db.collection('user_settings').doc(userID);
    final usettings = await settingsDocRef.get();
    final userSettings = usettings.data() as Map<String, dynamic>;
    return userSettings['profile_pic_url'];
  }

  /// Get the profile picture file type(= url if not empty) and path (default if url is empty)
  Future<Map<String, String>> _getProfilePicFile() async {
    final profilePicURL = await _getProfilePicURL();
    if (profilePicURL.isEmpty) {
      return {'type': 'default', 'path': ProfileConsts.defaultProfilePicPath};
    }
    return {'type': 'url', 'path': profilePicURL};
  }

  // Build the profile photo widget
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getProfilePicFile(),
      builder: (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
        final uploadPopup = PhotoUploadPopup(context, consts.GlobalConsts.test ? _selectFromSourceMock : _selectFromSource);
        if (snapshot.hasData) {
          dynamic bgImage;
          if (snapshot.data?['type'] == 'default') {
            bgImage = AssetImage(snapshot.data?['path'] as String);
          } else {
            bgImage = NetworkImage(snapshot.data?['path'] as String);
          }
          return GestureDetector(
            onDoubleTap: uploadPopup.showOptions,
            child: Builder(
              builder: (context) {
                return SizedBox(
                  width: 80,
                  height: 80,
                  child: ClipOval(
                    child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                      child: ImageFade(
                        key: const Key('profilePic'),
                        image: _showFile ? FileImage(_image) : bgImage,
                        placeholder: Container(
                          width: 80,
                          height: 80,
                          color: Colors.black,
                        ),
                      )
                    ),
                  ),
                );
              }
            ),
          );
        } else {
          return helpers.ProfilePicPlaceholder(radius: 40,);
        }
      }
    );
  }
}

class _ProfilePageState extends State<ProfilePage> {
  final _toggleEditDUname = Toggle();
  final _toggleEditBio = Toggle();
  final _controller = TextEditingController();
  final _bioController = TextEditingController();
  var  _lastVisible;
  var _lastVisibleNum = 1;
  bool _isFirst = true;
  var _firstVisible;
  var _getPostsByUserFuture;
  var _getUserDataFuture;
  final FocusNode _bioFocusNode = FocusNode();
  final FocusNode _displayUnameFocusNode = FocusNode();
  final _bottomScrollController = ScrollController();
  List<Map<String, dynamic>> _res = [];
  int _totalNumberOfPosts = 0;

  @override
  void initState() {
    super.initState();
    _getUserDataFuture = _getUserData();
    _bottomScrollController.addListener(() {
      if (_bottomScrollController.position.atEdge) {
        bool isTop = _bottomScrollController.position.pixels == 0;
        if (!isTop && _lastVisibleNum < _totalNumberOfPosts) {
          setState(() {
            _getPostsByUserFuture = _getPostsByUser();
          });
        }
      }
    });
  }

  /// Get the posts by the user from db
  Future<List<Map<String, dynamic>>> _getPostsByUser() async {
    if (_lastVisible == null) return [];
    String? userID = await helpers.getUserID();
    List<QueryDocumentSnapshot<Map<String, dynamic>>> userPostDocs;
    try {
      var userPosts = await db.collection('posts')
        .where('author', isEqualTo: userID)
        .orderBy('date', descending: true)
        .startAfterDocument(_lastVisible)
        .limit(consts.ProfileConsts.paginationNum).get();
      userPostDocs = userPosts.docs;
      if (_isFirst) {
        userPostDocs.insert(0, _lastVisible);
      }
      _isFirst = false;
      _lastVisible = userPosts.docs.isEmpty ? null : userPosts.docs[userPosts.docs.length - 1];
      _lastVisibleNum += userPosts.docs.length;
    } catch (e) {
      print(e);
      return [];
    }
    _res += (await post_builder.createDataForPosts(userPostDocs));
    return _res;
  }

  /// Set the last visible post to the first post
  Future<void> _setLastVisibleToFirst(userID) async {
    var userPosts = await db.collection('posts')
      .where('author', isEqualTo: userID)
      .orderBy('date', descending: true)
      .limit(1).get();
    _lastVisible = userPosts.docs.isEmpty ? null : userPosts.docs[0];
    _firstVisible = _lastVisible;
  }

  /// Get the user data from db
  Future<Map<String, dynamic>> _getUserData() async {
    // First get the ID of the user currently logged in 
    final userID = await helpers.getUserID();
    final users = db.collection('users');
    final settingsDocRef = db.collection('user_settings').doc(userID);
    _totalNumberOfPosts = (await db.collection('posts').where('author', isEqualTo: userID).count().get()).count as int;

    final QuerySnapshot userWithUID = await users.where('id', isEqualTo: userID).get();

    final user = userWithUID.docs[0].data() as Map<String, dynamic>;

    final usettings = await settingsDocRef.get();
    /*
      NOTE: the next line may hang forever since if usettings.data() is null
      This can happen (although infrequently) when using the emulator
      In the production database this is not a problem
    */
    final userSettings = usettings.data() as Map<String, dynamic>;

    await _setLastVisibleToFirst(userID);
    _getPostsByUserFuture = _getPostsByUser();

    return {
      'username': user['username'],
      'displayUsername': userSettings['display_username'],
      'bio': userSettings['bio'],
      'userID': userID
    };
  }

  /// Save the new data to the db
  Future<void> _saveNewData(String newData, int maxLen, String fieldName, {required bool isBio}) async {
    if (Characters(newData).length > maxLen) {
      return;
    }

    final userID = await helpers.getUserID();
    final settingsDocRef = db.collection('user_settings').doc(userID);

    try {
      await settingsDocRef.update({fieldName: newData});
    } catch (e) {
      // ...
      print(e);
    }
  }

  // Dispose the controllers & focus nodes
  @override
  void dispose() {
    _controller.dispose();
    _bioController.dispose();
    _bioFocusNode.dispose();
    _displayUnameFocusNode.dispose();
    super.dispose();
  } 

  // Build the profile page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
        )
      ),
      body: FutureBuilder(
        future: _getUserDataFuture,
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.hasData && snapshot.data != null && snapshot.connectionState == ConnectionState.done) {
            final Map<String, dynamic> data = snapshot.data as Map<String, dynamic>;
            final String username = data['username'];
            var displayUsername = data['displayUsername'] as String;
            var bio = data['bio'] as String;
            bool emptyUname = displayUsername.isEmpty;

            Future<void> resetToTxt({
              required Toggle toggle,
              required TextEditingController controller,
              required int maxLen,
              required String fieldName,
              required bool isBio}) async {
              if (toggle.showEdit.value) {
                if (controller.text.isNotEmpty) toggle.makeUneditable();
                await _saveNewData(controller.text, maxLen, fieldName, isBio: isBio);
              }
            }

            Future<void> finishEdit({
              required Toggle toggle,
              required TextEditingController controller,
              required int maxLen,
              required String fieldName,
              required bool isBio}) async {
              resetToTxt(
                toggle: toggle,
                controller: controller,
                maxLen: maxLen,
                fieldName: fieldName,
                isBio: isBio
              );
              await _saveNewData(controller.text, maxLen, fieldName, isBio: isBio);
            }

            Widget buildBioField({required bool autofocus}) {
              return TextField(
                key: const Key('bioField'),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: ProfileConsts.bioDefaultText,
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  counterText: '',
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                autofocus: autofocus,
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 0,
                  height: 1.4
                ),
                controller: _bioController,
                maxLines: null,
                onChanged: (value) {
                  bio = _bioController.text;
                },
                onEditingComplete: () {
                  finishEdit(
                    toggle: _toggleEditBio,
                    controller: _bioController,
                    maxLen: ProfileConsts.maxBioLength,
                    fieldName: 'bio',
                    isBio: true
                  );
                },
                onSubmitted: (context) {
                  finishEdit(
                    toggle: _toggleEditBio,
                    controller: _bioController,
                    maxLen: ProfileConsts.maxBioLength,
                    fieldName: 'bio',
                    isBio: true
                  );
                },
                onTapOutside: (event) {
                  finishEdit(
                    toggle: _toggleEditBio,
                    controller: _bioController,
                    maxLen: ProfileConsts.maxBioLength,
                    fieldName: 'bio',
                    isBio: true
                  );
                },
                focusNode: _bioFocusNode,
              );
            }

            return ListView(
              controller: _bottomScrollController,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            TapRegion(
                              onTapOutside: (tap) async {
                                if (_controller.text.isEmpty) {
                                  _displayUnameFocusNode.unfocus();      
                                } else {
                                  if (_toggleEditDUname.showEdit.value) displayUsername = _controller.text;
                                  await resetToTxt(
                                    toggle: _toggleEditDUname,
                                    controller: _controller,
                                    maxLen: ValidateSignupConsts.maxUsernameLength,
                                    fieldName: 'display_username',
                                    isBio: false
                                  );
                                }
                                emptyUname = _controller.text.isEmpty;
                                /*
                                setState(() {
                                  _getUserDataFuture = _getUserData();
                                  _lastVisible = _firstVisible;
                                  _isFirst = true;
                                });
                                */
                              },
                              child: GestureDetector(
                                onDoubleTap: () {
                                  _toggleEditDUname.makeEditable();
                                  _controller.text = displayUsername;
                                },
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: _toggleEditDUname.showEdit,
                                  builder: (context, value, child) {
                                    if (displayUsername.isEmpty) {
                                      _toggleEditDUname.makeEditable();
                                    }
                                    if (_toggleEditDUname.showEdit.value) {
                                      return TextField(
                                        key: const Key('displayUnameField'),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          counterText: '',
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          hintText: ProfileConsts.emptyDisplayUnameText,
                                          hintStyle: TextStyle(
                                            color: Colors.grey,
                                          )
                                        ),
                                        controller: _controller,
                                        focusNode: _displayUnameFocusNode,
                                        autofocus: !emptyUname,
                                        maxLength: 100,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0,
                                        ),
                                        onChanged: (value) {
                                          displayUsername = _controller.text;
                                        },
                                        onEditingComplete: () {
                                          finishEdit(
                                            toggle: _toggleEditDUname,
                                            controller: _controller,
                                            maxLen: ValidateSignupConsts.maxUsernameLength,
                                            fieldName: 'display_username',
                                            isBio: false
                                          );
                                        },
                                        onSubmitted: (context) {
                                          finishEdit(
                                            toggle: _toggleEditDUname,
                                            controller: _controller,
                                            maxLen: ValidateSignupConsts.maxUsernameLength,
                                            fieldName: 'display_username',
                                            isBio: false
                                          );
                                        },
                                        onTapOutside: (event) {
                                          finishEdit(
                                            toggle: _toggleEditDUname,
                                            controller: _controller,
                                            maxLen: ValidateSignupConsts.maxUsernameLength,
                                            fieldName: 'display_username',
                                            isBio: false
                                          );
                                        },
                                      );
                                    } else {
                                      // Username display
                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                        child: Text(displayUsername, style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0,
                                        )),
                                      );
                                    }
                                  }),
                                ),
                            ),
                              Text("@$username")
                            ],
                          ),),
                          Column(
                            // Profile photo and logout button
                            children: [
                              ProfilePhoto(),
                              SizedBox(height: 10,),
                              GestureDetector(
                                onTap: () async {
                                  await helpers.logout();
                                  setState(() {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) => WelcomePage(),
                                      ),
                                      (Route<dynamic> route) => false,
                                    );
                                  });
                                },
                                child: Icon(Icons.logout_rounded, size: 20, color: Theme.of(context).colorScheme.primary,),
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
                // Bio
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                  child: Builder(
                    builder: (context) {
                      if (bio.isEmpty) {
                        _toggleEditBio.makeEditable();
                      }
                      return TapRegion(
                        onTapOutside: (tap) async {
                          if (_bioController.text.isEmpty) {
                            _bioFocusNode.unfocus();      
                          } else {
                            if (_toggleEditBio.showEdit.value) bio = _bioController.text;
                            await resetToTxt(
                              toggle: _toggleEditBio,
                              controller: _bioController,
                              maxLen: ProfileConsts.maxBioLength,
                              fieldName: 'bio',
                              isBio: true
                            );
                          }
                        },
                        child: GestureDetector(
                          onDoubleTap: () {
                            if (bio.isEmpty) return;
                            _toggleEditBio.makeEditable();
                            _bioController.text = bio;
                          },
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _toggleEditBio.showEdit,
                            builder: (context, value, child) {
                              if (_toggleEditBio.showEdit.value) {
                                return buildBioField(autofocus: bio.isNotEmpty);
                              } else {
                                return Text(
                                  bio,
                                  style: TextStyle(letterSpacing: 0, height: null),
                                );
                              }
                            }
                          ),
                        ),
                      );
                    },
                  ),
                ), 
                Divider(
                  color: Colors.white12
                ),
                FutureBuilder(
                  future: _getPostsByUserFuture,
                  builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    List<Widget> posts = [];
                    if (snapshot.hasData && snapshot.data != null) {
                      for (final post in snapshot.data!) {
                        posts.add(
                          post_builder.postBuilder(post, displayUsername, context)
                        );
                      }
                      return Column(
                        children: posts, // Posts
                      );
                    } else {
                      return Center(
                        child: GlobalConsts.spinkit,
                      );
                    }
                  }
                )
              ],
            );
          } else {
            return Center(
              child: GlobalConsts.spinkit,
            );
          }
        }
      )
    );
  }
}