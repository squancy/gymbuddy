import 'package:gym_buddy/consts/common_consts.dart';
import 'package:image_fade/image_fade.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/utils/time_ago_format.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:gym_buddy/ui/core/common_ui.dart';
import 'package:gym_buddy/ui/post_builder/view_models/post_builder_view_model.dart';

class PostBuilder extends StatelessWidget {
  const PostBuilder({
    required post,
    required displayUsername,
    super.key
  }) :
  _post = post,
  _displayUsername = displayUsername;

  final Map<String, dynamic> _post;
  final String _displayUsername;

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('en', CustomMessages());

    return Column(
      key: Key(_post['post_id']),
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _post['author_profile_pic_url'].isEmpty ? Image.asset(
                ProfileConsts.defaultProfilePicPath,
                fit: BoxFit.cover,
                width: 40,
                height: 40,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) {
                    return child;
                  }
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 100),
                    opacity: frame == null ? 0 : 1,
                    child: child,
                  );
                },
              ) : ClipOval(
                child: ImageFade(
                  placeholder: ProfilePicPlaceholder(radius: 20,),
                  image: NetworkImage(_post['author_profile_pic_url']),
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                  duration: Duration(milliseconds: 100),
                  syncDuration: Duration(milliseconds: 100),
                )      
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 5),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              _displayUsername,
                              style: TextStyle(
                                fontWeight: FontWeight.bold
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                            child: Container( 
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.secondary
                              ),
                              width: 5,
                              height: 5,
                            ),
                          ),
                          Text(
                            timeago.format(_post['date'].toDate()),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary
                            ),
                          )
                        ]
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                      child: Text(
                        _post['content'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 10,
                      ),
                    ),
                    _post['gym'] == null ?
                      Container() :
                      InfoPart(
                        field: 'gymName',
                        post: _post,
                        viewModel: PostBuilderViewModel(),
                      ),
                    _post['when'] == null ?
                      Container() :
                      InfoPart(
                        field: 'when',
                        post: _post,
                        viewModel: PostBuilderViewModel(),
                      ),
                    _post['day_type'] == null ?
                      Container() :
                      InfoPart(
                        field: 'day_type',
                        post: _post,
                        viewModel: PostBuilderViewModel(),
                      ),
                  ],
                ),
              )
            ]
          ),
        ),
        _post['download_url_list'].isEmpty ? Container() : Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: HorizontalImageViewer(
            showImages: true,
            images: _post['download_url_list'],
            isPost: false,
            context: context
          ),
        ),
        Divider(
          color: Colors.white12
        ),
      ],
    );
  }
}

class InfoPart extends StatelessWidget {
  const InfoPart({
    required field,
    required post,
    required viewModel,
    super.key
  }) :
  _field = field,
  _post = post,
  _viewModel = viewModel;

  final String _field;
  final Map<String, dynamic> _post;
  final PostBuilderViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    return _viewModel.formatField(_field, _post).isNotEmpty ? Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
      child: Row(
        children: [
          Icon(
            _viewModel.getPostIcon(_field),
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 10,),
          Flexible(child:
            Text(_viewModel.formatField(_field, _post), style: TextStyle(
              fontWeight: FontWeight.bold
            ),)
          )
        ],
      )
    ) : Container();
  }
}