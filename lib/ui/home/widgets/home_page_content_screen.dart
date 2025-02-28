import 'package:flutter/material.dart';
import 'package:gym_buddy/search/default_search.dart' as default_search;
import 'package:gym_buddy/ui/home/view_models/home_page_content_view_model.dart';

class HomePageContent extends StatefulWidget {
  const HomePageContent({
    required this.viewModel,
    super.key
  });
  
  final HomePageContentViewModel viewModel;

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          scrolledUnderElevation: 0,
        )
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            // Search bar
            child: SearchAnchor( 
              builder: (BuildContext context, SearchController controller) {
                return SearchBar(
                  controller: widget.viewModel.searchController,
                  padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 15, vertical: 0)),
                  leading: Icon(Icons.search, color: Theme.of(context).colorScheme.secondary,),
                  backgroundColor: WidgetStatePropertyAll<Color>(Colors.black),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))
                    )
                  ),
                  onTapOutside: (event) {
                    widget.viewModel.searchFocus.unfocus();      
                  },
                  trailing: <Widget>[
                    IconButton(
                      onPressed: () {
                        setState(() {
                          widget.viewModel.searchController.text = '';
                        });
                      },
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                      )
                    )
                  ],
                  focusNode: widget.viewModel.searchFocus,
                  hintText: 'Search', 
                  hintStyle: WidgetStatePropertyAll(
                    TextStyle(
                      color: Theme.of(context).colorScheme.secondary
                    )
                  ),
                );
              },
              suggestionsBuilder: (BuildContext context, SearchController controller) {
                return [Container()]; // not used
              }
            ),
          ),
          Expanded(
            child: SingleChildScrollView( 
              child: Column(
                children: [
                  default_search.DefaultSearch(
                    key: UniqueKey(),
                    searchController: widget.viewModel.searchController,
                    searchFocus: widget.viewModel.searchFocus
                  )
                ],
              ),
            )
          )
        ],
      )
    );
  }
}
