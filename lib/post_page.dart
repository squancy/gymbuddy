import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:moye/widgets/gradient_overlay.dart';
import 'utils/photo_upload_popup.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/upload_image_firestorage.dart';
import 'utils/helpers.dart' as helpers;
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as datepicker;
import 'package:intl/intl.dart';
import 'package:moye/moye.dart';
import 'consts/common_consts.dart';
import 'package:gym_buddy/utils/mocks.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;
final storageRef = FirebaseStorage.instance.ref();

class PostPage extends StatefulWidget {
  final List<String> postPageActs;
  final List<Map<String, dynamic>> postPageGyms;

  const PostPage({
    required this.postPageActs,
    required this.postPageGyms,
    super.key
  });

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  String? _dayTypeVal = '';
  String? _gymVal = '';
  bool _showImages = false;
  final _picker = ImagePicker(); 
  List<File> _selectedImages = [];
  final _controller = TextEditingController();
  String _errorMsg = '';
  bool _hasError = false;
  DateTime? _datetimeVal;
  double? _progress;

  /// Select images from source (camera or gallery)
  void _selectFromSource(ImageSource sourceType) async {
    final pickedFiles = await _picker.pickMultiImage(limit: PostPageConsts.maxNumOfImages);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages = pickedFiles.map((el) => File(el.path)).toList();
        _showImages = true;
      });
    }
  }

  /// Select image from source mock (load default profile picture)
  void _selectFromSourceMock(ImageSource sourceType) async {
    File file = await getDefaultProfilePicAsFile();
    setState(() {
      _selectedImages = [file];
      _showImages = true;
    });
  }

  /// Create a new post
  Future<void> _createNewPost(
    List<File> images,
    String postText,
    String? dayType,
    String? gymID,
    DateTime? when) async {
    // First validate user input: only the text field is mandatory
    setState(() {
      _errorMsg = '';
      _hasError = false;
    });

    if (postText.isEmpty) {
      setState(() {
        _errorMsg = PostPageConsts.emptyFieldError;
        _hasError = true;
      });
      return;
    }

    final uuid = Uuid(); 
    final postID = uuid.v4();
    List<String> downloadURLs = [];
    List<String> filenames = [];

    Future<void> pushToDB() async {
      // Push to db
      final postsDocRef = db.collection('posts').doc(postID);
      final data = {
        'author': await helpers.getUserID(),
        'content': postText,
        'day_type': dayType,
        'gym': gymID,
        'download_url_list': downloadURLs,
        'filename_list': filenames,
        'when': when,
        'date': FieldValue.serverTimestamp()
      };

      try {
        await postsDocRef.set(data);
      } catch (e) {
        setState(() {
          _errorMsg = GlobalConsts.unknownErrorText; // 'An unknown error occurred'
          _hasError = true;
        });
        return;
      }

      setState(() {
        _progress = null;
        _hasError = false;
      });
    }

    if (images.isNotEmpty) {
      // Upload every image
      for (var i = 0; i < images.length; i++) {
        final image = images[i];
        final [UploadTask uploadTask, ref, filename] = await UploadImageFirestorage(storageRef).uploadImageProgess(image, 800, "post_pics/$postID");
        uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) async {
          switch (taskSnapshot.state) {
            case TaskState.running:
              setState(() {
                if (_progress == null) {
                  _progress = 0;
                } else if (taskSnapshot.totalBytes > 0) {
                  _progress = _progress! + (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) / images.length;
                }
              });
              break;
            case TaskState.success:
              downloadURLs.add(await ref.getDownloadURL());
              if (downloadURLs.length == images.length) {
                await pushToDB();
              }
              break;
            default:
              break;
        }
        });
        filenames.add(filename);
      }
    } else {
      await pushToDB();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadPhoto = PhotoUploadPopup(context, GlobalConsts.test ? _selectFromSourceMock : _selectFromSource);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
        )
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 'Find a gym buddy' text
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: Text(
                      PostPageConsts.appBarText, // 'Find a gym buddy'
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ).withGradientOverlay(gradient: LinearGradient(colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                      Theme.of(context).colorScheme.primary,
                    ])),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          key: const Key('textField'),
                          onTapOutside: (event) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: PostPageConsts.textBarText, // 'Looking for a buddy?'
                            hintStyle: TextStyle(
                              color: Colors.grey
                            ),
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none
                          ),
                          maxLines: null,
                          controller: _controller,
                        ),
                      ],
                    ),
                  ),
                  // Daytype scrollable dropdown menu
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: CustomDropdown<String>(
                      key: const Key('activityField'),
                      hintText: PostPageConsts.dayTypeText, // 'What are you going to do?'
                      items: widget.postPageActs,
                      onChanged: (p0) {
                        _dayTypeVal = p0;
                      },
                      excludeSelected: false,
                      overlayHeight: 350,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: Colors.black,
                        expandedFillColor: Colors.black,                      
                        listItemDecoration: ListItemDecoration(
                          highlightColor:  const Color.fromARGB(255, 23, 23, 23),
                          selectedColor: const Color.fromARGB(255, 23, 23, 23),
                          splashColor:  const Color.fromARGB(255, 23, 23, 23)
                        ),
                      ),
                    ),
                  ),
                  // Gym scrollable dropdown menu
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: CustomDropdown<Map<String, dynamic>>.search(
                      key: const Key('gymField'),
                      hintText: PostPageConsts.gymTypeText, // 'Which gym are you going to?'
                      items: widget.postPageGyms,
                      onChanged: (p0) {
                        _gymVal = p0?.keys.toList()[0];
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          selectedItem[selectedItem.keys.toList()[0]]['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500
                          ),);
                      },
                      overlayHeight: 350,
                      listItemBuilder: (context, item, isSelected, onItemSelect) {
                        String name = item[item.keys.toList()[0]]['name'];
                        String address = item[item.keys.toList()[0]]['address'];
                        return RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                            ),
                            children: <TextSpan>[
                              TextSpan(text: name),
                              TextSpan(text: '\t|\t'),
                              TextSpan(text: address, style: TextStyle(
                                color: Colors.grey)
                              ),
                            ],
                          ),
                        );
                      },
                      excludeSelected: false,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: Colors.black,
                        expandedFillColor: Colors.black,
                        listItemDecoration: ListItemDecoration(
                          highlightColor:  const Color.fromARGB(255, 23, 23, 23),
                          selectedColor: const Color.fromARGB(255, 23, 23, 23),
                          splashColor:  const Color.fromARGB(255, 23, 23, 23)
                        ),
                        searchFieldDecoration: SearchFieldDecoration(
                          fillColor: Colors.black
                        )
                      ),
                    ),
                  ),
                  // Date and time picker
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                            child: FilledButton.icon(
                              key: const Key('timeField'),
                              icon: Icon(Icons.date_range_rounded, size: 18, color: _datetimeVal != null ? Colors.white : Colors.grey,),
                              onPressed: () {
                                DateTime now = DateTime.now();
                                datepicker.DatePicker.showDateTimePicker(
                                  context,
                                  theme: datepicker.DatePickerTheme(
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    doneStyle: TextStyle(color: Colors.white),
                                    cancelStyle: TextStyle(color: Colors.white),
                                    itemStyle: TextStyle(color: Colors.white)
                                  ),
                                  showTitleActions: true,
                                  minTime: now,
                                  onConfirm: (date) {
                                    setState(() {
                                      _datetimeVal = date;
                                    });
                                  },
                                  currentTime: DateTime.now(),
                                  locale: datepicker.LocaleType.en
                                );
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(Colors.black),
                                foregroundColor: _datetimeVal != null ? WidgetStateProperty.all(Colors.white) : WidgetStateProperty.all(Colors.grey) 
                              ),
                              label: _datetimeVal != null ? Text(DateFormat('MM-dd kk:mm').format(_datetimeVal as DateTime)) : Text(PostPageConsts.timeTypeText), // 'What time?'
                            ),
                          ),
                        ),
                        Expanded(
                          // Upload photos button
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: FilledButton.icon(
                              key: const Key('uploadField'),
                              onPressed: uploadPhoto.showOptions,
                              label: Text(PostPageConsts.photosUploadText), // 'Add photos'
                              icon: Icon(Icons.add_a_photo_rounded, size: 18, color: _selectedImages.isNotEmpty ? Colors.white : Colors.grey,),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(Colors.black),
                                foregroundColor: _selectedImages.isNotEmpty ? WidgetStateProperty.all(Colors.white) : WidgetStateProperty.all(Colors.grey)
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  // Show selected images
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: helpers.HorizontalImageViewer(
                      showImages: _showImages,
                      images: _selectedImages,
                      isPost: true
                    )
                  ),
                  _progress == null ? Padding( // Post button
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: SizedBox(
                      height: 45,
                      child: helpers.ProgressBtn(
                        key: const Key('postBtn'),
                        onPressedFn: () {
                          return _createNewPost(
                            _selectedImages,
                            _controller.text,
                            _dayTypeVal,
                            _gymVal,
                            _datetimeVal
                          );
                        },
                        child: Text(PostPageConsts.postButtonText), // 'Post'
                      )
                    ),
                  ) : Container(),
                  _progress != null ? Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: LinearGradientProgressBar(
                      value: _progress!,
                      blurRadius: 10,
                      spreadRadius: 1,
                      borderRadius: BorderRadius.circular(56),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                      ),
                    ),
                  ) : Container(),
                  _hasError ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                      child: Text(_errorMsg),
                    )
                  ) : Container()
                ]
              ),
            )
          ],
        )
      )
    );
  }
}