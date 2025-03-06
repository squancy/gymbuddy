import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:gym_buddy/auth/secrets.dart' as secrets;
import 'package:rxdart/rxdart.dart';
import 'dart:async';

class SearchService {
  static final HitsSearcher hitsSearcherUser = HitsSearcher(
    applicationID: secrets.Algolia.applicationID,
    apiKey: secrets.Algolia.searchAPIKey,
    indexName: secrets.Algolia.indexNameUsers,
  );

  static final HitsSearcher hitsSearcherUserSettings = HitsSearcher(
    applicationID: secrets.Algolia.applicationID,
    apiKey: secrets.Algolia.searchAPIKey,
    indexName: secrets.Algolia.indexNameUserSettings,
  );

  // Searches are performed on both "users" and "user settings" indicies
  // So we need to combine their results into one stream
  static final Stream<List<Map<String, dynamic>>> combinedUserStream = Rx.combineLatest2(
    hitsSearcherUser.responses,
    hitsSearcherUserSettings.responses,
    (userResponse, userSettingsResponse) => [
      ...userResponse.hits,
      ...userSettingsResponse.hits,
    ],
  ).asBroadcastStream();
}