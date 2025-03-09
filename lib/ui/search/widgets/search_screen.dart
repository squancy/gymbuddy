import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';
import 'package:gym_buddy/data/repository/post_builder/post_builder_repository.dart';
import 'package:gym_buddy/data/repository/profile/profile_field_repository.dart';
import 'package:gym_buddy/data/repository/profile/profile_repository.dart';
import 'package:gym_buddy/data/repository/search/search_repository.dart';
import 'package:gym_buddy/ui/profile/view_models/profile_field_view_model.dart';
import 'package:gym_buddy/ui/profile/view_models/profile_page_view_model.dart';
import 'package:gym_buddy/ui/profile/widgets/profile_page_screen.dart';
import 'package:image_fade/image_fade.dart';
import 'dart:async';
import 'package:gym_buddy/ui/search/view_models/search_view_model.dart';

class SearchRowResult extends StatelessWidget {
  const SearchRowResult({
    required this.profilePicUrl,
    required this.displayUsername,
    required this.username,
    super.key
  });

  final String profilePicUrl;
  final String displayUsername;
  final String username;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 45,
          height: 45,
          child: ClipOval(
            child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
              child: ImageFade(
                image: profilePicUrl.isEmpty ?
                  AssetImage(GlobalConsts.defaultProfilePicPath) :
                  NetworkImage(profilePicUrl),
                placeholder: Container(
                  width: 45,
                  height: 45,
                  color: Colors.black,
                ),
              )
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayUsername,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("@$username", style: TextStyle(color: Colors.grey),)
            ],
          ),
        ),
      ],
    );
  }
}

class SearchRowUser extends StatelessWidget {
  const SearchRowUser({
    required this.hit,
    required this.cached,
    required this.future,
    super.key
  });
  
  final Map<String, dynamic> hit;
  final bool cached;
  final Future<UserData> future;
  
  factory SearchRowUser.fromHit({
    required Map<String, dynamic> hit,
    required bool cached,
    required SearchViewModel viewModel}) {
    return SearchRowUser(
      hit: hit,
      cached: cached,
      future: viewModel.getUserInfo(hit, cached),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (hit['cached'] != null && hit['cached']) {
      final (profilePicUrl, displayUsername, username) = (
        hit['profile_pic_url'],
        hit['display_username'],
        hit['username']
      );
      return SearchRowResult(
        profilePicUrl: profilePicUrl,
        displayUsername: displayUsername,
        username: username
      );
    } else {
      return FutureBuilder(
        future: future,
        builder: (BuildContext context, AsyncSnapshot<UserData> snapshot) {
          if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.connectionState == ConnectionState.done) {
            final (:profilePicUrl, :displayUsername, :username, :userID) = snapshot.data!;
            return SearchRowResult(
              profilePicUrl: profilePicUrl,
              displayUsername: displayUsername,
              username: username
            );
          } else {
            return Container();
          }
        }
      );
    }
  }
}

class AlwaysOnSearchBar extends StatelessWidget {
  const AlwaysOnSearchBar({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.5,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            child: IconButton(
              icon: Icon(
                Icons.saved_search_rounded,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () {
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Text(SearchViewModel.latestQuery),
          )
        ],
      ),
    );
  }
}

class SearchColumn extends StatelessWidget {
  const SearchColumn({
    required hits,
    required shouldCache,
    required viewModel,
    super.key
  }) :
  _hits = hits,
  _shouldCache = shouldCache,
  _viewModel = viewModel;

  final Iterable _hits;
  final bool _shouldCache;
  final SearchViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final hit in _hits) TapRegion(
          behavior: HitTestBehavior.translucent,
          onTapInside: (event) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(
                  viewModelField: ProfileFieldViewModel(
                    profileFieldRepository: ProfileFieldRepository()
                  ),
                  viewModel: ProfilePageViewModel(
                    profileRepository: ProfileRepository(),
                    commonRepository: CommonRepository(),
                    postBuilderRepository: PostBuilderRepository()
                  ),
                  userID: hit['objectID']
                )
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                SearchRowUser.fromHit(
                  hit: hit,
                  cached: _shouldCache,
                  viewModel: _viewModel,
                )
              ],
            )
            )
        )
      ],
    );
  }
}

class SearchContent extends StatelessWidget {
  const SearchContent({
    required viewModel,
    super.key
  }) :
  _viewModel = viewModel;

  final SearchViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    final (:isHit, :hit) = SearchViewModel.cache.get(SearchViewModel.latestQuery);
    SearchViewModel.cacheHit = isHit;
    return isHit ?
    Column(
      children: [
        AlwaysOnSearchBar(),
        SearchColumn(
          hits: hit![SearchViewModel.latestQuery],
          shouldCache: true,
          viewModel: _viewModel,
        )
      ],
    )
    :
    Column(
      children: [
        AlwaysOnSearchBar(),
        StreamBuilder(
          stream: _viewModel.combinedUserStream,
          builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.connectionState == ConnectionState.active) {
              List<Map<String, dynamic>> filteredData = _viewModel.filterUnique(snapshot.data!);
              SearchViewModel.cache.add({
                SearchViewModel.latestQuery: filteredData
              });
              return SearchColumn(
                hits: filteredData,
                shouldCache: false,
                viewModel: _viewModel,
              );
            } else {
              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: GlobalConsts.spinkit,
              );
            }
          }
        ),
      ],
    );
  }
}

class DefaultSearch extends StatefulWidget {
  const DefaultSearch({
    required this.searchController,
    required this.viewModel,
    super.key
  });

  final TextEditingController searchController;
  final SearchViewModel viewModel;

  @override
  State<DefaultSearch> createState() => _DefaultSearchState();
}

class _DefaultSearchState extends State<DefaultSearch> {  
  @override
  void initState() {
    super.initState();
    widget.viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (BuildContext context, Widget? child) {
        return SearchViewModel.curSearchState == SearchStates.textSearch ?
          SearchContent(
            key: UniqueKey(),
            viewModel: SearchViewModel(
              searchRepository: SearchRepository(),
              searchController: widget.searchController,
            ),
          )
          :
          Container();
      }
    );
  }
}