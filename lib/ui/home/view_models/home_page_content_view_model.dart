import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gym_buddy/data/repository/home/home_page_content_repository.dart';
import 'package:gym_buddy/consts/common_consts.dart';

class HomePageContentViewModel extends ChangeNotifier {
  HomePageContentViewModel({
    required homePageContentRepository
  }) :
  _homePageContentRepository = homePageContentRepository;
  List<Map<String, dynamic>> nearbyPosts = [];
  bool get wantKeepAlive => true;
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  final HomePageContentRepository _homePageContentRepository;
  ValueNotifier <LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  bool dataLoaded = false;

  Future<void> fetchPosts() async {
    await _homePageContentRepository.updateLocation();
    await _homePageContentRepository.fetchData();
    dataLoaded = true;
    nearbyPosts = _homePageContentRepository.nearbyPosts;
    loadingState.value = LoadingState.done;
  }


  

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
    searchFocus.dispose();
  }
}