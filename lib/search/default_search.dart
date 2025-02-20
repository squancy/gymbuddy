import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:gym_buddy/auth/secrets.dart' as secrets;

final FirebaseFirestore db = FirebaseFirestore.instance;

class DefaultSearch extends StatefulWidget {
  final String query;

  const DefaultSearch({
    required this.query,
    super.key
  });

  @override
  State<DefaultSearch> createState() => _DefaultSearchState();
}

class _DefaultSearchState extends State<DefaultSearch> {
  final hitsSearcher = HitsSearcher(
    applicationID: secrets.Algolia.applicationID,
    apiKey: secrets.Algolia.searchAPIKey,
    indexName: secrets.Algolia.indexNamePosts,
  );

  @override
  void initState() {
    super.initState();
    
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}