import 'package:flutter/material.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';
import 'package:gym_buddy/data/repository/core/upload_image_repository.dart';
import 'package:gym_buddy/data/repository/profile/profile_photo_repository.dart';
import 'package:gym_buddy/ui/profile/view_models/profile_field_view_model.dart';
import 'package:gym_buddy/ui/profile/view_models/profile_page_view_model.dart';
import 'package:gym_buddy/ui/profile/view_models/profile_photo_view_model.dart';
import 'package:gym_buddy/ui/main/widgets/welcome_page_screen.dart';
import 'package:gym_buddy/ui/main/view_models/welcome_page_view_model.dart';
import 'package:gym_buddy/ui/post_builder/widgets/post_builder_screen.dart';
import 'package:gym_buddy/ui/profile/widgets/profile_field_screen.dart';
import 'package:gym_buddy/ui/profile/widgets/profile_photo_screen.dart';
import 'package:gym_buddy/consts/common_consts.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.viewModelField,
    required this.viewModel,
    required this.userID,
    super.key
  });

  final ProfileFieldViewModel viewModelField;
  final ProfilePageViewModel viewModel;
  final String userID;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.init(widget.userID);
    widget.viewModel.pageTransition.addListener(_handlePageTransition);
  }

  void _handlePageTransition() {
    if (widget.viewModel.pageTransition.value == PageTransition.stayOnPage) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => WelcomePage(
          viewModel: WelcomePageViewModel(
            commonRepository: CommonRepository()
          ),
        ),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    widget.viewModel.pageTransition.removeListener(_handlePageTransition);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
        )
      ),
      body: FutureBuilder(
        future: widget.viewModel.getUserDataFuture,
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.hasData && snapshot.data != null && snapshot.connectionState == ConnectionState.done) {
            final Map<String, dynamic> data = snapshot.data as Map<String, dynamic>;
            widget.viewModelField.uname = data['displayUsername'];
            widget.viewModelField.bio = data['bio'];

            return ListView(
              controller: widget.viewModel.bottomScrollController,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DUnameTapRegion(
                                viewModel: widget.viewModelField
                              ),
                              Text("@${data['username']}")
                            ],
                          ),),
                          Column(
                            // Profile photo and logout button
                            children: [
                              ProfilePhoto(
                                viewModel: ProfilePhotoViewModel(
                                  profilePhotoRepository: ProfilePhotoRepository(
                                    uploadImageRepository: UploadImageRepository()
                                  )
                                ),
                                userID: widget.userID,
                              ),
                              SizedBox(height: 10,),
                              GestureDetector(
                                onTap: widget.viewModel.logout,
                                child: Icon(
                                  Icons.logout_rounded,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
                // Bio
                BioTapRegion(
                  viewModel: widget.viewModelField
                ),
                Divider(
                  color: Colors.white12
                ),
                ListenableBuilder(
                  listenable: widget.viewModel,
                  builder: (BuildContext context, Widget? child) {
                    return FutureBuilder(
                      future: widget.viewModel.getPostsByUserFuture,
                      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                        List<Widget> posts = [];
                        if (snapshot.hasData && snapshot.data != null) {
                          for (final post in snapshot.data!) {
                            posts.add(
                              PostBuilder(
                                post: post,
                                displayUsername: widget.viewModelField.uname
                              )
                            );
                          }
                          return Column(
                            children: posts, // Posts
                          );
                        } else {
                          return Center(
                            child: GlobalConsts.spinkit,
                          );
                        }
                      }
                    );
                  }
                )
              ],
            );
          } else {
            return Center(
              child: GlobalConsts.spinkit,
            );
          }
        }
      )
    );
  }
}