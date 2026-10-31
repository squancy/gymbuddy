import 'package:flutter/material.dart';
import 'package:gym_buddy/data/repository/search/search_repository.dart';
import 'package:gym_buddy/ui/search/view_models/search_view_model.dart';
import 'package:gym_buddy/ui/search/widgets/search_screen.dart';

class SearchExtendedScreen extends StatefulWidget {
  const SearchExtendedScreen({
    required this.searchQuery,
    super.key
  });

  final String searchQuery;

  @override
  State<SearchExtendedScreen> createState() => _SearchExtendedScreenState();
}

class _SearchExtendedScreenState extends State<SearchExtendedScreen> {
  @override
  Widget build(BuildContext context) {
    /*
    return SearchColumn(
      hits: widget.hits,
      shouldCache: true,
      viewModel: SearchViewModel(
        searchRepository: SearchRepository(),
        searchController: searchController
      )
    );
    */
    return Scaffold(

    );
  }
}