import 'package:cloud_firestore/cloud_firestore.dart';

/*
  Cache-first .get() on documents and queries
*/

// https://github.com/furkansarihan/firestore_collection/blob/master/lib/firestore_document.dart
extension FirestoreDocumentExtension on DocumentReference {
  Future<DocumentSnapshot> getCached() async {
    try {
      DocumentSnapshot ds = await get(GetOptions(source: Source.cache));
      if (!ds.exists) return get(GetOptions(source: Source.server));
      return ds;
    } catch (_) {
      return get(GetOptions(source: Source.server));
    }
  }
}

// https://github.com/furkansarihan/firestore_collection/blob/master/lib/firestore_query.dart
extension FirestoreQueryExtension on Query {
  Future<QuerySnapshot> getCached() async {
    try {
      QuerySnapshot qs = await get(GetOptions(source: Source.cache));
      if (qs.docs.isEmpty) return get(GetOptions(source: Source.server));
      return qs;
    } catch (_) {
      return get(GetOptions(source: Source.server));
    }
  }
}