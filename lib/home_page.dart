import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'profile_page.dart';
import 'post_page.dart';
import 'utils/helpers.dart' as helpers;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'utils/post_builder.dart' as post_builder;

final FirebaseFirestore db = FirebaseFirestore.instance;

class HomePage extends StatefulWidget {
  final List<String> postPageActs;
  final List<Map<String, dynamic>> postPageGyms;

  const HomePage({required this.postPageActs, required this.postPageGyms, super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});
  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  GeoFirePoint? geoPoint;
  List<String> nearbyGyms = [];
  List<Map<String, dynamic>> nearbyPosts = [];
  Future<void>? _fetchDataFuture;
  bool _dataLoaded = false;
  double _currentRadius = 1.0;
  final ScrollController _scrollController = ScrollController();
  Position? _lastKnownPosition;
  StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>>? gymSubscription;

  @override
void initState() {
  super.initState();
  if (!_dataLoaded) {
    print("Data was not loaded");
    _fetchDataFuture = _fetchData().then((_) {
      _dataLoaded = true;
    });
  }
}


  Future<void> _fetchData() async {
  if (_dataLoaded) return;  // Prevent unnecessary fetching
  Position? geoloc = await helpers.getGeolocation();
  if (geoloc == null) return;
  
  await fetchPosts(geoloc);
  await fetchNearbyGyms(geoloc);
}


 Future<void> _onRefresh() async {
  setState(() {
    _dataLoaded = false;
  });
  await _fetchData();
}


  Future<void> fetchPosts(Position geoloc) async {
    String? userID = await helpers.getUserID();
    if (userID == null) return;
    if (_lastKnownPosition != null) {
      double distance = Geolocator.distanceBetween(
        _lastKnownPosition!.latitude, _lastKnownPosition!.longitude,
        geoloc.latitude, geoloc.longitude,
      );
      if (distance < 100) return;
    }
    try {
      geoPoint = GeoFirePoint(GeoPoint(geoloc.latitude, geoloc.longitude));
      await db.collection('users').doc(userID).update({'geoloc': geoPoint!.data});
      _lastKnownPosition = geoloc;
    } catch (e) {
      print("Error updating user location: $e");
    }
  }

  Future<void> fetchNearbyGyms(Position geoloc) async {
    GeoFirePoint userGeoPoint = GeoFirePoint(GeoPoint(geoloc.latitude, geoloc.longitude));
    final collectionReference = db.collection('gyms').doc('budapest').collection('gyms');

    gymSubscription?.cancel();
    gymSubscription = GeoCollectionReference<Map<String, dynamic>>(collectionReference)
        .subscribeWithin(
          center: userGeoPoint,
          radiusInKm: _currentRadius,
          field: 'geoloc',
          geopointFrom: (data) => (data['geoloc'] as Map<String, dynamic>?)?['geopoint'] as GeoPoint? ?? GeoPoint(0, 0),
        )
        .listen((snapshots) async {
          print("Gyms were fetched");
          if (snapshots.isEmpty) return;
          nearbyGyms = snapshots.map((doc) => doc.id).toList();
          await fetchPostsForNearbyGyms();
          await _getUserDataForPostById();
        }, onError: (e) => print("Error fetching gyms: $e"));
  }

  Future<void> fetchPostsForNearbyGyms() async {
    if (nearbyGyms.isEmpty) return;
    nearbyPosts.clear();
    for (var gymBatch in _chunkList(nearbyGyms, 10)) {
      try {
        final postsQuery = db.collection('posts')
            .where('gym', whereIn: gymBatch)
            .orderBy('date', descending: true)
            .limit(50);
        final postsSnapshot = await postsQuery.get();
        nearbyPosts.addAll(postsSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
      } catch (e) {
        print("Error fetching posts: $e");
      }
    }
  }

  Future<void> _getUserDataForPostById() async {
    Set<String> userIDs = {for (var post in nearbyPosts) post['author'] as String};
    if (userIDs.isEmpty) return;
    List<String> userList = userIDs.toList();
    Map<String, Map<String, dynamic>> userSettingsMap = {};
    try {
      for (var batch in _chunkList(userList, 30)) {
        final usersSnapshot = await db.collection('user_settings').where(FieldPath.documentId, whereIn: batch).get();
        for (var doc in usersSnapshot.docs) {
          userSettingsMap[doc.id] = doc.data();
        }
      }
      for (var post in nearbyPosts) {
        final userSettings = userSettingsMap[post['author']];
        if (userSettings != null) {
          post['displayUsername'] = userSettings['display_username'];
          post['profilePic'] = userSettings['profile_pic_url'];
        }
      }
      setState(() {});
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

@override
Widget build(BuildContext context) {
  super.build(context);
  return Scaffold(
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(0),
      child: AppBar(
        scrolledUnderElevation: 0,
      ),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: SearchAnchor(
            builder: (BuildContext context, SearchController controller) {
              return SearchBar(
                controller: controller,
                padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 15, vertical: 0)),
                leading: Icon(Icons.search, color: Theme.of(context).colorScheme.secondary),
                backgroundColor: WidgetStatePropertyAll<Color>(Colors.black),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                onTapOutside: (event) {
                  FocusScope.of(context).unfocus();
                },
                hintText: 'Search',
                hintStyle: WidgetStatePropertyAll(
                  TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
              );
            },
            suggestionsBuilder: (BuildContext context, SearchController controller) {
              return [Container()];
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<void>(
            future: _fetchDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: GlobalConsts.spinkit);
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: nearbyPosts.length,
                  itemBuilder: (context, index) => post_builder.postBuilder(nearbyPosts[index], DisplayUsername.uname, context),
                ),
              );
            },
          ),
        ),
      ],
    ),
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
      body: IndexedStack(
  index: _selectedIndex,
  children: [
    HomePageContent(),
    PostPage(postPageActs: widget.postPageActs, postPageGyms: widget.postPageGyms),
    Container(), // Empty widget for the Buddies page
    ProfilePage(),
  ],
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