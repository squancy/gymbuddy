import 'package:flutter/material.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';
import 'package:gym_buddy/data/repository/post_builder/post_builder_repository.dart';
import 'package:gym_buddy/data/repository/profile/profile_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/consts/common_consts.dart';

class ProfilePageViewModel extends ChangeNotifier {
  ProfilePageViewModel({
    required profileRepository,
    required commonRepository,
    required postBuilderRepository
  }) :
  _profileRepository = profileRepository,
  _commonRepository = commonRepository,
  _postBuilderRepository = postBuilderRepository;

  final ProfileRepository _profileRepository;
  final CommonRepository _commonRepository;
  final PostBuilderRepository _postBuilderRepository;

  QueryDocumentSnapshot<Map<String, dynamic>>? _lastVisible;
  int _lastVisibleNum = 1;
  bool _isFirst = true;
  Future<List<Map<String, dynamic>>>? getPostsByUserFuture;
  Future<Map<String, dynamic>>? getUserDataFuture;
  List<Map<String, dynamic>> _res = [];
  int _totalNumberOfPosts = 0;
  ValueNotifier<PageTransition> pageTransition = ValueNotifier(PageTransition.stayOnPage);
  final bottomScrollController = ScrollController();

  /// Get the posts by the user from db
  Future<List<Map<String, dynamic>>> getPostsByUser(String userID) async {
    if (_lastVisible == null) return [];
    var userPosts = await _profileRepository.getUserPosts(
      userID: userID,
      lastVisible: _lastVisible
    );
    _isFirst = false;
    _lastVisible = userPosts.docs.isEmpty ?
      null :
      userPosts.docs[userPosts.docs.length - 1];
    _lastVisibleNum += userPosts.docs.length;
    List<QueryDocumentSnapshot<Map<String, dynamic>>> userPostDocs = _profileRepository.getUserPostDocs(
      userPosts: userPosts,
      isFirst: _isFirst,
      lastVisible: _lastVisible
    );
    _res += (await _postBuilderRepository.createDataForPosts(userPostDocs));
    return _res;
  }

  /// Set the last visible post to the first post
  Future<void> _setLastVisibleToFirst(userID) async {
    final userPosts = await _profileRepository.getLastPostByUser(
      userID: userID
    );
    _lastVisible = userPosts.docs.isEmpty ? null : userPosts.docs[0];
  }

  /// Get the user data from db
  Future<Map<String, dynamic>> _getUserData(String userID) async {
    // First get the ID of the user currently logged in 
    _totalNumberOfPosts = await _profileRepository.getTotalNumOfPostsByUser(
      userID: userID
    );

    final user = (await _profileRepository.getUser(userID: userID))
      .docs[0]
      .data() as Map<String, dynamic>;

    final userSettings = (await _profileRepository.getUserSettings(userID: userID))
      .data() as Map<String, dynamic>;
    /*
      NOTE: the next line may hang forever since if usettings.data() is null
      This can happen (although infrequently) when using the emulator
      In the production database this is not a problem
    */

    await _setLastVisibleToFirst(userID);
    getPostsByUserFuture = getPostsByUser(userID);

    return {
      'username': user['username'],
      'displayUsername': userSettings['display_username'],
      'bio': userSettings['bio']
    };
  }

  void _setFuture(String userID) {
    getPostsByUserFuture = getPostsByUser(userID);
    notifyListeners();
  }

  void logout() async {
    await _commonRepository.logout();
    pageTransition.value = PageTransition.goToNextPage;
  }

  void init(String userID) {
    getUserDataFuture = _getUserData(userID);
    bottomScrollController.addListener(() {
      if (bottomScrollController.position.atEdge) {
        bool isTop = bottomScrollController.position.pixels == 0;
        if (!isTop &&
          _lastVisibleNum < _totalNumberOfPosts) {
          _setFuture(userID);
        }
      }
    });
  }
}