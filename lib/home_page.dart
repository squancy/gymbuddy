import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'post_page.dart';
import 'utils/helpers.dart' as helpers;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

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

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await fetchPosts();
    await fetchNearbyGyms();
  });
}




  Future<Object> fetchPosts() async {
    // First get the geoloc of the user (if possible) and update it in db
    Position? geoloc = await helpers.getGeolocation(); 
    String? userID = await helpers.getUserID(); 
    if (geoloc != null) {
      try {
        geoPoint = GeoFirePoint(GeoPoint(geoloc.latitude, geoloc.longitude));
        await db.collection('users').doc(userID).update({'geoloc': geoPoint!.data}); 
      } catch (e) {
        // print(e);
      }
    }

    return {};
  }
  Future<void> fetchNearbyGyms() async {
  Position? geoloc = await helpers.getGeolocation();
  print("-----------------------------$geoloc");
  
  if (geoloc != null) {
    print("User location: ${geoloc.latitude}, ${geoloc.longitude}");
    
    // Create a new geoPoint from user's current location
    GeoFirePoint userGeoPoint = GeoFirePoint(GeoPoint(geoloc.latitude, geoloc.longitude));

    final radius = 10.0; // Radius in kilometers
    final collectionReference = db.collection('gyms').doc('budapest').collection('gyms');
    const String field = 'geoloc';  // Ensure this matches Firestore field

    // Correct field reference inside Firestore document
    GeoPoint geopointFrom(Map<String, dynamic> data) =>
        (data['geoloc'] as Map<String, dynamic>)['geopoint'] as GeoPoint;

    final Stream<List<DocumentSnapshot<Map<String, dynamic>>>> gyms =
        GeoCollectionReference<Map<String, dynamic>>(collectionReference).subscribeWithin(
      center: userGeoPoint,  // Use the new geoPoint instead of possibly null geoPoint
      radiusInKm: radius,
      field: field,
      geopointFrom: geopointFrom,
    );
    print("🔥 GeoQuery Stream created!");
    gyms.listen(
      (List<DocumentSnapshot<Map<String, dynamic>>> snapshots) {
        print("📡 GeoQuery Stream Triggered! Received ${snapshots.length} gyms.");

        if (snapshots.isEmpty) {
          print("⚠️ No gyms found within ${radius}km.");
        } else {
          for (var doc in snapshots) {
            final data = doc.data();
            if (data != null) {
              print("Gym ID: ${doc.id}, Data: $data");
            } else {
              print("Gym ID: ${doc.id}, but data is null");
            }
          }
        }
      },
      onError: (e) {
        print("❌ Error fetching gyms from GeoQuery: $e");
      },
    );
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
            child: ListView.builder(
              itemCount: nearbyGyms.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(nearbyGyms[index]));
              },
            ),
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