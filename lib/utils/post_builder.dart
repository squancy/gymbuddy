import 'package:gym_buddy/consts/common_consts.dart';
import 'package:image_fade/image_fade.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'helpers.dart' as helpers;
import 'time_ago_format.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  String? userID = await helpers.getUserID();
  var userData = (await db.collection('user_settings').doc(userID).get()).data();
  for (final post in userPostDocs) {
    Map<String, dynamic> data = post.data();
    data['author_display_username'] = userData!['display_username'];
    data['author_profile_pic_url'] = userData!['profile_pic_url'];
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

Widget postBuilder(Map<String, dynamic> post, String displayUsername, BuildContext context) {
  timeago.setLocaleMessages('en', CustomMessages());

  final authorProfilePicUrl = post['author_profile_pic_url'] ?? '';
  final postId = post['post_id'] ?? '';
  final date = post['date'] != null ? timeago.format(post['date'].toDate()) : '';
  final content = post['content'] ?? '';
  final gymName = post['gymName'] ?? '';
  final when = post['when'] != null ? DateFormat('MM-dd hh:mm a').format(post['when'].toDate()).toString() : '';
  final dayType = post['day_type'] ?? '';
  final downloadUrlList = post['download_url_list'] ?? [];
  final displayUsername = post['displayUsername'] ?? '';

  return Column(
    key: Key(postId),
    children: [
      Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            authorProfilePicUrl.isEmpty
                ? Image.asset(
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
                  )
                : ClipOval(
                    child: ImageFade(
                      placeholder: helpers.ProfilePicPlaceholder(radius: 20),
                      image: NetworkImage(authorProfilePicUrl),
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                      duration: Duration(milliseconds: 100),
                      syncDuration: Duration(milliseconds: 100),
                    ),
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
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            width: 5,
                            height: 5,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: Text(
                      content,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 10,
                    ),
                  ),
                  gymName.isEmpty ? Container() : buildInfoPart('gymName', post, context),
                  when.isEmpty ? Container() : buildInfoPart('when', post, context),
                  dayType.isEmpty ? Container() : buildInfoPart('day_type', post, context),
                ],
              ),
            ),
          ],
        ),
      ),
      downloadUrlList.isEmpty
          ? Container()
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: helpers.HorizontalImageViewer(
                showImages: true,
                images: downloadUrlList,
                isPost: false,
                context: context,
              ),
            ),
      Divider(
        color: Colors.white12,
      ),
    ],
  );
}