import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';
import 'package:gym_buddy/data/repository/core/upload_image_repository.dart';
import 'package:gym_buddy/data/repository/post/post_page_repository.dart';
import 'package:gym_buddy/data/repository/post_builder/post_builder_repository.dart';
import 'package:gym_buddy/data/repository/profile/profile_field_repository.dart';
import 'package:gym_buddy/data/repository/profile/profile_repository.dart';
import 'package:gym_buddy/ui/home/view_models/home_page_view_model.dart';
import 'package:gym_buddy/ui/home/widgets/home_page_content_screen.dart';
import 'package:gym_buddy/ui/home/view_models/home_page_content_view_model.dart';
import 'package:gym_buddy/data/repository/home/home_page_content_repository.dart';
import 'package:gym_buddy/ui/post/widgets/post_page_screen.dart';
import 'package:gym_buddy/ui/post/view_models/post_page_view_model.dart';
import 'package:gym_buddy/ui/profile/view_models/profile_field_view_model.dart';
import 'package:gym_buddy/ui/profile/view_models/profile_page_view_model.dart';
import 'package:gym_buddy/ui/profile/widgets/profile_page_screen.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

class HomePage extends StatefulWidget {
  final List<String> postPageActs;
  final List<Map<String, dynamic>> postPageGyms;

  const HomePage({
    required this.viewModel,
    required this.postPageActs,
    required this.postPageGyms,
    super.key
  });

  final HomePageViewModel viewModel;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return ValueListenableBuilder<int>(
          valueListenable: widget.viewModel.selectedIndex,
          builder: (BuildContext context, int val, Widget? child) {
            return Scaffold(
              key: Key('homepage'),
              extendBody: true,
              body: Center(
                child: [
                  HomePageContent(
                    viewModel: HomePageContentViewModel(
                      homePageContentRepository: HomePageContentRepository()
                    ),
                  ),
                  PostPage(
                    postPageActs: widget.postPageActs,
                    postPageGyms: widget.postPageGyms,
                    viewModel: PostPageViewModel(
                      postPageRepository: PostPageRepository(),
                      uploadImageRepository: UploadImageRepository()
                    ),
                  ),
                  Container(),
                  ProfilePage(
                    viewModel: ProfilePageViewModel(
                      profileRepository: ProfileRepository(),
                      commonRepository: CommonRepository(),
                      postBuilderRepository: PostBuilderRepository()
                    ),
                    viewModelField: ProfileFieldViewModel(
                      profileFieldRepository: ProfileFieldRepository()
                    ),
                  )
                ][widget.viewModel.selectedIndex.value], 
              ),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.all(30), 
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(30)) 
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: BottomBarFloating(
                    items: widget.viewModel.items,
                    backgroundColor: Colors.black,
                    color: Theme.of(context).colorScheme.primary,
                    colorSelected: Theme.of(context).colorScheme.tertiary,
                    indexSelected: widget.viewModel.selectedIndex.value,
                    onTap: widget.viewModel.onItemTapped,
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
        );
      }
    );
  }
}