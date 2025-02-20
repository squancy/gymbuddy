import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'post_page.dart';
import 'utils/helpers.dart' as helpers;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'dart:async';
import 'package:gym_buddy/search/default_search.dart' as default_search;

final FirebaseFirestore db = FirebaseFirestore.instance;

class HomePage extends StatefulWidget {
  final List<String> postPageActs;
  final List<Map<String, dynamic>> postPageGyms;

  const HomePage({
    required this.postPageActs,
    required this.postPageGyms,
    super.key
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  Future<Object> fetchPosts() async {
    // First get the geoloc of the user (if possible) and update it in db
    Position? geoloc = await helpers.getGeolocation(); 
    String? userID = await helpers.getUserID(); 
    if (geoloc != null) {
      try {
        final geoPoint = GeoFirePoint(GeoPoint(geoloc.latitude, geoloc.longitude));
        db.collection('users').doc(userID).update({'geoloc': geoPoint.data}); 
      } catch (e) {
        // print(e);
      }
    }

    return {};
  }

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

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
                  controller: _searchController,
                  padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 15, vertical: 0)),
                  leading: Icon(Icons.search, color: Theme.of(context).colorScheme.secondary,),
                  backgroundColor: WidgetStatePropertyAll<Color>(Colors.black),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))
                    )
                  ),
                  onTapOutside: (event) {
                    _searchFocus.unfocus();      
                  },
                  focusNode: _searchFocus,
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
                    searchController: _searchController,
                    searchFocus: _searchFocus
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

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; 

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index; 
    });
  } 

  final List<TabItem> items = [
    TabItem(
      icon: Icons.home,
      title: 'Home',
    ),
    TabItem(
      icon: Icons.add_box_rounded,
      title: 'Post',
    ),
    TabItem(
      icon: Icons.people_alt_rounded,
      title: 'Buddies',
    ),
    TabItem(
      icon: Icons.account_box,
      title: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('homepage'),
      extendBody: true,
      body: Center(
        child: [
          HomePageContent(),
          PostPage(postPageActs: widget.postPageActs, postPageGyms: widget.postPageGyms),
          Container(),
          ProfilePage()
        ][_selectedIndex], 
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(30), 
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(30)) 
          ),
          clipBehavior: Clip.hardEdge,
          child: BottomBarFloating(
            items: items,
            backgroundColor: Colors.black,
            color: Theme.of(context).colorScheme.primary,
            colorSelected: Theme.of(context).colorScheme.tertiary,
            indexSelected: _selectedIndex,
            onTap: _onItemTapped,
            duration: Duration(milliseconds: 200), 
            titleStyle: TextStyle(
              letterSpacing: 0,
            ),
            pad: 1,
            animated: false,
            paddingVertical: 8,
            iconSize: 18,
          ),
        ),
      ),
    );
  }
}