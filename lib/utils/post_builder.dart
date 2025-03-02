import 'package:gym_buddy/consts/common_consts.dart';
import 'package:image_fade/image_fade.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'time_ago_format.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:gym_buddy/ui/core/common_ui.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';

IconData getPostIcon(String field) {
  switch (field) {
    case 'gymName':
      return Icons.location_pin;
    case 'when':
      return Icons.calendar_month_rounded;
    case 'day_type':
      return Icons.sports_gymnastics_rounded;
  }
  return Icons.location_pin;
}

Widget buildInfoPart(field, post, context) {
  String val;
  if (field == 'when') {
    val = DateFormat('MM-dd hh:mm a').format(post[field].toDate()).toString();
  } else {
    val = post[field];
  }
  IconData icon = getPostIcon(field);

  return val.isNotEmpty ? Padding(
    padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary,),
        SizedBox(width: 10,),
        Flexible(child:
          Text(val, style: TextStyle(
            fontWeight: FontWeight.bold
          ),)
        )
      ],
    )
    ) : Container();
}

Future<List<Map<String, dynamic>>> createDataForPosts(List<QueryDocumentSnapshot<Map<String, dynamic>>> userPostDocs) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> res = [];
  String? userID = await CommonRepository().getUserID();
  var userData = (await db.collection('user_settings').doc(userID).get()).data();
  for (final post in userPostDocs) {
    Map<String, dynamic> data = post.data();
    data['author_display_username'] = userData!['display_username'];
    data['author_profile_pic_url'] = userData['profile_pic_url'];
    data['post_id'] = post.reference.id;
    List<String> gymNames = (await db.collection('gyms/budapest/gyms')
      .where('id', isEqualTo: data['gym']).get())
      .docs
      .map((doc) => (doc.data() as Map<String, dynamic>?)?['name'] as String? ?? '')
      .toList();
    data['gymName'] = gymNames.isNotEmpty ? gymNames[0] : '';
    res.add(data);
  }
  return res;
}

Widget postBuilder(post, displayUsername, context) {
  timeago.setLocaleMessages('en', CustomMessages());
  return Column(
    key: Key(post['post_id']),
    children: [
      Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            post['author_profile_pic_url'].isEmpty ? Image.asset(
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
                image: NetworkImage(post['author_profile_pic_url']),
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
                            displayUsername,
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
                          timeago.format(post['date'].toDate()),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary
                          ),
                        )
                      ]
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: Text(post['content'], overflow: TextOverflow.ellipsis, maxLines: 10,),
                  ),
                  post['gym'] == null ? Container() : buildInfoPart('gymName', post, context),
                  post['when'] == null ? Container() : buildInfoPart('when', post, context),
                  post['day_type'] == null ? Container() : buildInfoPart('day_type', post, context),
                ],
              ),
            )
          ]
        ),
      ),
      post['download_url_list'].isEmpty ? Container() : Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: HorizontalImageViewer(
          showImages: true,
          images: post['download_url_list'],
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