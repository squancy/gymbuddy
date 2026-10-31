import 'package:flutter/material.dart';

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