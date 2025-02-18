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

// Get the Firestore instance
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
  GeoFirePoint? geoPoint;
  List<String> nearbyGyms = [];
  List<Map<String, dynamic>> nearbyPosts = [];
  late Future<void> _fetchDataFuture;

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = _fetchData();
  }

  Future<void> _fetchData() async {
  Position? geoloc = await helpers.getGeolocation();
  if (geoloc == null) return;

  await fetchPosts(geoloc);
  await fetchNearbyGyms(geoloc);
}
  Future<void> fetchPosts(Position geoloc) async {
  String? userID = await helpers.getUserID();
  if (userID == null) return;

  try {
    geoPoint = GeoFirePoint(GeoPoint(geoloc.latitude, geoloc.longitude));
    await db.collection('users').doc(userID).update({'geoloc': geoPoint!.data});
  } catch (e) {
    print("Error updating user location: $e");
  }
}


  Future<void> fetchNearbyGyms(Position geoloc) async {
  print("User location: ${geoloc.latitude}, ${geoloc.longitude}");
  GeoFirePoint userGeoPoint = GeoFirePoint(GeoPoint(geoloc.latitude, geoloc.longitude));

  final radius = 10.0; 
  final collectionReference = db.collection('gyms').doc('budapest').collection('gyms');

  GeoPoint geopointFrom(Map<String, dynamic> data) =>
      (data['geoloc'] as Map<String, dynamic>?)?['geopoint'] as GeoPoint? ?? GeoPoint(0, 0);

  final Stream<List<DocumentSnapshot<Map<String, dynamic>>>> gyms =
      GeoCollectionReference<Map<String, dynamic>>(collectionReference).subscribeWithin(
    center: userGeoPoint,
    radiusInKm: radius,
    field: 'geoloc',
    geopointFrom: geopointFrom,
  );

  gyms.listen(
    (List<DocumentSnapshot<Map<String, dynamic>>> snapshots) async {
      if (snapshots.isEmpty) {
        print("No gyms found within ${radius}km.");
        return;
      }

      nearbyGyms = snapshots.map((doc) => doc.id).toList();
      print("Nearby gyms: $nearbyGyms");

      await fetchPostsForNearbyGyms();
      await _getUserDataForPostById();
    },
    onError: (e) {
      print("Error fetching gyms: $e");
    },
  );
}


  Future<void> fetchPostsForNearbyGyms() async {
    if (nearbyGyms.isNotEmpty) {
      List<Map<String, dynamic>> allPosts = [];
      for (int i = 0; i < nearbyGyms.length; i += 10) {
        final batch = nearbyGyms.sublist(i, i + 10 > nearbyGyms.length ? nearbyGyms.length : i + 10);
        final postsQuery = db.collection('posts').where('gym', whereIn: batch);
        final postsSnapshot = await postsQuery.get();
        allPosts.addAll(postsSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Add the document ID to the data
          return data;
        }).toList());
      }
      nearbyPosts = allPosts;
    }
  }

  Future<void> _getUserDataForPostById() async {
  Set<String> userIDs = {for (var post in nearbyPosts) post['author'] as String};

  if (userIDs.isEmpty) return;

  try {
    final usersSnapshot = await db
        .collection('user_settings')
        .where(FieldPath.documentId, whereIn: userIDs.toList())
        .get();

    Map<String, Map<String, dynamic>> userSettingsMap = {
      for (var doc in usersSnapshot.docs) doc.id: doc.data()
    };

    for (var post in nearbyPosts) {
      final userID = post['author'];
      final userSettings = userSettingsMap[userID];
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
                  controller: controller,
                  padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 15, vertical: 0)),
                  leading: Icon(Icons.search, color: Theme.of(context).colorScheme.secondary,),
                  backgroundColor: WidgetStatePropertyAll<Color>(Colors.black),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)))
                  ),
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                  },
                  hintText: 'Search',
                  hintStyle: WidgetStatePropertyAll(
                    TextStyle(
                      color: Theme.of(context).colorScheme.secondary
                    )
                  ),
                );
              },
              suggestionsBuilder: (BuildContext context, SearchController controller) {
                return [Container()];
              }
            ),
          ),
          Expanded(
            child: FutureBuilder<void>(
              future: _fetchDataFuture,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: GlobalConsts.spinkit);
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return ListView.builder(
                    itemCount: nearbyPosts.length,
                    itemBuilder: (context, index) {
                      final post = nearbyPosts[index];
                      return Column(
                        children: [
                          post_builder.postBuilder(post, DisplayUsername.uname, context),
                        ],
                      );
                    },
                  );
                }
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