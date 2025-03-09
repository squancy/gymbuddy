import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/data/repository/search/search_repository.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:circular_buffer/circular_buffer.dart';
import 'dart:async';

enum SearchStates {
  emptySearch, // the search bar is in focus but no text is entered
  textSearch, // the search bar is in focus with text
  noSearch // the search bar is not in focus
}

typedef UserData = ({
  String profilePicUrl,
  String displayUsername, 
  String username,
  String userID
});

class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required searchRepository,
    required searchController,
  }) :
  _searchRepository = searchRepository,
  _searchController = searchController;

  final SearchRepository _searchRepository;
  final TextEditingController _searchController;

  static final HitCache cache = HitCache(
    cache: CircularBuffer<Map<String, dynamic>>(HomePageConsts.cacheSize)
  );
  static String latestQuery = '';
  static bool cacheHit = false;
  static SearchStates curSearchState = SearchStates.noSearch;
  DateTime _prevTime = DateTime.now();
  String _prevText = '';
  Timer? _timer;

  Stream<List<Map<String, dynamic>>> get combinedUserStream {
    return _searchRepository.combinedUserStream;
  }

  HitsSearcher get hitsSearcherUserSettings {
    return _searchRepository.hitsSearcherUserSettings;
  }

  Future<UserData> getUserInfo(Map<String, dynamic> hit, bool cached) async {
    return await _searchRepository.getUserInfo(
      hit: hit,
      cached: cached,
      cache: cache,
      latestQuery: latestQuery
    );
  }

  /// Filters results by a unique ID given the hits from "users" and "user settings"
  List<Map<String, dynamic>> filterUnique(List<Map<String, dynamic>> hits) {
    List<Map<String, dynamic>> res = [];
    for (final hit in hits) {
      if (!res.map((el) => el['objectID']).contains(hit['objectID'])) {
        res.add(hit);
      }
    }
    return res;
  }

  void _setSearchState() {
    if (_searchController.text.isEmpty &&
      curSearchState != SearchStates.emptySearch) {
      curSearchState = SearchStates.emptySearch;
      notifyListeners();
    } else if (_searchController.text.isNotEmpty &&
      curSearchState != SearchStates.textSearch) {
      curSearchState = SearchStates.textSearch;
      notifyListeners();
    }
  }

  /// Update search state with the current value in the search field
  void _applySearchState() {
    latestQuery = _searchController.text;
    for (final searcher in [
      _searchRepository.hitsSearcherUser,
      _searchRepository.hitsSearcherUserSettings]) {
      searcher.applyState((state) {
        return state.copyWith(query: latestQuery, page: 0, hitsPerPage: 5);
      });
    }
  }

  void setPrevTime() {
    _prevTime = DateTime.now();
  }

  /// Only make API calls if there is a minimum elapsed time between two consecutive
  /// key types and the text is different that what was previously
  void query() {
    if (DateTime.now().difference(_prevTime).inMilliseconds > 200 &&
      _prevText != _searchController.text) {
      _applySearchState();
      _setSearchState();
      notifyListeners();
      _prevText = _searchController.text;
    }
  }

  void init() {
    _searchController.addListener(setPrevTime);
    _timer = Timer.periodic(
      Duration(milliseconds: 10),
      (Timer t) => query()
    );
  }
  
  @override
  void dispose() {
    super.dispose();
    _searchController.removeListener(setPrevTime);
    _timer?.cancel();
  }
}