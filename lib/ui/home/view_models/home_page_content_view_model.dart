import 'package:flutter/material.dart';
import 'package:gym_buddy/data/repository/home/home_page_content_repository.dart';

class HomePageContentViewModel extends ChangeNotifier {
  HomePageContentViewModel({
    required homePageContentRepository
  }) :
  _homePageContentRepository = homePageContentRepository;

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  final HomePageContentRepository _homePageContentRepository;

  Future<Object> fetchPosts() async {
    return _homePageContentRepository.fetchPosts();
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
    searchFocus.dispose();
  }
}